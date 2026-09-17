---
name: code-navigation
description: Use when exploring unfamiliar code, mapping dependencies, reading an API surface, tracing call chains or data flow across files, or checking a function's side effects before changing it. Queries structure and bindings instead of reading whole files.
---

# Code Navigation with act

act's query tools answer questions about structure and bindings. Read and Grep answer
questions about text. Pick by the shape of the question: "what does this file
declare" or "who binds this symbol" is an act query; "where does this string
appear" or "show me lines 40-80" is a Read or Grep.

## Which tool answers which question

| Question | Tool | Notes |
|---|---|---|
| What is in this repo? | `repo_outline` | Always scope it (`depth`, `include`, `path`, or `max_files`); an unscoped outline of a medium repo stays in context for the whole session. Add `symbols: true` only for a narrowed path. |
| What does this file declare? | `skeleton` | Signatures and declarations, no bodies. |
| How do I call this? | `interface` | Signatures, types, and docstrings for one named symbol. |
| What does this file import, and what imports it? | `graph` | `direction: "out"` for dependencies, `"in"` for dependents; `depth` bounds the walk. |
| Where is this symbol defined? | `definition` | AST-based, no LSP needed. |
| Where is this symbol used? | `references` | Resolves the binding, not the text. Requires LSP. |
| What is defined across these files? | `symbols_batch` | Pass `kinds` or `pattern`; unfiltered output over several files is large. Pass `ids` to fetch specific implementations by stable ID. |
| What does this function touch, and is it pure? | `effect_summary` | Reads, writes, raises, allocations, blocking calls, awaits, a purity verdict, and the unresolved-call frontier. |
| Which external state does it read or write, exactly? | `mutations` | The raw access list behind `effect_summary`. |
| How does control flow through it? | `control_flow` | Linearized branches and loops. |
| Where does this value come from or go? | `data_flow` | Definition sites, use sites, def-to-use edges, and the locals that reach the return, within one function. |

## Working rules

- Use a symbol's stable ID (`file::QualifiedName#kind`) for follow-up calls once you
  have it; it removes ambiguity and the need to repeat `file`.
- Before modifying a function, run `effect_summary` on it and `graph` on its file so
  the blast radius is known before the edit.
- Follow the pairing hints in tool responses: `symbols` leads to `definition`, which
  leads to `references`, which leads to `rename`.
