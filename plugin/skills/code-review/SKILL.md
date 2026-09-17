---
name: code-review
description: Use when reviewing a PR, checking code quality, finding dead code, measuring function complexity, auditing a module, or checking for type errors. AST-aware analysis plus the deterministic merge gate.
---

# Code Review with act

## Tools

Parser-only, always available:

- `skeleton(file)`: structure, signatures, nesting depth.
- `symbols(file)`: every symbol with kind and location.
- `unsafe_surface(file)`: unsafe blocks, `eval`, raw SQL, FFI, reflective
  invocation, unsafe deserialization. Run it on any file handling input, queries,
  or native interop. `modeled_kinds` says which categories the grammar models; an
  empty surface with an empty mask is unmodeled, not clean.
- `definition(symbol, file, line, column)`: where a symbol is defined, AST-based.

Language-server backed (the server starts on first call; `status` reports LSP
readiness; `references` and `callers` name the answering server in `resolved_by`):

- `diagnostics(files=[…])`: compiler and linter errors, warnings, hints. Call it
  once over the change with every edited path in `files`, not once per file.
- `references(symbol, file)`: every binding of a symbol; zero external references
  on an export means possibly dead.
- `callers(symbol, file)`: call sites, for coupling and blast radius.
- `get_type(file, line, column)`: inferred type at a position.

Explore broad to narrow: directory skeletons, then file symbols, then reference
chains.

## Workflow

**Single file**: `diagnostics`, then `skeleton` for function sizes and nesting, then
`symbols` for density and naming.

**Directory or module**: `skeleton` per file for the structural overview; one
`diagnostics` call over the files; `references` on exports to find unused public
API; `callers` on key functions for coupling.

**PR (changed files)**:

1. One `diagnostics` call over the changed files.
2. `skeleton` on changed files for the new structure.
3. `references` on renamed or moved symbols to confirm every binding moved.
4. `callers` on modified functions for direct impact, and
   `analyze_impact(target=<file>, symbol=<name>)` (Architecture) for transitive
   callers without LSP. Confirm the symbol name with `skeleton` first and read
   `confidence`, `modeled_kinds`, and `unresolved`.
5. `analyze_api_diff(base_ref=<base>)` (Architecture; CLI `act analyze api-diff
   --base-ref <base>`) when the PR touches public API. It diffs the merge-base of
   the base branch against the working tree and returns per-symbol `rows` and
   `summary` counts. Cite **Breaking** (a parameter added, an export removed),
   **PossiblyBreaking** (other signature drift), and **Additive** rows, and surface
   every **Unjudgeable** row: it names a grammar whose visibility act does not
   model, so that change is unjudged, not safe.
6. `scan(root=<repo>, base_ref=<base>)` for the AI-code security pass over the
   change: hardcoded credentials, `.cursorrules` backdoors, MCP-config RCE, typosquat
   or hallucinated dependencies, Actions expression injection, LLM-output-to-exec
   flows, prompt-injection surfaces, and the AI-Code Health Score. With `base_ref`
   the scan computes the changed set itself (merge-base, rename-aware) and discloses
   it in the report's `scope` section. Without a git base, pass
   `files=[<changed files>]` instead (`scope.mode: "paths"`). Either way the score
   covers only the selected files and is never comparable to a full-repo score. With a committed `.act/baseline.json`, add
   `baseline=".act/baseline.json"`: `baseline.new_finding_ids` is then exactly the
   set of findings this change introduces.
7. `gate(base_ref=<base>)` (CLI `act gate --base-ref <base>`) for the merge-safety
   verdict over the whole changed set. Cite its output directly; the gate owns the
   rules, and `verify_diff_semantics`, `verify_test_impact`, and
   `verify_side_effects` are its inputs. Verdict semantics, exit codes, and
   degradation rules are in the safe-to-merge skill. UNKNOWN means not verified,
   never a pass.

   `gate --receipts` (MCP `gate(receipts=true)`) writes per-function receipts to
   `.act/receipts/`. On a later run, functions matching a valid receipt report
   `pre-verified by receipt <id>`, which reviewers may accept without re-running the
   trio. Receipt mechanics are in the refactor-receipt skill. A behavior change with
   no test reaching it blocks:

   ```
   $ act gate
   act gate — working tree vs HEAD (1 changed function(s))
     BLOCK   auth.ts::validateAge — behavior, NO test reaches it (behavior change with no test reaching it)
   verdict: BLOCK
   $ echo $?
   1
   ```

## What to look for

| Signal | Tool | Severity |
|--------|------|----------|
| Compiler errors | diagnostics | Error |
| Type mismatches | diagnostics, get_type | Error |
| Unused imports or variables | diagnostics | Warning |
| Function over 50 lines | skeleton | Warning |
| Function with over 5 parameters | skeleton | Warning |
| Nesting depth over 4 | skeleton | Warning |
| Symbol with 0 references | references | Info |
| High caller count (over 10) | callers | Info |
| eval, raw SQL, FFI, unsafe deserialize | unsafe_surface | Error/Warning |
| Hardcoded credential, `.cursorrules` backdoor, MCP-config RCE | scan | Error |

## References

- [review-patterns.md](references/review-patterns.md): review checklists and
  multi-file strategies.
- [error-recovery.md](references/error-recovery.md): LSP failures, file not found,
  ambiguous symbols.

## Output format

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
