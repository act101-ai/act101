---
name: architectural-refactoring
description: >
  Execute structural decompositions based on an architectural analysis report.
  Use when breaking circular dependencies, splitting god classes, reducing coupling
  between modules, extracting interfaces at seam boundaries, or executing any
  large-scale structural change identified in an architectural analysis. Requires
  the architectural-analysis skill to have been run first.
---

# Architectural Refactoring with act

Execute structural decompositions based on an architectural analysis report.

## Prerequisites

The `architectural-analysis` report must exist at `docs/architectural-analysis-report.md`.
If it doesn't exist, run the `architectural-analysis` skill first.

## Rules

1. **Start from the report** — Read the analysis report first. Every refactoring decision should trace back to a finding in the report.

2. **Find seams, don't invent them** — Use `act analyze seams` to identify natural boundaries. Refactor along these boundaries, not against them.

3. **Evaluate before cutting** — Before extracting a module, use `act analyze surface --files <files>` to measure the API surface. If the surface is too wide, the extraction will create more coupling, not less.

4. **Break cycles first** — Circular dependencies are the highest priority. Use `act analyze cycles` to find them, then break the simplest edge in each cycle.

5. **Extract interfaces at seams** — At each seam boundary, extract an interface that both sides depend on. Use `act query interface <file>` to understand the current API, then `act refactor extract-interface` to create it.

6. **Stable foundations first** — Start with the most stable modules (lowest instability in `act analyze coupling`). Make them independent before touching unstable modules.

7. **Measure coupling reduction** — After each refactoring step, re-run `act analyze coupling` and `act analyze cycles` to verify that coupling decreased and cycles were broken.

8. **Use dead code analysis for cleanup** — Before and after each major refactoring, run `act analyze dead-code` to identify symbols that are no longer needed.

9. **Document the architecture** — After each major change, update the analysis report by re-running `architectural-analysis`.

10. **Incremental, verifiable steps** — Each refactoring step should be small enough to verify independently. Commit after each step. Never make multiple structural changes at once.

## Workflow

1. Read the analysis report
2. Prioritize findings: cycles > god classes > high coupling > dead code
3. For each finding:
   a. Verify it's still present (`act analyze cycles` / `act analyze coupling`)
   b. Plan the refactoring (identify seams, measure surface)
   c. Execute the refactoring using `act refactor` operations
   d. Verify the fix (re-run analysis, check tests)
   e. Commit

## Delegation

- Use `refactoring` skill for individual operations (rename, extract, move)
- Use `code-generation` skill for scaffolding new modules
- Use `code-navigation` skill to understand code before modifying it

## Token-Saving Hints

- Use `act analyze cycles` with `--max-length 3` to focus on the tightest cycles first
- Use `act analyze coupling --threshold 0.7` to focus on the most unstable modules
- Use `act query skeleton` instead of reading full files
- Re-run only the specific analysis that your change affects, not the full suite
