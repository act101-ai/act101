---
name: refactor-receipt
description: Emit durable refactor receipts — content-addressed JSON artifacts proving a refactor was verified. Delegates to the shipped gate machinery (act gate --receipts / MCP gate with receipts:true) rather than re-running verification ops manually.
---

# refactor-receipt

Emit durable **refactor receipts** — content-addressed JSON files stored in
`.act/receipts/` that record the full verification evidence for each changed
function. The receipt machinery is built into `act gate`; this skill describes
how to drive it, where the files live, what validity means, and how to read one.

## Honesty caveat (read first)

A receipt is evidence, not proof of equivalence. The `modeled_kinds` field
records what the grammar can actually judge; every dimension the grammar cannot
judge is reported as `unknown:…` in the `contract` field, never silently treated
as preserved. Per-grammar degradation is real — some languages cover fewer
dimensions. When citing a receipt, always quote `modeled_kinds` for any
`unknown` dimension; omitting it misrepresents the receipt's confidence.
Rename receipts always record `contract: "unknown:rename"` because names differ
by construction; that is not a verification gap, it is the correct honest answer.

## Tier

**Engineering.** The gate tool (which writes receipts) requires the Engineering
tier. The `receipt: true` parameter on the four refactor tools also requires
Engineering; it is silently ignored in preview mode.

## Emitting receipts

### Whole changed set — `act gate --receipts`

Run after a refactor session to verify and record every changed function in one
pass:

```
act gate --receipts
```

MCP equivalent:

```
gate(receipts=true)
```

The gate discovers changed functions from the git diff (working tree vs HEAD by
default, or vs `base_ref` when supplied), runs the full verification pipeline
per function, and writes one `<id>.json` receipt to `.act/receipts/` per
verified function. The overall verdict (MERGE / REVIEW / BLOCK / UNKNOWN) is
returned; receipt writing does not change the verdict rules — those live in the
gate engine.

### Single refactor op — `receipt: true`

The four refactor tools (`rename`, `extract_function`, `move_symbol`, `inline`)
accept `receipt: true` to write a receipt immediately after applying the change.
CLI usage:

```
act refactor --receipt rename foo bar --file src/lib.ts
```

MCP equivalent (pass `receipt=true` as a parameter):

```
rename(file=…, old_name=…, new_name=…, receipt=true)
```

On success the result carries `receipt.id`. On failure it carries
`receipt_error`. In preview mode (`preview: true`) the field is ignored and no
receipt is written.

## Where receipts live

All receipts are stored flat in `.act/receipts/<id>.json` at the workspace
root. The `<id>` is the first 16 hex characters of
`sha256("<file>\0<symbol>\0<before_hash>\0<after_hash>")` — a content-addressed
key that encodes the exact before/after state.

## Validity — content-addressed, never stale

Receipt consumption is **always on** when `.act/receipts/` exists: before using
a cached result the engine recomputes `before_hash` and `after_hash` from the
live span text and confirms they match the stored values. A mismatch means the
code changed since verification ran — the receipt is discarded and the function
is re-verified from scratch. There is no "stale pass": a hash mismatch is always
a re-verify signal.

Receipts with an unrecognised `schema_version` are also silently skipped and
treated as re-verify signals.

## Reading a receipt

Each receipt is a JSON file with these fields:

| Field | What it means |
|---|---|
| `verdict` | `MERGE` / `REVIEW` / `BLOCK` / `UNKNOWN` — the gate's top-line decision |
| `contract` | `"preserved"` / `"broken:<dims>"` / `"unknown:<dims>"` |
| `diff_semantics` | Array of hunk classifications: `format`, `signature`, `behavior` |
| `effects_added` / `effects_removed` | Side-effect delta |
| `dropped_cleanup` | `true` if a cleanup effect was removed |
| `impacted_tests` | Test files whose call graph reaches the changed function |
| `modeled_kinds` | Bitmask of what the grammar could judge — cite this for any `unknown` dimension |
| `before_hash` / `after_hash` | `"sha256:<hex>"` of the function's span text at verification time |
| `id` | Content-addressed key (see above) |
| `tool_version` / `timestamp` | Provenance |

When citing a receipt in a review or audit:

1. Quote the `verdict` and `contract` fields.
2. For any `unknown:…` or `broken:…` contract, quote `modeled_kinds` and name
   the unmodeled dimension — do not present an `unknown` dimension as preserved.
3. The verdict decision rules live in the gate engine (`full_description` of the
   `gate` catalog entry); do not re-derive them here.
