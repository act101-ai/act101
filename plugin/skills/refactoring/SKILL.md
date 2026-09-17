---
name: refactoring
description: Use when renaming symbols, extracting functions or variables, inlining, moving symbols between files, organizing imports, or making any code change that must update every reference. AST-aware, reference-correct, with preview and undo.
---

# Refactoring with act

The MCP refactor tools are tree-sitter based and need no LSP; each call reports
the kinds it modeled in `modeled_kinds`. This skill covers
`rename`, `extract_function`, `extract_variable`, `inline`, `move_symbol`, and
`import_organize`. The Refactoring group also ships `insert_body` (insert or replace
a function body) and `recipe_run` (multi-site codemod recipes, Enterprise).

## Tools

```
rename(file="src/user.ts", old_name="getData", new_name="fetchData", preview=true)
extract_function(file="src/utils.ts", new_name="validateInput", start_line=10, start_column=1, end_line=20, end_column=50, preview=true)
extract_variable(file="src/calc.ts", new_name="basePrice", start_line=15, start_column=5, end_line=15, end_column=40, preview=true)
inline(file="src/utils.ts", symbol="tempResult", preview=true)
move_symbol(file="src/models.ts", symbol="UserService", destination="src/services/user.ts", preview=true)
import_organize(file="src/main.ts", preview=true)
```

## Workflow

1. **Preview.** `preview` defaults to `false`, so set `preview=true` on the first
   run, especially for `rename` and `move_symbol`, which touch many files.
2. **Review** the returned `FileChange[]`.
3. **Apply** by re-running with `preview=false`.
4. **Verify** with one `diagnostics` call, passing the edited paths in `files`.
5. **Undo** a bad batch before stacking more changes on it:
   `history_undo(preview=true)` to see what reverts, then `history_undo()`.

Operations that touch different symbols and files are independent and can run in
one parallel batch; sequence only the operations that consume another's output.

`move_symbol` and the CLI operations `act refactor extract-class` and
`act refactor extract-interface` create their destination files themselves; target
the operation at the destination path and let it create the file.

## History

```
history_list(limit=10)
history_undo(count=1)
history_redo(count=1)
```

## Compound refactoring

Sequences such as extract-then-rename, move-then-organize, and decompose-god-class
are in [compound-sequences.md](references/compound-sequences.md).

## Code generation

After a structural refactor (extract class, extract interface) the new type usually
needs boilerplate. The code-generation skill covers batch generation of
constructors, accessors, equals, hash, serialization, and other derived methods.

## Full operation catalog

The `act` CLI ships 180+ named operations, registered per language across 163
grammars (generate-constructor, convert-async, wrap-try-catch, and so on).
[operation-catalog.md](references/operation-catalog.md) explains how to discover the
live per-language surface from the registry.

## Error recovery

See [error-recovery.md](references/error-recovery.md).
