---
name: code-navigation
description: >
  Traverse large repositories efficiently using act's query tools. Use when
  exploring unfamiliar code, mapping dependencies, understanding API surfaces,
  analyzing side effects before modifying functions, or following call chains
  across files. Avoids reading entire files by querying only the structure needed.
---

# Code Navigation with act

Use act's query tools to traverse large repositories efficiently.
Do NOT read entire files when you can query for specific information.

## Rules

1. **Start with repo-outline** — Before exploring a codebase, run `repo_outline` to understand the file tree, languages, and structure. Use `--symbols` for files of interest.

2. **Use skeleton for file structure** — When you need to understand a file's structure, use `skeleton` to see declarations without bodies. Never read an entire file just to find function names.

3. **Use interface for API surfaces** — When you need to understand how to use a class or module, use `interface` to get signatures, types, and docstrings without implementation details.

4. **Follow the dependency graph** — Use `graph` to understand how files are connected. Start from the file you're interested in with `--direction out` (what it depends on) or `--direction in` (what depends on it).

5. **Use mutations for side-effect analysis** — Before modifying a function, use `mutations` to understand what external state it accesses or modifies. This tells you what might break.

6. **Use control-flow for complex logic** — When a function is hard to understand, use `control_flow` to get a linearized view of its branching structure.

7. **Batch symbol retrieval** — When you need symbols from multiple files, use `symbols_batch --files` instead of making separate `symbols` calls. When you need specific implementations, use `symbols_batch --ids` with stable IDs.

8. **Use stable symbol IDs** — After finding a symbol, use its stable ID (format: `file::QualifiedName#kind`) for subsequent operations. This avoids ambiguity and eliminates the need to specify `--file`.

9. **Use definition for cross-file navigation** — When you find a reference to an unknown symbol, use `definition` to jump to its source.

10. **Analyze before modifying** — Before making changes, run `mutations` on affected functions and `graph` on affected files to understand the blast radius.

## Token-Saving Hints

- `repo_outline` costs ~7 tokens/file (vs reading files: ~250 tokens/file)
- `skeleton` costs ~15 tokens/declaration (vs reading full file)
- `interface` costs ~25 tokens/member (vs reading implementation)
- Always use compact mode (default) — ranges are strings, not objects
- Use `--depth` limits on `graph` and `repo_outline` to control output size
- Filter `symbols_batch` with `--kinds` to get only what you need
