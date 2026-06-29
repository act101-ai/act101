---
name: dead-in-production
description: Use when you want to safely remove code — finds symbols that are statically unreferenced, never covered by tests, and never executed in production, by intersecting dead-code, coverage, and trace evidence.
---

# Dead in Production

Find code that is safe to delete with high confidence by requiring three independent signals to agree: it is statically unreachable, untested, and never runs in production.

## When to use

- Cleanup / dead-code removal where a static signal alone feels risky.
- Shrinking a service before a refactor or migration.

## Inputs

A git repo, an lcov coverage report, and an OTLP/JSON trace export from production. All overlays are MCP tools (Architecture tier).

## Protocol

1. **Static** — call `analyze_dead_code` to find symbols unreferenced from any entry point.
2. **Untested** — call `coverage_overlay` with the lcov report; a symbol with `covered: false` (or zero hits) is untested.
3. **Unused in prod** — call `trace_overlay` with the production trace; a symbol absent from the hits (zero `span_count`) never ran in prod.
4. **Intersect** — a symbol present in ALL THREE (statically dead AND uncovered AND untraced) is high-confidence dead. Report it first. Symbols in two of three are "probably dead — verify"; one of three is "investigate."
5. **Caveat** — reflexion/DI/dynamic dispatch can hide real uses from static analysis; coverage and trace windows may be incomplete. State the evidence window and the `unmapped` counts so the user can judge.

## Output

A ranked deletion list: high-confidence (3/3) first, then 2/3 with the missing signal named, then 1/3. For each, cite the symbol id and which signals fired. Include the trace/coverage `unmapped` counts and the trace time window as caveats.

## Honesty

Respect `modeled_kinds` and `unmapped`: a symbol that mapped to no coverage/trace fact is "no evidence," not "dead." Never recommend deleting on a single signal. Coverage/trace are facts about the captured window only.
