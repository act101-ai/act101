# act MCP Tools Reference

17 tools exposed by the `act` MCP server. Tool names below are the canonical protocol names; individual MCP clients may render them with a client-specific prefix (e.g., Claude Code shows `skeleton`, Codex CLI shows `act.skeleton`).

## Quick Reference

| Tool | Purpose | LSP Required |
|------|---------|-------------|
| `status` | Workspace status and LSP readiness | No |
| `skeleton` | File structure without bodies | No |
| `symbols` | All symbols defined in a file | No |
| `diagnostics` | Errors, warnings, hints | Yes |
| `references` | Find all references to a symbol | Yes |
| `callers` | Find call sites for a function | Yes |
| `definition` | Jump to symbol definition | Yes |
| `get_type` | Get type of expression at position | Yes |
| `rename` | Rename symbol across codebase | No |
| `extract_function` | Extract code range to new function | No |
| `extract_variable` | Extract expression to variable | No |
| `inline` | Inline a variable or function | No |
| `move_symbol` | Move symbol to different file | No |
| `import_organize` | Sort and clean imports | No |
| `history_list` | List recent operations | No |
| `history_undo` | Undo last operation(s) | No |
| `history_redo` | Redo undone operation(s) | No |

## Query Tools

### status
Get workspace status including detected languages and LSP readiness. Call this first.
```json
{"name": "status"}
```
Returns: `{ name, version, operational, tools[], workspace: { root, languages[] } }`

### skeleton
Get file structure (function/class/method declarations) without bodies.
```json
{"name": "skeleton", "arguments": {"file": "src/main.ts"}}
```
Parameters: `file` (required) — path to source file.

### symbols
List all symbols defined in a file with their kinds and locations.
```json
{"name": "symbols", "arguments": {"file": "src/main.ts"}}
```
Parameters: `file` (required) — path to source file.

### diagnostics
Get compiler/linter errors, warnings, and hints for a file. Requires LSP.
```json
{"name": "diagnostics", "arguments": {"file": "src/main.ts"}}
```
Parameters: `file` (required) — path to source file.

### references
Find all references to a symbol across the workspace. Requires LSP.
```json
{"name": "references", "arguments": {"symbol": "UserService", "file": "src/services/user.ts"}}
```
Parameters: `symbol` (required), `file` (optional — scopes search, improves performance).

### callers
Find all call sites for a function or method. Requires LSP.
```json
{"name": "callers", "arguments": {"symbol": "processPayment", "file": "src/billing.ts"}}
```
Parameters: `symbol` (required), `file` (optional — locates symbol).

### definition
Jump to symbol definition location. Requires LSP.
```json
{"name": "definition", "arguments": {"symbol": "UserService", "file": "src/api.ts", "line": 15, "column": 10}}
```
Parameters: `symbol` (required), `file` (required), `line` (required, 1-indexed), `column` (required, 1-indexed).

### get_type
Get the type of an expression at a position. Requires LSP.
```json
{"name": "get_type", "arguments": {"file": "src/api.ts", "line": 42, "column": 12}}
```
Parameters: `file` (required), `line` (required, 1-indexed), `column` (required, 1-indexed).

## Refactor Tools

All refactor tools support `preview` mode (default: `false`). Set `preview: true` to see changes without applying them.

### rename
Rename a symbol and update all references across the codebase.
```json
{"name": "rename", "arguments": {"file": "src/user.ts", "old_name": "getData", "new_name": "fetchData", "preview": true}}
```
Parameters: `file` (required), `old_name` (required), `new_name` (required), `line` (optional), `column` (optional), `preview` (default: false).

### extract_function
Extract a code range into a new named function.
```json
{"name": "extract_function", "arguments": {"file": "src/utils.ts", "new_name": "validateInput", "start_line": 10, "start_column": 1, "end_line": 20, "end_column": 50, "preview": true}}
```
Parameters: `file` (required), `new_name` (required), `start_line` (required), `start_column` (required), `end_line` (required), `end_column` (required), `preview` (default: false).

### extract_variable
Extract an expression into a named variable.
```json
{"name": "extract_variable", "arguments": {"file": "src/calc.ts", "new_name": "basePrice", "start_line": 15, "start_column": 5, "end_line": 15, "end_column": 40, "preview": true}}
```
Parameters: `file` (required), `new_name` (required), `start_line` (required), `start_column` (required), `end_line` (required), `end_column` (required), `preview` (default: false).

### inline
Inline a variable or function at its usage sites.
```json
{"name": "inline", "arguments": {"file": "src/utils.ts", "symbol": "tempResult", "preview": true}}
```
Parameters: `file` (required), `symbol` (required), `line` (optional), `preview` (default: false).

### move_symbol
Move a symbol to a different file, updating all imports. Creates the destination file if it doesn't exist.
```json
{"name": "move_symbol", "arguments": {"file": "src/models.ts", "symbol": "UserService", "destination": "src/services/user.ts", "preview": true}}
```
Parameters: `file` (required), `symbol` (required), `destination` (required), `preview` (default: false).

### import_organize
Sort and clean up imports in a file.
```json
{"name": "import_organize", "arguments": {"file": "src/main.ts", "preview": true}}
```
Parameters: `file` (required), `preview` (default: false).

## History Tools

### history_list
List recent refactoring operations with affected files.
```json
{"name": "history_list", "arguments": {"limit": 10}}
```
Parameters: `limit` (optional, default: 10).

### history_undo
Undo the most recent operation(s).
```json
{"name": "history_undo", "arguments": {"count": 1, "preview": true}}
```
Parameters: `count` (optional, default: 1), `preview` (default: false).

### history_redo
Redo previously undone operation(s).
```json
{"name": "history_redo", "arguments": {"count": 1, "preview": true}}
```
Parameters: `count` (optional, default: 1), `preview` (default: false).

## Notes

- **Preview mode:** All refactor tools accept `preview`. When true, returns the diff without modifying files.
- **LSP tools:** Tools marked "Requires LSP" need a running language server. Check `status` first. If LSP is not ready, use parser-only tools (`skeleton`, `symbols`) while waiting.
- **Parser-only tools** (`skeleton`, `symbols`, all refactor tools) work immediately without LSP.
- **Positions are 1-indexed:** Lines start at 1, columns start at 1.
- **File creation:** Refactor and CLI operations automatically create target files (and parent directories) if they don't exist. You do NOT need to create files before running operations like `move_symbol`, `extract-class`, or `extract-interface`. The operation handles it.
- **Batching:** Independent operations (different symbols, different files) should be dispatched in parallel. Only sequence operations where one depends on another's output.
