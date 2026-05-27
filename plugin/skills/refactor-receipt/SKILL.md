---
name: refactor-receipt
description: Produce an audit artifact ("receipt") proving a refactor preserved behavior — composes diff-semantics, side-effect diff, test-impact, and contract-preservation checks. Use after refactoring to document that the change is behavior-preserving.
---

# refactor-receipt

Emit a durable **refactor receipt** — a structured artifact that records, with
evidence, that a refactor preserved behavior. Composes four Pro verification ops
over a two-version comparison (git working-tree vs `HEAD` by default, or an
explicit `before`/`after` pair).

## Honesty caveat (read first)

The receipt is an evidence summary, not a proof of equivalence. Every op reports
`modeled_kinds` for what the grammar can judge; any dimension it cannot judge is
`unknown` and the receipt must record it as UNVERIFIED. A receipt that hides
`unknown` dimensions is dishonest — per-grammar degradation means some languages
cover fewer dimensions, so name the language and what was not checked.

## Tier

**Pro.** All four composed tools are Pro and enforce the tier themselves.

## Tools (in order)

| Step | Tool | Receipt line it produces |
|---|---|---|
| 1 | `verify_diff_semantics` | Classified hunks — refactor receipts expect mostly `format`, some `signature`, ideally no `behavior`. |
| 2 | `verify_side_effects` | Effect delta — should be empty for a pure refactor; flags `dropped_cleanup`. |
| 3 | `verify_test_impact` | The tests whose call graph reaches the change — the receipt's "covered by" evidence. |
| 4 | `verify_contract_preserved` | The top-line verdict: `preserved` / `broken{dimensions}` / `unknown{dimensions}`. |

## Workflow

1. For each refactored function, call `verify_diff_semantics`. A
   behavior-preserving refactor should show `format`/`signature` hunks; record
   any `behavior` hunk as a receipt warning.
2. Call `verify_side_effects`. For a true refactor the added/removed effect sets
   should be empty; record the delta and flag `dropped_cleanup: true`.
3. Call `verify_test_impact` for the changed file to list which tests exercise
   the touched symbols — this is the receipt's coverage evidence.
4. Call `verify_contract_preserved` per function for the headline verdict.
   `broken` dimensions invalidate the receipt; `unknown` dimensions are recorded
   as UNVERIFIED, never as preserved.

## Receipt artifact

Produce a markdown block per refactored symbol:

```
Symbol: <name> (<file>)
Contract: preserved | broken{...} | unknown{...}
Diff semantics: N format, N signature, N behavior (+ any unknown)
Effects: added=[...] removed=[...] dropped_cleanup=<bool>
Covered by: <impacted test files>
Verdict: PRESERVED | NOT PRESERVED | UNVERIFIED
modeled_kinds: <...>   (language: <lang>)
```

## Verdict synthesis

- **PRESERVED** — contract `preserved`, no `behavior` hunks, empty effect delta,
  no `dropped_cleanup`, and at least one impacted test covers it.
- **NOT PRESERVED** — contract `broken`, a `dropped_cleanup`, or a `behavior`
  hunk that changed externally observable behavior.
- **UNVERIFIED** — any op returned `unknown`/empty `modeled_kinds` on a relevant
  dimension. Record exactly which dimension and language; do not call it
  preserved.
