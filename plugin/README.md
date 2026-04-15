# act Plugin for Claude Code

AST-aware code transformer for AI agents. 17 MCP tools for code analysis and refactoring across 40 languages.

## Features

- **8 query tools**: status, skeleton, symbols, diagnostics, references, callers, definition, get_type
- **6 refactor tools**: rename, extract_function, extract_variable, inline, move_symbol, import_organize
- **3 history tools**: history_list, history_undo, history_redo
- **Preview mode**: See changes before applying
- **42 languages**: TypeScript, JavaScript, TSX, Python, Rust, Go, C, C++, CUDA, C#, F#, Java, Kotlin, Swift, Ruby, PHP, Haskell, Zig, Lua, SQL, Elixir, Dart, Bash, Objective-C, Scala, Groovy, Perl, Pascal, R, Erlang, VB.NET, Clojure, Julia, OCaml, PowerShell, Solidity, Common Lisp, COBOL, V, JSON, CSS, Svelte

## Installation

```
claude plugin marketplace add act101-ai/act101
claude plugin install act@act-marketplace
```

The plugin ships a small Node launcher that downloads the matching
`act` binary for your platform from
[GitHub Releases](https://github.com/act101-ai/act101/releases) on
first session start (cached under `${CLAUDE_PLUGIN_DATA}/bin`). Node 18+
on `PATH` is required.

Supported targets: x86_64 / aarch64 Linux (gnu), x86_64 / aarch64 macOS,
x86_64 / aarch64 Windows (MSVC).

## Skills

- **Code Review** — Analyze code for bugs, complexity, unused symbols, structural issues
- **Refactoring** — Semantic code transformations with preview and undo
- **Codebase Analysis** — Systematic quality audit with prioritized recommendations
- **Code Generation** — Batch generation of constructors, accessors, builders, serialization

## Commands

- `/explore` — Explore code structure using query tools
- `/refactor` — Perform refactoring operations
- `/review` — Review code for issues

## Tool Reference

See [TOOLS.md](TOOLS.md) for complete tool signatures and parameters.
