---
name: explore
description: Explore and understand code structure using act's query tools
usage: /explore <query> <target> [options]
examples:
  - /explore skeleton src/main.ts
  - /explore symbols src/auth/
  - /explore references UserService
  - /explore callers handleRequest
---

# /explore Command

Explore and understand code structure using act's query tools.

## Usage

```
/explore <query> <target> [options]
```

## Available Queries

### Structure (parser-only — always work)

| Query | Description | Example |
|-------|-------------|---------|
| `skeleton` | File structure without bodies | `skeleton src/main.ts` |
| `symbols` | All symbols in a file | `symbols src/auth/login.ts` |

### Reference & Navigation (requires LSP)

| Query | Description | Example |
|-------|-------------|---------|
| `definition` | Symbol definition location | `definition handleAuth` |
| `references` | All references to a symbol | `references UserService` |
| `callers` | Functions that call a symbol | `callers processPayment` |
| `get_type` | Type information at position | `get_type src/api.ts:45:12` |
| `diagnostics` | Errors and warnings | `diagnostics src/` |

### CLI-Only Queries (not available via MCP)

These queries are available through the `act` CLI but not yet exposed as MCP tools:

| Query | Description | Status |
|-------|-------------|--------|
| `callees` | Functions called by a symbol | CLI only |
| `implementations` | Interface/trait implementations | CLI only |
| `hierarchy` | Class/type hierarchy | CLI only |
| `suggest` | Fix suggestions | CLI only |
| `duplicates` | Duplicate code blocks | CLI only |
| `complexity` | Complexity metrics | CLI only |
| `dependencies` | Dependency analysis | Planned |
| `impact` | Change impact analysis | Planned |
| `unused` | Unused code detection | Planned |
| `tests` | Find tests for a symbol | Planned |
| `coverage` | Coverage information | Planned |

## Options

- `--workspace <path>` — Set workspace root explicitly
- `--trace` — Stream progress to stderr

## Examples

### Get File Skeleton
```
/explore skeleton src/services/user.ts
```

### Find All References
```
/explore references UserService
```

### Trace Call Hierarchy
```
/explore callers processPayment
```

## LSP Requirements

Queries in the "Reference & Navigation" section require an active language server. Parser-only queries (`skeleton`, `symbols`) work immediately.
