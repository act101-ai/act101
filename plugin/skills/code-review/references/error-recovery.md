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

## Symbol Not Found

**Symptom:** `references` or `callers` returns empty results for a symbol you know exists.

**Recovery:**
1. Use `symbols(file="path")` to list all symbols in the file
2. Check exact spelling and case
3. Some symbols are anonymous (arrow functions, lambdas) — use `skeleton` to find them
4. If the symbol is in a different file, provide the `file` parameter to scope the search

## Ambiguous Symbol

**Symptom:** Multiple results when you expected one specific symbol.

**Recovery:**
1. Provide the `file` parameter to narrow scope
2. For `definition`, provide exact `line` and `column` position
3. Use `skeleton` to find the exact location first, then use precise coordinates
