---
name: where-bugs-live
description: Use when you need to find the riskiest code in a repository — where bugs are most likely to live — by combining git churn, complexity, co-change coupling, and ownership concentration into one ranked, explained list.
---

# Where Bugs Live

Rank the code most likely to harbor defects by composing four signals. Bugs cluster where code changes often, is complex, is entangled with other code, and is owned by few people.

## When to use

- Prioritizing a code-review, test-writing, or refactoring effort on a large codebase.
- Onboarding to an unfamiliar repo and wanting to know where the landmines are.
- Triaging technical debt with evidence, not vibes.

## Inputs

The git-overlay ops require a git repository with history. All are MCP tools (Architecture tier).

## Protocol

1. **Churn** — call `churn_hotspots` (workspace mode, no `file`) to rank symbols by recency-weighted change frequency. High churn = actively-changing, defect-prone code.
2. **Complexity** — call `analyze_hotspots` to rank files by composite complexity (cyclomatic, statements, nesting). Complex code hides bugs.
3. **Coupling** — call `co_change_clusters` to find symbols that change together. Hidden coupling means a fix in one place needs a fix in another — a classic bug source.
4. **Ownership** — call `ownership_map` to find low-bus-factor symbols. Code owned by one departed author is risky to touch.
5. **Synthesize** — intersect and rank: a symbol that is *high-churn AND complex AND in a co-change cluster AND low-bus-factor* is a top risk. Present a ranked list; for each entry, name which signals fired and why it matters. Cite the symbol id and file.

## Output

A ranked, explained risk list. Each item: symbol/file, the firing signals (churn score, complexity, co-change members, bus factor), and a one-line "why this is risky." Lead with the highest-confidence intersections (multiple signals agree).

## Honesty

Respect `modeled_kinds`: for grammars without symbol extraction, churn/co-change/ownership degrade to file-level — say so rather than implying symbol precision. Churn and ownership are git facts; complexity is a syntactic estimate.
