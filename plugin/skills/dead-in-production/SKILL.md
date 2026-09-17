---
name: dead-in-production
description: Use when removing code and a static dead-code signal alone feels risky. Finds symbols that are statically unreferenced, never covered by tests, and never executed in production.
---

# Dead in Production

Find code that is safe to delete by requiring three independent signals to agree:
statically unreachable, untested, and never run in production.

## When to use

- Cleanup or dead-code removal where the static signal alone is not enough.
- Shrinking a service before a refactor or migration.

## Inputs

An lcov coverage report and an OTLP/JSON trace export from production.
`coverage_overlay` and `trace_overlay` are Architecture tier; `analyze_dead_code` is
static (Free). None of the three needs git.

## Protocol

1. **Static**: `analyze_dead_code` finds symbols unreferenced from any entry point.
2. **Untested**: `coverage_overlay` with the lcov report; `covered: false` or zero hits
   means untested.
3. **Unused in prod**: `trace_overlay` with the production trace; zero `span_count`
   means it never ran in the captured window.
4. **Intersect**: a symbol that is statically dead, uncovered, and untraced is
   high-confidence dead and leads the report. Two of three is "probably dead, verify"; one of three is
   "investigate".
5. **Caveat**: reflection, DI, and dynamic dispatch hide real uses from static
   analysis, and coverage and trace windows can be incomplete. State the evidence
   window and the `unmapped` counts.

## Output

A ranked deletion list: 3/3 first, then 2/3 with the missing signal named, then 1/3.
For each entry cite the symbol id and which signals fired. Close with the trace and
coverage `unmapped` counts and the trace time window.

## Coverage

Read `modeled_kinds` and `unmapped` on every overlay result: a symbol that mapped
to no coverage or trace fact is "no evidence", not "dead".
Deletion recommendations need at least two agreeing signals. Coverage and trace
describe the captured window only.
