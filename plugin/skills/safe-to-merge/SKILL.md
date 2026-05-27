---
name: safe-to-merge
description: Decide whether a change is safe to merge — composes diff-semantics classification, test-impact, and side-effect diffs into a merge / review / block verdict. Use before merging a branch or approving a PR.
---

# safe-to-merge

Turn a set of changed functions into an actionable **MERGE / REVIEW / BLOCK**
verdict by composing three Pro verification ops over a two-version comparison
(git working-tree vs `HEAD` by default, or an explicit `before`/`after` pair).

## Honesty caveat (read first)

These analyses are AST/heuristic and intra-/inter-procedural, not a proof. Each
op returns `modeled_kinds` describing what the current grammar can judge. A
verdict on a dimension the grammar does not model is reported `unknown` — treat
UNKNOWN as "not verified," never silently upgrade it to MERGE. Per-grammar
degradation is real: an empty `modeled_kinds` means that dimension is uncovered
for this language, so say so explicitly.

## Tier

**Pro.** All three composed tools are Pro and enforce the tier themselves; if a
call is rejected for tier the verdict is incomplete — report that, do not guess.

## Tools (in order)

| Step | Tool | What it answers |
|---|---|---|
| 1 | `verify_diff_semantics` | For each changed function, is each hunk `format`, `signature`, or `behavior`? |
| 2 | `verify_test_impact` | Which tests' call graphs reach the changed symbols? Is anything changed but untested? |
| 3 | `verify_side_effects` | Which side effects were added/removed? Was a cleanup dropped? |

## Workflow

1. For each changed function in the diff, call `verify_diff_semantics` with
   `target` + `file`. Tally hunks: `format`-only is low risk; `signature`
   changes are caller-breaking; `behavior` changes are the ones that need
   tests. If a hunk classification is `unknown`, record it — that hunk is not
   judged.
2. For **each** function classified `behavior` or `signature` in step 1, call
   `verify_test_impact` with that function as **`target`** (`file` + `target`).
   Do **not** rely on the no-`target` file mode for this cross-reference: it
   derives its changed set from the symbol-**name** diff, so it catches
   added/removed symbols but **misses same-name body changes** — exactly the
   `behavior` hunks step 1 flags. Cross-reference: a `behavior`/`signature`-
   changed function whose impacted set is **empty** is a change-without-a-test —
   the strongest BLOCK signal.
3. Call `verify_side_effects` for each behavior-changed function. Surface any
   `dropped_cleanup: true` prominently (a removed write/close while an
   allocation is kept is a likely leak) and list added/removed effects.

## Verdict synthesis

- **MERGE** — only `format`/`signature` changes that are covered by impacted
  tests, no `dropped_cleanup`, no `behavior` hunk left untested, nothing
  `unknown`.
- **REVIEW** — `behavior` changes that ARE covered by impacted tests, or effects
  changed in an explainable way; summarize what moved and why it's plausibly
  intended.
- **BLOCK** — a `behavior`/`signature` change reaching no test, a
  `dropped_cleanup: true`, or an unexpected effect addition.
- **UNKNOWN** — any step returned `unknown`/empty `modeled_kinds` on a dimension
  that matters; never present UNKNOWN as MERGE.

## Output

Report the verdict, then one line per changed function: its diff-semantics
class, whether a test reaches it, and any effect delta. Quote `modeled_kinds`
for any UNKNOWN dimension and name the language so the reviewer knows the
coverage boundary.
