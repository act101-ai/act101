# Error Recovery for Refactoring

## Refactor Introduced Errors

**Symptom:** `diagnostics` shows new errors after a refactor operation.

**Recovery:**
1. `history_undo(preview=true)` — see what undo would revert
2. `history_undo()` — revert the broken refactor
3. `diagnostics` — confirm errors are gone
4. Investigate why the refactor failed before retrying

**Common causes:**
- Rename collision with existing symbol
- Extract created a function with missing closure variables
- Move didn't update all import paths

## Symbol Not Found

**Symptom:** Rename or inline returns "symbol not found."

**Recovery:**
1. Use `symbols(file="path")` to list all symbols in the file
2. Check exact spelling, case, and that the symbol is at the expected location
3. Provide `line` and `column` parameters to disambiguate

## Preview Shows Unexpected Changes

**Symptom:** Preview returns changes you didn't expect (wrong files, wrong locations).

**Recovery:**
1. Don't apply — keep `preview=true`
2. The symbol name may be ambiguous (e.g., `data` appears in many files)
3. Provide `file`, `line`, `column` parameters to narrow scope
4. Use `references` first to understand the full scope before refactoring

## Undo Not Available

**Symptom:** `history_undo` reports nothing to undo.

**Recovery:**
- History is session-scoped — it resets when the MCP server restarts
- If the server restarted between refactor and undo, manual revert via git is needed
- Always commit or stash before large refactoring sessions
