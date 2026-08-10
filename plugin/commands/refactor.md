---
name: refactor
description: Perform semantic code refactoring using act's refactor tools
usage: /refactor <operation> <target> [options]
examples:
  - /refactor rename src/user.ts getUserData fetchUserProfile
  - /refactor extract-function src/utils.ts:10-20 validateInput
  - /refactor inline src/calc.ts tempResult
---

# /refactor Command

Perform semantic code refactoring using act's refactor tools.

## Usage

```
/refactor <operation> <target> [options]
```

## MCP Tools (Refactoring group — preview + undo supported)

The Refactoring group — `rename`, `extract_function`, `extract_variable`, `inline`, `move_symbol`, `insert_body`, `recipe_run` — is exposed as MCP tools with full preview and history support. (`import-organize` below is a Verification-group tool, invoked the same way.) Run the `status` tool for the live list and each tool's parameter contract; the table is illustrative, not the whole surface.

| Operation | Description | Example |
|-----------|-------------|---------|
| `rename` | Rename symbol + all references | `rename src/user.ts getUserData fetchUserProfile` |
| `extract-function` | Extract code range to function | `extract-function src/utils.ts:10-20 validateInput` |
| `extract-variable` | Extract expression to variable | `extract-variable src/calc.ts:15 basePrice` |
| `inline` | Inline variable or function | `inline src/utils.ts tempResult` |
| `move` | Move symbol to different file | `move src/models.ts UserService src/services/user.ts` |
| `import-organize` | Sort and clean imports | `import-organize src/main.ts` |

## CLI Operations

Many more operations are available via the `act` CLI, and the set is language-specific. Discover the live surface — never work from a memorized list:

```bash
act --list-operations                      # every operation, with `languages` per op
act --list-operations --language <lang>    # the surface for one language
```

Categories include extraction, generation, conversions, wrapping, and structural transformations, plus per-language operations. See the refactoring skill's [operation-catalog.md](../skills/refactoring/references/operation-catalog.md) discovery guide.

## Options

- `--preview` — Show changes without applying (default for MCP tools)
- `--workspace <path>` — Set workspace root explicitly
- `--trace` — Stream progress to stderr

## Workflow

1. **Preview changes** — All MCP operations support `preview=true`
2. **Review the diff** — Verify changes are correct
3. **Apply** — Re-run with `preview=false`
4. **Verify** — Run diagnostics to check for introduced errors
5. **Undo if needed** — `history_undo`

## Examples

### Rename with Preview
```
/refactor rename src/services/user.ts getUserData fetchUserProfile
```

### Extract Function
```
/refactor extract-function src/checkout.ts:45-60 validateCart
```

### Batch Generation (CLI)
```
/refactor generate-builder UserConfig --file src/models/config.ts
/refactor generate-to-json UserConfig --file src/models/config.ts
/refactor generate-from-json UserConfig --file src/models/config.ts
```

## File Creation

Refactor operations create target files automatically when needed. You do not need to create destination files before running:
- `move` — creates the destination file
- `extract-class` — creates a new file for the extracted class
- `extract-interface` — creates a new file for the extracted interface

Parent directories are also created automatically.

## Batching

Independent operations (different symbols, different files) should be dispatched in parallel. Only sequence operations where one depends on another's output. See the refactoring skill's compound-sequences reference for patterns.

## Error Handling

- **Symbol not found**: Suggests similar symbols
- **Ambiguous target**: Asks for clarification with file:line
- **Refactor introduced errors**: Use `history_undo` to revert, then investigate
