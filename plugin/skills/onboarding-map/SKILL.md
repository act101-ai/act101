---
name: onboarding-map
description: Use when onboarding to an unfamiliar codebase — produces a guided reading order (entry points first, then high-traffic and load-bearing code) annotated with ownership and risk flags.
---

# Onboarding Map

Turn an unfamiliar repository into a guided reading order: where to start, what to read next, and what to be careful around.

## When to use

- A developer (or agent) is new to a codebase and needs a path through it.
- Building a mental model fast, prioritizing the code that matters.

## Protocol

1. **Shape** — call `repo_outline` to get the file tree, languages, and sizes. This is the territory.
2. **Entry points** — call `analyze_entry_points` to find mains, HTTP routes, CLI commands, and event listeners. These are where execution (and reading) should begin.
3. **Traffic** — call `churn_hotspots` (workspace mode) to find the most actively-changed code — what the team touches daily.
4. **Ownership** — call `ownership_map` to find who knows what, and which symbols have a low bus factor (read these carefully; the expert may be unavailable).
5. **Sequence** — produce a reading order: entry points → the high-churn core they reach → supporting modules. Annotate each step with its owner(s) and a risk flag for low-bus-factor or high-churn code. Keep it short and ordered; this is a path, not a catalog.

## Output

An ordered reading list. Each step: what to read (file/symbol), why it's next (entry point / high churn / load-bearing), its owner(s), and any risk flag. End with "areas to be careful around" (low bus factor, high churn).

## Honesty

Ownership and churn are git facts but degrade to file-level for grammars without symbol extraction (`modeled_kinds`) — say so. Entry-point and outline data are syntactic.
