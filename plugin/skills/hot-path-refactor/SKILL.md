---
name: hot-path-refactor
description: Use when choosing what to optimize or refactor for performance. Ranks code by runtime hotness combined with static complexity and coupling, so effort lands where code is both expensive at runtime and hard to change.
---

# Hot Path Refactor

Target code that is both hot at runtime and structurally hard. Cold code is not
worth optimizing; hot but trivial code rarely pays; the wins are where hotness meets
complexity.

## When to use

- Performance work that needs evidence-chosen targets.
- Deciding which hot functions are worth refactoring and which to leave alone.

## Inputs

A CPU profile in speedscope JSON (py-spy, Austin) or pprof format, and the source
tree. `profile_overlay` is Architecture tier.

## Protocol

1. **Hotness**: `profile_overlay` with the profile ranks symbols by `self_pct`
   (direct cost) and `total_pct` (inclusive cost).
2. **Complexity**: `analyze_hotspots` ranks files and functions by composite
   complexity (cyclomatic, statements, nesting).
3. **Coupling**: `analyze_coupling` shows how entangled a hot symbol's module is;
   refactoring a high-coupling hot path is riskier and higher-value.
4. **Synthesize**: rank by hot × hard. High `self_pct` with high complexity is the
   top refactor target. High `self_pct` with low complexity suggests an algorithmic
   or throughput fix rather than a refactor. High `total_pct` with low `self_pct`
   means the cost is in callees; follow the stack.
5. **Recommend**: for each top target give the profile evidence (self and total
   percent), the complexity signal, and one concrete next step (optimize in place,
   extract, or reduce coupling first).

## Output

A ranked target list. Each entry: symbol id, `self_pct` and `total_pct`, complexity
and coupling signals, and a one-line action. Lead with the hot-and-hard
intersections.

## Coverage

Profile percentages are relative to the captured workload; a different workload
shifts the hot set. Read `modeled_kinds` and `unmapped`: frames that mapped to no
symbol are excluded, not zero-cost. Complexity is a syntactic estimate.
