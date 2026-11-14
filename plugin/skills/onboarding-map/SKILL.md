---
name: onboarding-map
description: Use when a developer or agent is new to a codebase and needs a path through it. Produces a guided reading order (entry points first, then high-traffic and load-bearing code) annotated with ownership and risk flags.
---

# Onboarding Map

Turn an unfamiliar repository into an ordered reading list: where to start, what to
read next, and what to be careful around.

## Inputs

A git repository with history for `churn_hotspots` (workspace mode) and
`ownership_map`, both Architecture tier. `repo_outline` (Free) and
`analyze_entry_points` (Engineering) are static and need no git. When no git
history is available (not a repository, or none or shallow history),
`analyze_hotspots` (Engineering) replaces churn in step 3: it ranks by static
complexity, not change frequency. Ownership (step 4) has no static fallback:
it is skipped, and owners read unknown.

## Protocol

1. **Shape**: `repo_outline`, scoped with `depth` or `include`, for the file tree,
   languages, and sizes.
2. **Entry points**: `analyze_entry_points` for mains, HTTP routes, CLI commands, and
   event listeners. Execution, and reading, begins here.
3. **Traffic**: `churn_hotspots` in workspace mode for the most actively changed
   code. Without git history, `analyze_hotspots` (`top_n`, `include`) instead —
   the ranking is then where complexity concentrates, and every risk flag
   derived from it is complexity-based, not churn-based. Say which basis was
   used.
4. **Ownership**: `ownership_map` for who knows what, and which symbols have a low
   bus factor. Without git history there is no ownership: skip this step, mark
   every reading step's owners unknown, and say so in the report.
5. **Sequence**: entry points, then the high-churn core they reach, then supporting
   modules. Annotate each step with its owners and a risk flag for low-bus-factor or
   high-churn code. Keep it short and ordered: a path, not a catalog.
6. **Connections**: for each of the first top files in the order, `graph` with
   `file` = that file, `depth` = 1, `direction` = `both` — its direct
   dependencies and direct dependents. Annotate that reading step with them:
   what the file needs read first, and what depends on it staying stable.

## Output

An ordered reading list. Each step: what to read (file or symbol), why it is next
(entry point, high churn, load-bearing), its owners, and any risk flag. End with the
areas to be careful around (low bus factor, high churn).

## Coverage

Ownership and churn are git facts, but for grammars without symbol extraction they
degrade to file level; `modeled_kinds` says which grammars degraded, so report it. Entry-point and
outline data are syntactic. Files in grammars without dependency edges get no
`graph` pass in step 6 — say so when it happens. When step 3 ran on the
`analyze_hotspots` fallback, the traffic ranking and its risk flags are
complexity-based, not churn-based. When ownership was skipped for the same
reason, every owner in the reading list reads unknown, not unowned.
