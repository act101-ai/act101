---
name: verify-refactor
description: Verify a refactor preserved behavior — composes contract, side-effect, and CFG-equivalence checks across two versions of a function. Use after editing a function to confirm the change is safe.
---

# verify-refactor

Confirm a function's refactor is behavior-preserving by composing three Pro
verification ops over a two-version comparison (git working-tree vs `HEAD` by
default, or an explicit before/after pair).

## Tools

| Step | Tool | What it answers |
|---|---|---|
| 1 | `verify_contract_preserved` | Did the public + behavioral contract (signature, effects, control, returns, guards, raises) change? |
| 2 | `verify_side_effects` | Which side effects were added/removed? Was a cleanup dropped? |
| 3 | `verify_behavioral_equivalence` | Is the control-flow shape equivalent (no new/removed branches, loops, exception paths)? |

All three are **Pro**. `verify_behavioral_equivalence` at `scope:"port"` is Enterprise.

## How to run

1. Call `verify_contract_preserved` with `target` + `file`. If the verdict is
   `broken`, report the broken dimensions and stop — the refactor changed the
   contract.
2. Call `verify_side_effects`. Surface any `dropped_cleanup: true` prominently —
   a removed write/close while an allocation is kept is a likely leak.
3. Call `verify_behavioral_equivalence`. `equivalent` confirms the shape held;
   `changed` lists which dimensions; `unknown` means a grammar dimension (e.g.
   Go exceptions) could not be judged — say so, do not claim safety.

## Verdict

- **SAFE** — contract preserved, no dropped cleanup, behaviorally equivalent.
- **REVIEW** — contract preserved but effects changed, or CFG `changed` in an
  expected way; summarize what moved.
- **UNSAFE** — contract `broken`, `dropped_cleanup: true`, or behavior changed
  unexpectedly.
- **UNKNOWN** — any op returned `unknown` on a not-modeled dimension; never
  upgrade UNKNOWN to SAFE.

## Summary format

Report: the verdict, the three op results in one line each, and the specific
dimensions/effects that changed. Quote `modeled_kinds` when a verdict is UNKNOWN.
