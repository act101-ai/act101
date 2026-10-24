---
name: code-generation
description: Generates boilerplate (constructors, accessors, builders, equals and hash methods, JSON serialization, toString, interface stubs, test stubs) from a type's existing fields, previewed and reversible. Use when creating any of that boilerplate from an existing class or struct, or when porting a type and its boilerplate to another language. Business logic is written by hand.
---

# Code Generation

## Procedure

1. **Classify.** Data types (DTOs, models, value objects) get generated
   boilerplate; business logic is written by hand; an interface
   implementation gets generated stubs.
2. **Read the type first.** Boilerplate is generated from fields that
   already exist; never guess a field name. Make the type's name unique in
   the workspace before generating from it, so the generation lands on the
   intended type.
3. **Prefer the language's native mechanism**, and generate only what it does
   not provide:

   | Language | Native mechanism |
   |---|---|
   | Rust | `#[derive(Debug, Clone, PartialEq, Eq, Hash)]` (+ serde derives for JSON) |
   | Python | `@dataclass` (init/repr/eq) |
   | C# | `record` types (equality, ToString, deconstruction) |
   | Kotlin | `data class` |
   | Scala | `case class` |
   | Java | `record` (Java 16+) |
   | Go | no native equals/hash — generation earns its keep |
   | TypeScript | structural typing removes most equals/hash needs; generate guards and mapped types instead |

4. **Preview before applying** on a language where you have not yet seen the
   generated output.
5. **Generate, then finish.** Generate the boilerplate (below), then organize
   the file's imports, then generate tests last — they need the finished API
   — then confirm the touched files compile and type-check.

### Batch generation

Generations that target the same type run one at a time, in this order.
Concurrent runs each read the file and write their own version, so one change
is silently lost:

1. constructor
2. accessors
3. equals
4. hash
5. toString
6. to-JSON
7. from-JSON
8. builder
9. organize imports
10. tests

### Recipes

- **New service class:** write the class with method signatures; generate
  the interface stubs and the constructor; then the tests.
- **New DTO:** write the class with its fields; run the batch above; add a
  builder when the DTO has many fields; then the tests.
- **Porting:** scaffold the target-language type with its fields; generate
  its data-type boilerplate and translate the business logic by hand; confirm
  it compiles.

## Report

Each file changed, what was generated in it, and how to revert it. A
generation that was refused is reported with the refusal, never worked
around by hand-writing the same code silently.
