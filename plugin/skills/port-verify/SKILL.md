---
name: port-verify
description: Use to verify that a ported function matches its source before marking the port done. Composes port-scoped behavioral equivalence, cross-language contract parity, and port-manifest state into one port-correctness verdict.
---

# port-verify

A **port-correctness gate**: confirm a ported function behaves like its source and
that the port manifest agrees with reality. `verify_behavioral_equivalence` at
`scope:"port"`, `verify_port_parity`, and the `port_*` tools are Enterprise tier and
enforce it themselves.

## Tools, in order

| Step | Tool | Question it answers |
|---|---|---|
| 1 | `verify_behavioral_equivalence` with `scope:"port"` | Do source and port have an equivalent control-flow shape under cross-language normalization? |
| 2 | `verify_port_parity` | Do signature arity, return presence, effect-kind set, CFG shape, and raise count match across the language pair? |
| 3 | `port_inventory` | Is this symbol marked ported in the manifest, and does its target verify? |

## Workflow

1. Look up the source-to-target mapping with `port_inventory`. Then call
   `verify_behavioral_equivalence` with `scope:"port"`, the source `target` and
   `file`, and the ported version via `before`/`after`. `equivalent` means the shape
   held; `changed` lists the diverging dimensions; `unknown` means a dimension could
   not be normalized across the pair and carries no parity claim.
2. Call `verify_port_parity` with `source_file`/`source_target` and
   `ported_file`/`ported_target`. Read the verdict (`preserved`, `diverged`,
   `unknown`), `dimensions_checked`, and every entry in `mismatches`. A `diverged`
   dimension fails the gate.
3. Read `port_inventory` for the file: is the symbol recorded as ported (not
   stubbed), and does target verification pass? A structurally equivalent symbol
   that the manifest records as absent, stubbed, or unverified is **drift**.

`verify_port_parity` also offers differential execution with `execute: true`: it
generates inputs from the source signature, runs both functions under a
resource-capped subprocess, and diffs their JSON output. It applies only when both
sides run under a supported interpreter (node, python3) with a JSON-able signature,
and falls back to the structural comparison otherwise.

## Verdict

- **PORT VERIFIED**: `equivalent` at port scope, parity `preserved` (the tool grants
  it only with at least two jointly modeled dimensions), and the manifest marks the
  symbol ported with a verified target.
- **PORT DIVERGED**: equivalence `changed` or parity `diverged` on any modeled
  dimension. Report the dimension and the mismatch.
- **MANIFEST DRIFT**: structurally equivalent but the manifest disagrees.
- **UNKNOWN**: either op returned `unknown` or empty `modeled_kinds` on a dimension.
  Name both languages and the dimension. UNKNOWN is never reported as VERIFIED.

## Coverage

Structural comparison covers only the dimensions both grammars model; a dimension
modeled on one side only is reported `unknown`, never `preserved` or `diverged`.
Each result carries `modeled_kinds`, and degradation across a language pair is
normal. Quote `modeled_kinds` for both languages on any UNKNOWN. Verdicts
are advisory.

## Output

Per ported symbol: the equivalence result, the parity verdict with
`dimensions_checked` and `mismatches`, the manifest status, and the gate verdict.
