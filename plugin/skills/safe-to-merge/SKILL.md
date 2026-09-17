---
name: safe-to-merge
description: Use before merging a branch or approving a PR. Runs act's deterministic merge gate over every changed function and reports its MERGE / REVIEW / BLOCK / UNKNOWN verdict.
---

# safe-to-merge

Delegate to the `gate` tool (CLI twin `act gate`). The verdict rules live in the
engine; this skill covers how to run it and how to read the result.

## Run

| Scope | Call |
|---|---|
| Working tree vs HEAD (default) | `gate` with no params, or `act gate` |
| PR branch vs its base | `gate` with `base_ref` set to the base (e.g. `origin/main`), or `act gate --base-ref origin/main` |

CLI exit codes: 0 MERGE, 1 BLOCK, 2 REVIEW, 3 UNKNOWN, 4 execution error. CI scripts
branch on the exact code; the numbers are identifiers, not a severity scale.

## What the engine does

It discovers every changed function from the git diff (rename-aware; same-file
exact-body renames are paired as signature changes), then runs the verification trio
per function: `verify_diff_semantics` (hunk classes; a guard-condition change counts
as behavior), `verify_test_impact` (does any test reach it, via a syntactic
call-graph floor with import resolution), and `verify_side_effects` (effect delta,
dropped cleanup). In outline: format-only changes merge; signature-only changes merge
with test reach and block without it; tested behavior changes ask for review;
untested behavior changes and dropped cleanup block; anything the grammar cannot
model degrades to UNKNOWN with `modeled_kinds` quoted. Changed test code is exempt
from the reach rule. The per-function `reason` field cites the rule that fired.

## Tier

Engineering (the verify trio's tier). Tier-blocked runs, and files in a premium
language (a grammar gated to the Elite edition) the license does not cover, report
UNKNOWN with the blocking dimension named; report that as given.

## Reading the result

`verdict` is the worst case over `functions[]`. Each record carries
`classification`, `tested` with `impacted_tests`, `effects_added` and
`effects_removed`, `dropped_cleanup`, `modeled_kinds`, its own `verdict`, and
`reason`. `skipped[]` lists changed files with no grammar; include them in the
summary so coverage is honest.

## Coverage

These are AST and heuristic analyses, not a proof. UNKNOWN means "not verified"; the
engine ranks it above MERGE and REVIEW in the overall verdict, and your summary
keeps it that way. Grammars without branch-CFG modeling cannot rule out behavior
changes in body edits and return UNKNOWN with the evidence quoted.
