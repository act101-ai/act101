---
name: refactoring
description: >
  Perform semantic code refactoring using AST-aware tools. Use when renaming symbols,
  extracting functions or variables, inlining code, moving symbols between files,
  organizing imports, or any code transformation that must update all references.
  Supports preview mode and undo. Each call reports the kinds it modeled in
  `modeled_kinds`; the supported-language list is whatever act ships.
---

# Refactoring with act

MCP refactor tools with preview mode and undo/redo — this skill documents `rename`, `extract_function`, `extract_variable`, `inline`, `move_symbol`, and `import_organize`; the MCP catalog's Refactoring group also ships `insert_body` (insert/replace a function body) and `recipe_run` (multi-site recipes, Enterprise). All tools are tree-sitter based — no LSP required.

## Start Here

```
status()
```

## Refactor Tools

### rename
Rename a symbol and update all references across the codebase.
```
rename(file="src/user.ts", old_name="getData", new_name="fetchData", preview=true)
```

### extract_function
Extract a code range into a new named function.
```
extract_function(file="src/utils.ts", new_name="validateInput", start_line=10, start_column=1, end_line=20, end_column=50, preview=true)
```

### extract_variable
Extract an expression into a named variable.
```
extract_variable(file="src/calc.ts", new_name="basePrice", start_line=15, start_column=5, end_line=15, end_column=40, preview=true)
```

### inline
Inline a variable or function at all usage sites.
```
inline(file="src/utils.ts", symbol="tempResult", preview=true)
```

### move_symbol
Move a symbol to a different file, updating all imports.
```
move_symbol(file="src/models.ts", symbol="UserService", destination="src/services/user.ts", preview=true)
```

### import_organize
Sort and clean up imports in a file.
```
import_organize(file="src/main.ts", preview=true)
```

## Workflow

1. **Preview first** — the default is `preview=false`, so always set `preview=true` explicitly on the first run
2. **Review the diff** — Check the returned `FileChange[]` array
3. **Apply** — Re-run with `preview=false`
4. **Verify** — Run `diagnostics(file="...")` to check for introduced errors
5. **Undo if needed** — `history_undo(preview=true)` then `history_undo()`

## History (Undo/Redo)

```
history_list(limit=10)   # See recent operations
history_undo(count=1)    # Undo last operation
history_redo(count=1)    # Redo undone operation
```

## Safety Rules

1. **Always preview before applying** — especially for rename and move_symbol which affect multiple files
2. **Run diagnostics after each batch of refactors** — catch introduced errors immediately
3. **Batch independent operations in parallel** — operations that touch different symbols/files can run concurrently. This is the primary efficiency advantage of act. Only sequence operations that depend on each other's output.
4. **Undo immediately if diagnostics show new errors** — don't stack more refactors on top of a broken state
5. **Don't create files manually** — operations like `move_symbol`, `extract-class`, and `extract-interface` create destination files automatically. Never write a file just so an operation can target it.

## Compound Refactoring

Complex refactors often require sequences of operations. See [compound-sequences.md](references/compound-sequences.md) for patterns like extract-then-rename, move-then-organize, and decompose-god-class.

## Code Generation

After structural refactoring (extract class, extract interface), the new type often needs boilerplate. See the **code-generation** skill for batch generation of constructors, accessors, equals, hash, serialization, and other derived methods.

## Full Operation Catalog

The `act` CLI supports thousands of registry-defined operations across 163 grammars beyond the MCP tools (generate-constructor, convert-async, wrap-try-catch, …). See [operation-catalog.md](references/operation-catalog.md) for how to discover the live per-language surface — it is registry-derived, never a hand list.

## Error Recovery

See [error-recovery.md](references/error-recovery.md) for handling common failures.
