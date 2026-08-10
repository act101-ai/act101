# Compound Refactoring Sequences

Complex refactors combine multiple operations. The key efficiency rule: **batch independent operations in parallel, sequence dependent ones.**

## Dependency Rules

- **Dependent:** Operation B uses the output of A (e.g., extract → rename the extracted symbol). Must be sequential.
- **Independent:** Operations touch different symbols or files (e.g., move 5 functions to 5 files). Run in parallel.

## Extract-Rename-Move (Sequential — each step depends on previous)

**Goal:** Pull a function out of a large file, give it a better name, move it to a dedicated module.

1. `extract_function` — extract the code range
2. `rename` — give the new function a meaningful name (depends on step 1)
3. `move_symbol` — move to dedicated file (depends on step 2)
4. `import_organize` — clean up imports in both source and destination
5. `diagnostics` — verify final state

## Decompose God Class (Parallel moves — independent targets)

**Goal:** Break a large class into smaller, focused classes.

1. `skeleton` + `symbols` — understand current structure, identify groups of related methods
2. **Batch in parallel:** `move_symbol` for each independent method/group to its new file — these don't depend on each other
3. `diagnostics` — verify all moves succeeded
4. **Batch in parallel:** `import_organize` on all affected files

## Flatten Deep Nesting (Mixed — extracts are independent if from different functions)

**Goal:** Reduce nesting depth in complex functions.

1. `skeleton` — identify deeply nested functions
2. **If extracting from different functions:** batch `extract_function` calls in parallel
   **If extracting from the same function:** sequence them (earlier extracts change line numbers)
3. Batch `rename` calls in parallel (each renames a different extracted function)
4. `diagnostics` — verify

## Convert Module to Modern Syntax (Parallel — each file is independent)

**Batch per file in parallel** (different files don't interact):

```bash
# All of these target different files — run in parallel
act refactor convert-require-to-import --file src/auth.ts
act refactor convert-require-to-import --file src/billing.ts
act refactor convert-require-to-import --file src/users.ts
```

Then batch the follow-up transforms in parallel:
```bash
act refactor import-organize --file src/auth.ts
act refactor import-organize --file src/billing.ts
act refactor import-organize --file src/users.ts
```

## Batch Generation for Data Models

Boilerplate generation (constructors, accessors, equals/hash, JSON, builders,
tests) is the code-generation skill's ground — see its Batch Generation Pattern.
Generators targeting the same file are independent: run them in parallel, then
`import-organize`, then `generate-tests` last.
