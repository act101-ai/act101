# Review Patterns

## PR Review Checklist

### 1. Type Safety
- Run `diagnostics` on every changed file
- For new function signatures, use `get_type` on return expressions to verify return types
- For renamed symbols, use `references` to confirm all usages updated

### 2. Dead Code Detection
- For every exported symbol in changed files, run `references`
- 0 external references on a public symbol = likely dead code
- Exception: entry points (main, handlers, exports consumed by external packages)

### 3. Coupling Analysis
- For modified public functions, run `callers` to assess blast radius
- >10 callers = high coupling, changes here are risky
- 0 callers on a public function = dead code candidate

### 4. Structural Quality
- Run `skeleton` on files >200 lines
- Flag functions >50 lines, >5 parameters, >4 nesting levels
- Flag classes >10 methods (god class)
- Flag files >500 lines (should be split)

### 5. Import Health
- Run `diagnostics` — most LSPs flag unused imports
- Check for circular dependencies by tracing `definition` on imports

## Multi-File Analysis Strategy

When reviewing a directory with many files:

1. **Triage**: Run `skeleton` on all files. Sort by size/complexity.
2. **Deep dive**: Run full review (diagnostics + references + callers) on the top 5 most complex files.
3. **Spot check**: Run `diagnostics` only on remaining files.

This prevents token exhaustion on large directories while catching the most impactful issues.

## Severity Classification

| Severity | Criteria | Action |
|----------|----------|--------|
| Error | Won't compile, type mismatch, missing import | Must fix |
| Warning | Code smell, complexity, unused code | Should fix |
| Info | Style issue, coupling observation, naming | Nice to fix |
