---
name: code-generation
description: Use when creating constructors, getters/setters, builders, equals/hash methods, JSON serialization, toString, interface implementations, test stubs, or any boilerplate derived from an existing class or struct. AST-aware generators, batchable.
---

# Code Generation with act

Generate boilerplate from existing type definitions. Generators run on the CLI;
discovery and validation use the MCP tools. The refactoring and
architectural-refactoring skills delegate boilerplate here.

## Rules

1. **Classify first.** Data types (DTOs, models, value objects) go to generators;
   business logic is written by hand; interface stubs go to `generate-impl`. A
   generator produces correct, language-idiomatic code without spending tokens.
2. **Read the type before generating.** `skeleton` and `symbols` give the target's
   fields; generators work from fields that already exist.
3. **Order: type, then generators, then logic.** For porting: scaffold the type,
   batch-generate, then translate logic.
4. **Preview before applying**: `act refactor --preview <generator> …`, without
   exception on a language you have not verified a generator on.
5. **Validate** the batch with one `diagnostics` call over the touched files, then
   `import-organize` the file.
6. **Prefer the language's native mechanism** when it exists: Rust derive macros,
   Python dataclasses, C# records. Generators are for languages that need explicit
   boilerplate.
7. **Generate tests last.** `generate-tests` needs the finished API to produce
   useful stubs.

## Generators

| Generator | Creates | Target argument |
|-----------|---------|-----------------|
| `generate-constructor` | Constructor from fields | Class or struct name (`--fields` to select) |
| `generate-impl` | Interface or trait implementation stubs | Class name, interface name |
| `generate-accessors` | Getters and setters | Class name (`--fields`, `--accessor-type`) |
| `generate-builder` | Builder pattern | Class or struct name |
| `generate-equals` | Equality method | Class or struct name |
| `generate-hash` | Hash method | Class or struct name |
| `generate-to-string` | String representation | Class or struct name |
| `generate-from-json` | JSON deserialization | Class or struct name |
| `generate-to-json` | JSON serialization | Class or struct name |
| `generate-tests` | Test stubs | Class or function name |
| `generate-mapped-type` | Mapped type utilities (TypeScript) | Type name |
| `generate-type-guard` | Type guard function (TypeScript) | Type name |
| `generate_docstring` | Documentation comment | Symbol name (registry-only, see below) |
| `generate_init` | `__init__` method (Python) | Class name (registry-only) |
| `generate_repr` | `__repr__` method (Python) | Class name (registry-only) |

Subcommand generators take the target symbol name and locate it in the workspace;
they have no `--file` flag:

```bash
act refactor generate-constructor User
act refactor generate-accessors User --fields name,email,age
```

Registry-only generators (`generate_docstring`, `generate_init`, `generate_repr`)
have no subcommand and run through `refactor-lang`:

```bash
act refactor-lang generate_docstring --file src/models/user.py --params '{"target": "User"}'
```

Availability is per language and registry-derived:
`act --list-operations --language <lang>` lists the generators for that language,
and a generator absent from that output is unavailable for it.

## Batch generation

Generators that target the same type are independent. Issue them as one parallel
batch of tool calls; the batch finishes in the time of the slowest generator.

```bash
# Independent: run as one batch
act refactor generate-constructor User
act refactor generate-accessors User --fields name,email,age
act refactor generate-equals User
act refactor generate-hash User
act refactor generate-to-string User
act refactor generate-to-json User
act refactor generate-from-json User
act refactor generate-builder User
```

Then, in order:

```bash
act refactor import-organize src/models/user.ts
act refactor generate-tests User
```

## Recipes

**New service class**: write the class with method signatures; batch `generate-impl
ServiceClass IServiceInterface` and `generate-constructor ServiceClass`; then
`generate-tests ServiceClass`; then `import-organize`.

**New DTO**: write the class with fields only; batch `generate-constructor`,
`generate-accessors`, `generate-equals`, `generate-hash`, `generate-to-json`,
`generate-from-json`, `generate-to-string`; add `generate-builder` when the DTO has
many fields; then `generate-tests`.

**New API response type**: write the type with fields; batch `generate-from-json`,
`generate-to-json`, `generate-equals`; then `generate-tests`.

**Post-scaffold boilerplate when porting**: write the target-language type with its
fields; classify each symbol (data type to generators, business logic to
translation); batch every applicable generator; validate with `diagnostics`; then
translate the logic.

## When other skills call this skill

- **Porting**: after scaffolding a target file, data types are batch-generated here
  and business logic is translated.
- **architectural-refactoring**: after extracting interfaces at seams,
  `generate-impl` produces the implementation stubs.
- **refactoring**: after `extract-class` creates a new type, generators add its
  boilerplate.

## Language-specific recipes

[language-recipes.md](references/language-recipes.md) covers generator discovery per
language and the native-mechanism preference table.
