---
name: safe-to-merge
description: Decide whether a change is safe to merge — runs `act gate`, the deterministic verdict (MERGE / REVIEW / BLOCK / UNKNOWN) over every changed function. Use before merging a branch or approving a PR.
---

# safe-to-merge

Delegate to the **`gate`** tool (CLI twin: `act gate`). The verdict rules live
in the engine — one source of truth; this skill describes how to run it and
read the result, it does not re-specify the rules.

## Run

| Scope | Call |
|---|---|
| Working tree vs HEAD (default) | `gate` with no params / `act gate` |
| PR branch vs its base | `gate` with `base_ref` = the base (e.g. `origin/main`) / `act gate --base-ref origin/main` |

CLI exit codes: 0 MERGE, 1 BLOCK, 2 REVIEW, 3 UNKNOWN, 4 execution error —
CI scripts branch on exact codes (they are identifiers, not a severity scale).

## What the engine does

Discovers every changed function from the git diff (rename-aware; same-file
exact-body renames are paired as signature changes), then composes the
verification trio per function: `verify_diff_semantics` (hunk classes —
guard-condition changes count as behavior), `verify_test_impact` (does any
test reach it — syntactic call-graph floor with import resolution),
`verify_side_effects` (effect delta, dropped cleanup). Broadly: format- or
signature-only changes with test reach merge; tested behavior changes ask for
review; untested behavior/signature changes and dropped cleanup block; anything
the grammar cannot model degrades to UNKNOWN with `modeled_kinds` quoted.
Changed test code is exempt from the reach rule. The authoritative matrix is in
`act-analysis`'s `gate` module — read the per-function `reason` field; it cites
the rule that fired.

## Honesty caveat (read first)

These are AST/heuristic analyses, not a proof. UNKNOWN means "not verified" —
never present it as MERGE; the engine enforces this (UNKNOWN outranks MERGE
and REVIEW in the overall verdict). Per-grammar degradation is real: grammars
without branch-CFG modeling cannot rule out behavior changes in body edits and
return UNKNOWN with the evidence quoted.

## Tier

**Engineer** (the verify trio's tier; named Pro before V2). Tier-blocked runs
and premium-language files report UNKNOWN with the blocking dimension named —
report that, do not guess a verdict.

## Reading the result

`verdict` is the overall worst case over `functions[]`. Each record carries:
`classification`, `tested` + `impacted_tests`, `effects_added`/`effects_removed`,
`dropped_cleanup`, `modeled_kinds`, per-function `verdict`, and `reason`.
`skipped[]` lists changed files that did not gate (no grammar) — mention them
in your summary so coverage is honest.
