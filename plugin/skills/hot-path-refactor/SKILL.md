---
name: hot-path-refactor
description: Use when deciding what to optimize or refactor for performance — ranks code by combining runtime profile hotness with static complexity and coupling, so effort lands where it is both expensive at runtime and hard to change.
---

# Hot Path Refactor

Prioritize performance/refactor effort on code that is both hot at runtime and structurally hard. Optimizing cold code wastes effort; optimizing hot-but-trivial code rarely pays; the wins are where hotness meets complexity.

## When to use

- Performance work where you need to choose targets with evidence.
- Deciding which hot functions are worth refactoring vs. leaving alone.

## Inputs

A speedscope profile (py-spy/Austin or pprof→speedscope) and the source tree. Overlays are MCP tools (Architecture tier).

## Protocol

1. **Hotness** — call `profile_overlay` with the speedscope report to rank symbols by `self_pct` (direct cost) and `total_pct` (inclusive cost).
2. **Complexity** — call `analyze_hotspots` to rank files/functions by composite complexity (cyclomatic, statements, nesting).
3. **Coupling** — call `analyze_coupling` to find how entangled a hot symbol's module is (refactoring a high-coupling hot path is riskier and higher-value).
4. **Synthesize** — rank by hot × hard: a symbol with high `self_pct` AND high complexity is the top refactor target (expensive and changeable). High `self_pct` + low complexity → consider an algorithmic/throughput fix, not a refactor. High `total_pct` but low `self_pct` → the cost is in callees; follow the stack.
5. **Recommend** — for each top target, state the profile evidence (self/total %), the complexity signal, and a concrete next step (optimize in place / extract / reduce coupling first).

## Output

A ranked target list. Each: symbol id, `self_pct`/`total_pct`, complexity/coupling signals, and a one-line recommended action. Lead with hot-and-hard intersections.

## Honesty

Profile percentages are relative to the captured workload — say so; a different workload shifts the hot set. Respect `modeled_kinds`/`unmapped`: frames that mapped to no symbol are excluded, not zero-cost. Complexity is a syntactic estimate.
