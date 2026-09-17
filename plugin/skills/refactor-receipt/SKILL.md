---
name: refactor-receipt
description: Use when a refactor needs durable, citable proof that it was verified, or when reading a receipt someone else produced. Receipts are content-addressed JSON artifacts written by the gate machinery, never assembled by hand.
---

# refactor-receipt

Emit and read **refactor receipts**: content-addressed JSON files in
`.act/receipts/` recording the verification evidence for each changed function.
The machinery is built into `act gate`; this skill covers how to drive it, where the
files live, what validity means, and how to read one.

## Tier

Engineering. The `gate` tool writes receipts, and the `receipt: true` parameter on
the four refactor tools needs Engineering too, even on `rename`, which is otherwise
Free. Preview mode ignores the flag and writes nothing.

## Emitting receipts

**Whole changed set.** After a refactor session, verify and record every changed
function in one pass:

```
act gate --receipts
```

MCP: `gate(receipts=true)`. The gate discovers changed functions from the git diff
(working tree vs HEAD, or vs `base_ref`), runs the verification pipeline per
function, and writes one `<id>.json` per verified function. Receipt writing does not
change the verdict rules.

**Single refactor op.** `rename`, `extract_function`, `move_symbol`, and `inline`
accept `receipt: true` to write a receipt right after applying the change:

```
act refactor --receipt rename foo bar --file src/lib.ts
```

MCP: `rename(file=…, old_name=…, new_name=…, receipt=true)`. On success the result
carries `receipt.id`; on failure it carries `receipt_error`.

## Where receipts live

Flat in `.act/receipts/<id>.json` at the workspace root. `<id>` is the first 16 hex
characters of `sha256("<file>\0<symbol>\0<before_hash>\0<after_hash>")`, so it
encodes the exact before and after state.

## Validity

Receipt consumption is always on when `.act/receipts/` exists. Before using a cached
result the engine recomputes `before_hash` and `after_hash` from the live span text
and compares them with the stored values. A mismatch means the code changed since
verification; the receipt is discarded and the function re-verified. Receipts with
an unrecognised `schema_version` are skipped the same way. There is no stale pass.

## Reading a receipt

| Field | Meaning |
|---|---|
| `verdict` | `MERGE` / `REVIEW` / `BLOCK` / `UNKNOWN`, the gate's decision |
| `contract` | `"preserved"` / `"broken:<dims>"` / `"unknown:<dims>"` |
| `diff_semantics` | Hunk classifications: `format`, `signature`, `behavior` |
| `effects_added` / `effects_removed` | Side-effect delta |
| `dropped_cleanup` | `true` if a cleanup effect was removed |
| `impacted_tests` | Test files whose call graph reaches the changed function |
| `modeled_kinds` | What the grammar could judge; cite it for any `unknown` dimension |
| `before_hash` / `after_hash` | `"sha256:<hex>"` of the function's span text at verification time |
| `id` | Content-addressed key |
| `tool_version` / `timestamp` | Provenance |

When citing a receipt in a review or audit, quote `verdict` and `contract`, and for
any `unknown:…` or `broken:…` contract quote `modeled_kinds` and name the unmodeled
dimension. The decision rules stay in the gate engine (the `gate` catalog entry's
`full_description`); the receipt is evidence, not a re-derivation of them.

## Coverage

A receipt is evidence, not proof of equivalence. Every dimension the grammar cannot
judge appears as `unknown:…` in `contract`, and some languages cover fewer
dimensions. Rename receipts always record `contract: "unknown:rename"` because the
names differ by construction; that is the correct answer, not a gap.
