# Error Recovery for Code Review

## LSP Not Ready

**Symptom:** `diagnostics`, `references`, `callers`, `definition`, `get_type` return LSP not ready error.

**Recovery:**
1. Check `status()` — look at `lsp_status` field
2. If `initializing`: wait 5-10 seconds, retry
3. If `failed` or `unavailable`: fall back to parser-only review
4. Parser-only tools (`skeleton`, `symbols`) always work

**Parser-only review covers:**
- Function size and complexity (skeleton)
- Symbol density and naming (symbols)
- Structural issues (nesting, parameter counts)

**Parser-only review misses:**
- Type errors, unused variables, missing imports (need diagnostics)
- Dead code detection (needs references)
- Coupling analysis (needs callers)

## File Not Found

**Symptom:** Tool returns "Failed to load file" error.

**Recovery:**
1. Check the file path — is it relative to workspace root?
2. Use `status()` to see the workspace root
3. Paths should be relative to workspace root, not absolute

## Symbol Not Found / Ambiguous Symbol

Shared op-level recovery — see the refactoring skill's
`references/error-recovery.md` (list symbols with `symbols(file=…)`, check
spelling/case, disambiguate with `file`/`line`/`column`, scope with `references`
first). Review-specific addition: some symbols are anonymous (arrow functions,
lambdas) — `references`/`callers` return nothing for them; use `skeleton` to find
and cite them by location instead.
