---
name: code-generation
description: >
  Generate boilerplate code from existing types using AST-aware code generation.
  Use when creating constructors, getters/setters, builders, equals/hash methods,
  JSON serialization, toString, interface implementations, test stubs, or any
  repetitive code derived from existing class/struct definitions. Supports batch
  generation for maximum efficiency.
---

# Code Generation with act

Generate boilerplate from existing type definitions. All generation operations are CLI-based — invoke via shell commands. This skill is the authoritative reference for code generation patterns. The refactoring and architectural-refactoring skills delegate here for boilerplate generation.

## Rules

1. **Classify before acting.** Before writing boilerplate by hand, determine if a generator can produce it. Data types (DTOs, models, value objects) → generators. Business logic → manual/LLM. Interface stubs → `generate-impl`. If a generator exists for the task, use it — it produces correct, language-appropriate code without consuming LLM tokens.

2. **Discover structure first.** Before generating, use `skeleton` and `symbols` to understand the target type's fields and structure. Don't guess field names — read them from the AST. The generator needs an existing type with fields defined to work from.

3. **Batch independent generators.** All generators targeting the same type are independent — run them in parallel. A batch of 8 generators completes in wall-clock time of the slowest single operation instead of 8 sequential calls with round-trip overhead.

4. **Order: type → generate → logic.** The base type with fields must exist first (generators need field definitions to work from). Run generators after the type exists. Write business logic last. For porting workflows: scaffold → batch generate → translate logic.

5. **Preview before commit.** Always preview generated code before applying, especially when running generators for the first time on a language you haven't verified.

6. **Validate after generation.** Run `diagnostics` after committing a generation batch to catch any issues. Follow with `import_organize` to clean up any new imports.

7. **Don't generate what the language provides natively.** Rust has derive macros (`#[derive(PartialEq, Hash, Debug)]`). Python has dataclasses. C# has records. When the language has a native mechanism that provides the same functionality, prefer it. The generator is for languages that require explicit boilerplate.

8. **Generate tests last.** `generate-tests` should run after all other boilerplate is in place — it needs to see the full API to produce useful stubs.

## Available Generators

| Generator | What it Creates | Input |
|-----------|----------------|-------|
| `generate-constructor` | Constructor from fields | Class/struct name |
| `generate-impl` | Interface/trait implementation stubs | Class + interface name |
| `generate-accessors` | Getters and setters | Class + field names |
| `generate-builder` | Builder pattern | Class/struct name |
| `generate-equals` | Equality comparison method | Class/struct name |
| `generate-hash` | Hash code method | Class/struct name |
| `generate-to-string` | String representation | Class/struct name |
| `generate-from-json` | JSON deserialization | Class/struct name |
| `generate-to-json` | JSON serialization | Class/struct name |
| `generate-tests` | Test stubs for methods | Class/function name |
| `generate-docstring` | Documentation comments | Symbol name |
| `generate-init` | `__init__` method (Python) | Class name |
| `generate-repr` | `__repr__` method (Python) | Class name |
| `generate-mapped-type` | Mapped type utilities (TypeScript) | Type name |
| `generate-type-guard` | Type guard function (TypeScript) | Type name |
| `generate-operator-overloads` | Operator overloads (C++, C#, Python) | Class name |
| `generate-rule-of-five` | Rule-of-five methods (C++) | Class name |

Most generators run as `act refactor <generator> …`. Five are registry-only operations
with no dedicated subcommand — `generate-docstring`, `generate-init`, `generate-repr`,
`generate-operator-overloads`, `generate-rule-of-five` — invoke them via
`act refactor-lang <generator> --file <path> --params '<json>'`.

## Batch Generation Pattern

When creating a new data model with full boilerplate, **invoke generators in parallel** for maximum speed. Each generator is independent — they can all run concurrently.

### Example: Full data model boilerplate

Given a class file with fields already defined:

```bash
# These are independent — run in parallel (all at once)
act refactor generate-constructor User --file src/models/user.ts
act refactor generate-accessors User --file src/models/user.ts --fields name,email,age
act refactor generate-equals User --file src/models/user.ts
act refactor generate-hash User --file src/models/user.ts
act refactor generate-to-string User --file src/models/user.ts
act refactor generate-to-json User --file src/models/user.ts
act refactor generate-from-json User --file src/models/user.ts
act refactor generate-builder User --file src/models/user.ts
```

Then sequentially:
```bash
# After all generators complete, organize imports
act refactor import-organize --file src/models/user.ts
# Generate test stubs last (depends on generated methods)
act refactor generate-tests User --file src/models/user.ts
```

### Why batch?

Each `act` invocation is fast, but each MCP/shell tool call has round-trip overhead. Running independent generators in parallel completes in the wall-clock time of the slowest single operation instead of the sum of all of them.

**For agents:** When you need to generate multiple boilerplate methods for a class, invoke all independent generators in a single batch of parallel tool calls.

## Common Recipes

### New Service Class

1. Write the minimal class with method signatures (the base type must exist for generators to target)
2. Batch in parallel: `generate-impl ServiceClass IServiceInterface`, `generate-constructor ServiceClass`
3. `generate-tests ServiceClass` — create test stubs
4. `import-organize` on the file

### New DTO / Data Transfer Object

1. Write the class with fields only (generators need the field definitions to work from)
2. Batch in parallel: `generate-constructor`, `generate-accessors`, `generate-equals`, `generate-hash`, `generate-to-json`, `generate-from-json`, `generate-to-string`
3. `generate-builder` if the DTO has many fields
4. `generate-tests`

### New API Response Type

1. Write the type with fields (generators need the field definitions)
2. Batch in parallel: `generate-from-json`, `generate-to-json`, `generate-equals`
3. `generate-tests`

### Post-Scaffold Boilerplate (Porting Integration)

When porting data types from another language:

1. Write the target-language type with its fields (generators need the field definitions to work from)
2. Classify: data type → generators, business logic → LLM translation
3. Batch in parallel: all applicable generators for the data type
4. Validate with `diagnostics`
5. Move on to business logic translation

This step produces 80–150 lines of correct, language-appropriate code per data type without consuming any LLM tokens.

## When Other Skills Call This Skill

- **Porting workflows:** after scaffolding a target file, classify each symbol — data types get batch-generated here, business logic gets LLM-translated.
- **architectural-refactoring:** after extracting interfaces at seams, use `generate-impl` for implementation stubs.
- **refactoring:** after `extract-class` creates a new type, use generators to add boilerplate.

## Language-Specific Recipes

See [language-recipes.md](references/language-recipes.md) for generator discovery and the native-mechanism preference table.

> **Note:** Language support is registry-derived — run `act --list-operations --language <lang>` to see which generators are available. A generator absent from that output is not supported for the language.
