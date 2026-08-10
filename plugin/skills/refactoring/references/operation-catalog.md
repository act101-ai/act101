# act Refactor Operation Catalog — Discovery Guide

The operation surface is registry-derived and language-specific: 100+ language
dispatch modules register thousands of operation entries, and the set grows with
every release. A hand-maintained list cannot stay truthful, so this file does not
enumerate operations. Discover the live surface instead.

## Discovering operations

CLI (registry-derived, always current):

```bash
act --list-operations                      # every operation, with `languages` per op
act --list-operations --language <lang>    # the surface for one language
```

Each JSON entry carries `name`, `category`, `description`, `complexity`, `tier`,
`mcp_tool` (set when an MCP tool wraps the operation), and `languages`
(`["*"]` = core operation, applies to every grammar act parses).

MCP: call `status()` first — it returns the refactoring operations grouped by
category with per-language counts; widen the advertised tool list per group with
`enable_toolset`.

Run an operation:

```bash
act refactor <operation> [args] --file <path>                 # language inferred from extension
act refactor-lang <operation> --file <path> --params '<json>' # explicit-params form
```

## MCP Refactoring tools

The MCP catalog's Refactoring group wraps these directly:

| MCP tool | CLI twin | Description |
|----------|----------|-------------|
| `rename` | `act refactor rename` | Rename symbol + all references |
| `extract_function` | `act refactor extract-function` | Extract code range to new function |
| `extract_variable` | `act refactor extract-variable` | Extract expression to variable |
| `inline` | `act refactor inline` | Inline variable/function at usage sites |
| `move_symbol` | `act refactor move` | Move symbol to another file |
| `insert_body` | `act insert` | Insert or replace a function body |
| `recipe_run` | — | Run a multi-site refactor recipe (Enterprise) |

`import_organize` (CLI: `act refactor import-organize <file>`) organizes imports and
lives in the MCP catalog's Verification group.

## Operation categories

The registry groups operations into categories — core (`rename`, `move`, `inline`,
`delete`, `split`, `combine`, … — `languages: ["*"]`, every supported grammar),
extract, generate, convert, modernize, introduce, wrap, import, change, structural,
and per-language categories. Read the live per-language contents from
`--list-operations`; never assume an operation exists for a language without
checking.

## Notes

- Destination-creating operations (e.g. `extract-class`, `extract-interface`,
  `move`) create files automatically — never pre-create a file for them.
- An operation not registered for a language fails with an honest error; treat the
  discovery output as the single source of truth.
- Boilerplate generators (constructors, accessors, equals/hash, JSON, builders,
  tests) are documented in the code-generation skill.
