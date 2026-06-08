---
name: code-review
description: >
  Review code for bugs, complexity, unused symbols, and structural issues using
  AST-aware analysis. Use when reviewing PRs, checking code quality, finding dead
  code, analyzing function complexity, auditing a codebase, or checking for type
  errors. Works across TypeScript, Python, Rust, Go, and 14 more languages.
---

# Code Review with act

Analyze code for issues using act's 8 query tools.

## Start Here

Check workspace status first — some tools require LSP:
```
status()
```

## Exploration Pattern

For systematic file exploration, use a two-pass approach: parser-only tools first (`skeleton`, `symbols`), then LSP tools (`diagnostics`, `references`, `callers`). Start broad (directory skeletons), narrow (file symbols), then deep (reference chains).

## Core Review Tools

### Always available (parser-only)

**skeleton** — Get file structure. Shows function signatures, class declarations, nesting depth.
```
skeleton(file="src/auth/login.ts")
```

**symbols** — List all symbols with kinds and locations. Spot missing exports, large symbol counts.
```
symbols(file="src/auth/login.ts")
```

### Requires LSP

**diagnostics** — Compiler/linter errors, warnings, hints. The primary bug-finding tool.
```
diagnostics(file="src/auth/login.ts")
```

**references** — Find all references to a symbol. Detect unused exports (0 external references).
```
references(symbol="validateToken", file="src/auth/token.ts")
```

**callers** — Find functions that call a symbol. Understand coupling and blast radius.
```
callers(symbol="processPayment", file="src/billing.ts")
```

**definition** — Jump to where a symbol is defined. Trace imports to source.
```
definition(symbol="UserService", file="src/api.ts", line=15, column=10)
```

**get_type** — Get the inferred type at a position. Check type correctness.
```
get_type(file="src/api.ts", line=42, column=12)
```

## Review Workflow

### For a single file
1. `diagnostics` — get all errors/warnings
2. `skeleton` — check structure (function sizes, nesting)
3. `symbols` — check symbol density and naming

### For a directory/module
1. `skeleton` on each file — build structural overview
2. `diagnostics` on each file — collect all issues
3. `references` on exports — find unused public API
4. `callers` on key functions — check coupling

### For a PR (changed files)
1. `diagnostics` on each changed file
2. `skeleton` on changed files — check new structure
3. `references` on renamed/moved symbols — verify all references updated
4. `callers` on modified functions — assess impact

## What to Look For

| Signal | Tool | Severity |
|--------|------|----------|
| Compiler errors | diagnostics | Error |
| Type mismatches | diagnostics, get_type | Error |
| Unused imports/variables | diagnostics | Warning |
| Function >50 lines | skeleton | Warning |
| Function >5 parameters | skeleton | Warning |
| Nesting depth >4 | skeleton | Warning |
| Symbol with 0 references | references | Info |
| High caller count (>10) | callers | Info |

## Advanced Patterns

See [review-patterns.md](references/review-patterns.md) for detailed review checklists and multi-file analysis strategies.

## Error Recovery

See [error-recovery.md](references/error-recovery.md) for handling LSP failures, file-not-found, and ambiguous symbols.

## Output Format

Report findings grouped by severity:

```
## Review: src/auth/login.ts

### Errors (2)
- Line 45: Type 'string' is not assignable to type 'number' [diagnostics]
- Line 72: Cannot find name 'authConfig' [diagnostics]

### Warnings (3)
- Line 15-80: Function `handleLogin` is 65 lines (>50 threshold) [skeleton]
- Line 23: Unused import 'lodash' [diagnostics]
- Line 90: `validateToken` has 0 external references — possibly dead code [references]

### Info (1)
- `processAuth` called from 12 locations — high coupling [callers]
```
