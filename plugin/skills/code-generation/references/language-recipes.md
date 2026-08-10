# Language Recipes — Generator Discovery & Cross-Language Patterns

Generator availability is language-specific and registry-derived. This file does
not enumerate per-language operation lists — a hand list rots. Discover the live
surface:

```bash
act --list-operations --language <lang>    # every op for <lang>, generators included
```

Generator entries carry `category: "generate"`; `languages` on each entry is the
authoritative support list.

## The universal generator workflow

1. The base type with fields must exist first — generators read field definitions
   from the AST.
2. `skeleton` / `symbols` the file and read the real field names; never guess.
3. Run all applicable generators for the type in one parallel batch (they are
   independent — they add code without modifying each other's output).
4. `import-organize` the file, then `generate-tests` last (it needs the full API).
5. `diagnostics` to validate the result.

The generator table and batch pattern live in the code-generation skill
(`../SKILL.md`) — every generator listed there is registry-verified.

## Prefer native mechanisms

When the language provides the boilerplate natively, prefer it over generation:

| Language | Native mechanism |
|----------|-----------------|
| Rust | `#[derive(Debug, Clone, PartialEq, Eq, Hash)]` (+ serde derives for JSON) |
| Python | `@dataclass` (init/repr/eq) |
| C# | `record` types (equality, ToString, deconstruction) |
| Kotlin | `data class` |
| Scala | `case class` |
| Java | `record` (Java 16+) |
| Go | no native equals/hash — generators earn their keep |
| TypeScript | structural typing removes most equals/hash needs; generate guards and mapped types instead |

Generate only what the native mechanism does not provide.

## Verifying language support

An operation that is not registered for a language fails with an honest error
naming the operation. To check before running:

```bash
act --list-operations --language <lang>
```

If an operation you expected is absent from that output, it is not implemented for
that language — pick the closest registered operation or fall back to a manual
edit; do not retry with spelling variants.
