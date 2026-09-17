---
name: verify-refactor
description: Use after editing a function to confirm the refactor preserved behavior. Composes contract, side-effect, and CFG-equivalence checks across the two versions of one function.
---

# verify-refactor

Confirm one function's refactor is behavior-preserving by composing three
Engineering-tier verification ops over a two-version comparison: git working tree vs
`HEAD` by default, or an explicit `before`/`after` pair.

This skill verifies one function pair. For a changed set of functions with git
context, use `act gate` via the safe-to-merge skill; its MERGE/REVIEW/BLOCK/UNKNOWN
vocabulary is deliberately distinct from this skill's SAFE/REVIEW/UNSAFE/UNKNOWN.

## Tools

| Step | Tool | Question it answers |
|---|---|---|
| 1 | `verify_contract_preserved` | Did the public and behavioral contract (signature, effects, control, returns, guards, raises) change? |
| 2 | `verify_side_effects` | Which side effects were added or removed? Was a cleanup dropped? |
| 3 | `verify_behavioral_equivalence` | Is the control-flow shape equivalent (no new or removed branches, loops, exception paths)? |

`verify_behavioral_equivalence` with `scope:"port"` is Enterprise and belongs to
port-verify.

## Workflow

1. `verify_contract_preserved` with `target` and `file`. A `broken` verdict ends the
   run: report the broken dimensions.
2. `verify_side_effects`. Surface `dropped_cleanup: true` first: a removed write or
   close while an allocation is kept is a likely leak.
3. `verify_behavioral_equivalence`. `equivalent` means the shape held; `changed`
   lists the dimensions; `unknown` means a grammar dimension (Go exceptions, for
   example) could not be judged and carries no safety claim.

## Verdict

- **SAFE**: contract preserved, no dropped cleanup, behaviorally equivalent.
- **REVIEW**: contract preserved but effects changed, or the CFG `changed` in an
  expected way. Summarize what moved.
- **UNSAFE**: contract `broken`, `dropped_cleanup: true`, or behavior changed
  unexpectedly.
- **UNKNOWN**: any op returned `unknown` on an unmodeled dimension. UNKNOWN stays
  UNKNOWN; it never becomes SAFE.

## Summary format

The verdict, the three op results in one line each, and the specific dimensions or
effects that changed. Quote `modeled_kinds` when the verdict is UNKNOWN.
