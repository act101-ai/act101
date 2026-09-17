---
name: where-bugs-live
description: Use when you need the riskiest code in a repository, where bugs are most likely to live. Combines git churn, complexity, co-change coupling, and ownership concentration into one ranked, explained list.
---

# Where Bugs Live

Rank the code most likely to harbor defects. Bugs cluster where code changes often,
is complex, is entangled with other code, and is owned by few people.

## When to use

- Prioritizing a code-review, test-writing, or refactoring effort on a large codebase.
- Onboarding to an unfamiliar repo and wanting to know where the landmines are.
- Triaging technical debt with evidence.

## Inputs

A git repository with history for the three git overlays: `churn_hotspots`
(workspace mode), `co_change_clusters`, and `ownership_map`, all Architecture tier.
`analyze_hotspots` is static (Engineering) and needs no git.

## Protocol

1. **Churn**: `churn_hotspots` in workspace mode (no `file`) ranks symbols by
   recency-weighted change frequency.
2. **Complexity**: `analyze_hotspots` ranks files by composite complexity
   (cyclomatic, statements, nesting).
3. **Coupling**: `co_change_clusters` finds symbols that change together. Hidden
   coupling means a fix in one place needs a fix in another.
4. **Ownership**: `ownership_map` finds low-bus-factor symbols.
5. **Synthesize**: intersect and rank. A symbol that is high-churn, complex, in a
   co-change cluster, and low-bus-factor is a top risk. For each entry name the
   signals that fired and why they matter, with the symbol id and file.

## Output

A ranked, explained risk list. Each item: symbol or file, the firing signals (churn
score, complexity, co-change members, bus factor), and a one-line reason. Lead with
the entries where the most signals agree.

## Coverage

For grammars without symbol extraction, churn, co-change, and ownership degrade to
file level. Each response's `modeled_kinds` shows whether symbol extraction was
modeled; when it was not, report file-level precision as such. Churn and ownership
are git facts; complexity is a syntactic estimate.
