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
`analyze_entry_points` (Engineering) are static and need no git.

## Protocol

1. **Shape**: `repo_outline`, scoped with `depth` or `include`, for the file tree,
   languages, and sizes.
2. **Entry points**: `analyze_entry_points` for mains, HTTP routes, CLI commands, and
   event listeners. Execution, and reading, begins here.
3. **Traffic**: `churn_hotspots` in workspace mode for the most actively changed
   code.
4. **Ownership**: `ownership_map` for who knows what, and which symbols have a low
   bus factor.
5. **Sequence**: entry points, then the high-churn core they reach, then supporting
   modules. Annotate each step with its owners and a risk flag for low-bus-factor or
   high-churn code. Keep it short and ordered: a path, not a catalog.

## Output

An ordered reading list. Each step: what to read (file or symbol), why it is next
(entry point, high churn, load-bearing), its owners, and any risk flag. End with the
areas to be careful around (low bus factor, high churn).

## Coverage

Ownership and churn are git facts, but for grammars without symbol extraction they
degrade to file level; `modeled_kinds` says which grammars degraded, so report it. Entry-point and
outline data are syntactic.
