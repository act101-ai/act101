---
name: code-review
description: >
  Review code for bugs, complexity, unused symbols, and structural issues using
  AST-aware analysis. Use when reviewing PRs, checking code quality, finding dead
  code, analyzing function complexity, auditing a codebase, or checking for type
  errors. Each call reports the kinds it modeled in `modeled_kinds` — that is the
  honest coverage signal; the supported-language list is whatever act ships.
---

# Code Review with act

Analyze code for issues using act's query tools.

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

**unsafe_surface** — Flag dangerous constructs: unsafe blocks, `eval`, raw SQL, FFI, reflective invocation, unsafe deserialization. Syntactic floor (works without LSP), upgrades confidence when LSP is warm. Run it on any file handling input, queries, or native interop.
```
unsafe_surface(file="src/db/query.ts")
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
4. `callers` on modified functions — assess impact (requires LSP)
5. `analyze_impact` (symbol mode, Architecture) on modified functions — transitive callers without LSP.
   Use `skeleton` first to confirm the symbol name, then: `analyze_impact(target=<file>, symbol=<name>)`.
   Review `confidence`, `modeled_kinds`, and `unresolved` fields for analysis gaps.
6. `analyze_api_diff` (Architecture) on changed PUBLIC surfaces — run it against the PR
   base branch: `analyze_api_diff(base_ref=<base>)` (CLI twin `act analyze api-diff --base-ref <base>`;
   omit `base_ref` to diff against HEAD). It diffs the merge-base of the base branch and the working
   tree, returning per-symbol `rows` and `summary` counts. Cite the verdicts — **Breaking** (e.g. a
   parameter added), **PossiblyBreaking** (other signature drift), **Additive** (a new export) — and
   report the `summary` breaking/possibly_breaking/additive counts. Surface any **Unjudgeable** rows:
   they name a grammar whose visibility act doesn't model, so the change is unjudged, NOT safe. Skip
   this step when the PR touches no public API.
7. `scan` — AI-code security pass on the change: hardcoded credentials
   (pattern + entropy heuristic), `.cursorrules` backdoors, MCP-config RCE,
   typosquat/hallucinated dependencies, GitHub Actions expression injection,
   LLM-output-to-exec flows, prompt-injection surfaces, plus an AI-Code
   Health Score.
   Prefer `scan(root=<repo>, base_ref=<base branch>)` — it computes the
   changed set itself (merge-base, rename-aware) and the report's `scope`
   section discloses the diff scoping; scores are diff-scoped, never
   comparable to full-repo scores. Fall back to
   `scan(root=<repo>, files=[<changed files>])` when there is no git base
   to diff against — path-scoped scans are cheap (the architecture graph
   builds over the selected files only) and equally disclosed via the
   `scope` section (`mode: "paths"`); their scores carry the same
   never-comparable rule. With a committed `.act/baseline.json`, add
   `baseline=".act/baseline.json"` — `baseline.new_finding_ids` is then
   exactly "findings this change introduces".
8. **Merge-safety verdict** — run `gate(base_ref=<base branch>)` (MCP) or
   `act gate --base-ref <base branch>` (CLI) to get a deterministic per-function
   verdict for the entire changed set. Cite its output directly; do not re-derive
   merge-safety prose from `verify_diff_semantics`, `verify_test_impact`, or
   `verify_side_effects` individually — those are the gate engine's inputs, and
   the gate is the rule owner. The safe-to-merge skill follows the same verdict
   rules and extends the gate workflow with post-merge validation.

   Verdict semantics (exit codes: 0 MERGE, 1 BLOCK, 2 REVIEW, 3 UNKNOWN, 4 error):
   - `MERGE` — every changed function cleared all three checks
   - `REVIEW` — at least one function needs human judgment (no automatic block)
   - `BLOCK` — at least one function failed a check; do not merge
   - `UNKNOWN` — verification could not complete for at least one function;
     treat as **not-verified**, never as a pass

   **Receipts:** `gate --receipts` (or `gate(receipts=true)`) writes one
   `<id>.json` file to `.act/receipts/` per verified function. Functions whose
   file, symbol, and span-hashes match a valid receipt are reported as
   `pre-verified by receipt <id>` — reviewers may accept that as evidence without
   re-running the trio. Any hash or schema mismatch discards the receipt and
   re-verifies from scratch automatically. Emission mechanics and receipt schema
   live in the refactor-receipt skill.

   **Worked example** (fixture: `auth.ts` with two working-tree changes):

   ```
   $ act gate --receipts
   act gate — working tree vs HEAD (2 changed function(s))
     MERGE   auth.ts::formatLabel — format (format-only)
     MERGE   auth.ts::validateAge — format (format-only)
   verdict: MERGE
   $ echo $?
   0
   ```

   Second run (receipts already written, consumed from cache):

   ```
   $ act gate --receipts
   act gate — working tree vs HEAD (2 changed function(s))
     MERGE   auth.ts::formatLabel — format (pre-verified by receipt 60e278c850577270)
     MERGE   auth.ts::validateAge — format (pre-verified by receipt 8bb683bbfe8e27cf)
   verdict: MERGE
   $ echo $?
   0
   ```

   A behavior change without test reach blocks (same fixture, `age >= 18`
   flipped to `age > 18`):

   ```
   $ act gate
   act gate — working tree vs HEAD (1 changed function(s))
     BLOCK   auth.ts::validateAge — behavior, NO test reaches it (behavior change with no test reaching it)
   verdict: BLOCK
   $ echo $?
   1
   ```

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
| eval / raw SQL / FFI / unsafe deserialize | unsafe_surface | Error/Warning |
| Hardcoded credential / `.cursorrules` backdoor / MCP-config RCE | scan | Error |

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
