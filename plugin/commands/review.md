---
name: review
description: Review code for issues using act's diagnostic and analysis tools
usage: /review <query> <target> [options]
examples:
  - /review diagnostics src/
  - /review skeleton src/auth/
  - /review references ExportedSymbol
---

# /review Command

Review code for issues using act's query tools, focused on finding problems.

## Usage

```
/review <query> <target> [options]
```

## Available Review Queries

### Bug Detection (requires LSP)

| Query | Description | Example |
|-------|-------------|---------|
| `diagnostics` | Errors, warnings, hints | `diagnostics src/` |
| `get_type` | Check type at position | `get_type src/api.ts:45:12` |

### Structural Quality (parser-only)

| Query | Description | Example |
|-------|-------------|---------|
| `skeleton` | Function sizes, nesting depth | `skeleton src/auth/` |
| `symbols` | Symbol density, naming | `symbols src/auth/login.ts` |

### Dead Code & Coupling (requires LSP)

| Query | Description | Example |
|-------|-------------|---------|
| `references` | Find dead exports (0 refs) | `references ExportedSymbol` |
| `callers` | Measure coupling (caller count) | `callers processPayment` |

### CLI-Only Analysis (not available via MCP)

| Query | Status |
|-------|--------|
| `complexity` | CLI only |
| `duplicates` | CLI only |
| `unused` | Planned |
| `impact` | Planned |
| `dependencies` | Planned |
| `tests` | Planned |
| `coverage` | Planned |
| `suggest` | CLI only |

## Options

- `--workspace <path>` — Set workspace root explicitly
- `--trace` — Stream progress to stderr

## Common Workflows

### Review Changed Files
```
/review diagnostics src/auth/login.ts
/review diagnostics src/services/user.ts
```

### Find Code Smells
```
/review skeleton src/
/review diagnostics src/
```

### Pre-Refactor Analysis
```
/review references TargetSymbol
/review callers TargetSymbol
/review skeleton src/target-file.ts
```

## LSP Requirements

`diagnostics`, `references`, `callers`, `get_type` require an active language server. `skeleton` and `symbols` work without LSP.
