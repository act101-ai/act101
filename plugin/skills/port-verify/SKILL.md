---
name: port-verify
description: Gate a cross-language port for correctness — composes port-scoped behavioral equivalence, contract parity, and port-manifest drift into a port-correctness verdict. Use to verify that a ported function matches its source before marking the port done.
---

# port-verify

A **port-correctness gate**: confirm a ported function behaves like its source
and that the port manifest is not drifting. Composes two Enterprise verification
ops with the port inventory.

## Honesty caveat (read first)

This is a structural/contract comparison (v1), not execution-based differential
testing. `verify_port_parity` and `verify_behavioral_equivalence` (scope=port)
compare only dimensions BOTH grammars model — a dimension modeled by one side
only is reported `unknown`, never falsely `preserved`/`diverged`. Each result
carries `modeled_kinds`; an empty set for either grammar means that dimension is
uncovered. Per-grammar degradation across the source/target language pair is the
norm — name both languages and the uncovered dimensions. Verdicts are advisory.

## Tier

**Enterprise.** `verify_behavioral_equivalence` at `scope:"port"`,
`verify_port_parity`, and the `port_*` manifest/inventory tools are all
Enterprise and enforce the tier themselves.

## Tools (in order)

| Step | Tool | What it answers |
|---|---|---|
| 1 | `verify_behavioral_equivalence` (`scope:"port"`) | Do the source and ported functions have an equivalent control-flow shape under cross-language normalization? |
| 2 | `verify_port_parity` | Do signature arity, return presence, effect-kind set, CFG shape, and raise count match across the language pair? |
| 3 | `port_inventory` | Is the manifest consistent — is this symbol marked ported, and is the target verified? Surfaces drift. |

## Workflow

1. Call `verify_behavioral_equivalence` with `scope:"port"`, the source
   `target`/`file` and the ported version (via `before`/`after` or the manifest
   mapping). `equivalent` confirms shape held; `changed` lists which dimensions
   diverged; `unknown` means a dimension could not be normalized across the pair
   — do not claim parity on it.
2. Call `verify_port_parity` with `source_file`/`source_target` and
   `ported_file`/`ported_target`. Read the verdict (`preserved`/`diverged`/
   `unknown`), the `dimensions_checked`, and every `mismatch`. A `diverged`
   dimension is a hard gate failure.
3. Call `port_inventory` to check manifest state for the file: is it marked
   ported, are ported/stubbed symbols recorded, does target verification pass?
   A symbol that is structurally equivalent but absent/stubbed in the manifest
   is **drift** — the manifest and reality disagree.

## Verdict synthesis

- **PORT VERIFIED** — `equivalent` (port scope) AND parity `preserved` with
  ≥1 jointly-modeled dimension AND the manifest marks the symbol ported with a
  verified target.
- **PORT DIVERGED** — equivalence `changed` or parity `diverged` on any modeled
  dimension; report the exact dimension and the mismatch.
- **MANIFEST DRIFT** — structurally equivalent but the manifest disagrees
  (unrecorded, stubbed, or unverified target).
- **UNKNOWN** — either op returned `unknown`/empty `modeled_kinds` on a
  dimension; name the source+target languages and the uncovered dimension.
  Never present UNKNOWN as VERIFIED.

## Output

Per ported symbol: the equivalence result, the parity verdict with
dimensions_checked + mismatches, the manifest status, and the gate verdict.
Quote `modeled_kinds` for both languages on any UNKNOWN.
