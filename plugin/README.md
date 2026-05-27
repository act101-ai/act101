# act Plugin for Claude Code

AST-aware code transformer for AI agents. 17 MCP tools for code analysis and refactoring across 40 languages.

## Features

- **8 query tools**: status, skeleton, symbols, diagnostics, references, callers, definition, get_type
- **6 refactor tools**: rename, extract_function, extract_variable, inline, move_symbol, import_organize
- **3 history tools**: history_list, history_undo, history_redo
- **Preview mode**: See changes before applying
- **42 languages**: TypeScript, JavaScript, TSX, Python, Rust, Go, C, C++, CUDA, C#, F#, Java, Kotlin, Swift, Ruby, PHP, Haskell, Zig, Lua, SQL, Elixir, Dart, Bash, Objective-C, Scala, Groovy, Perl, Pascal, R, Erlang, VB.NET, Clojure, Julia, OCaml, PowerShell, Solidity, Common Lisp, COBOL, V, JSON, CSS, Svelte

## Installation

### Claude Code

```
claude plugin marketplace add act101-ai/act101
claude plugin install act101@act101-marketplace
```

### Codex

```
codex plugin marketplace add act101-ai/act101
# Then in any Codex session:
#   /plugins   → select act101 → Install
```

The plugin ships a small Node launcher that downloads the matching
`act` binary for your platform from
[GitHub Releases](https://github.com/act101-ai/act101/releases) on
first session start (cached under `${CLAUDE_PLUGIN_DATA}/bin`). Node 18+
on `PATH` is required.

Supported targets: x86_64 / aarch64 Linux (gnu), x86_64 / aarch64 macOS,
x86_64 / aarch64 Windows (MSVC).

### Cursor

```
act install cursor
```

This writes the `act101` MCP server entry into `~/.cursor/mcp.json`
(preserving any other servers and JSONC comments). Restart Cursor to load it.

Or install from the Cursor marketplace once published, or one-click:

[![Add act101 to Cursor](https://img.shields.io/badge/Add%20to-Cursor-000000?logo=cursor)](cursor://anysphere.cursor-deeplink/mcp/install?name=act101&config=eyJjb21tYW5kIjoiYWN0IiwiYXJncyI6WyJtY3AiLCJzZXJ2ZSJdLCJlbnYiOnsiQUNUX0xPR19MRVZFTCI6Indhcm4ifX0=)

One-click install requires `act` already on your `PATH` (via the shell
installer or a manual download).

## Skills

- **Code Review** — Analyze code for bugs, complexity, unused symbols, structural issues
- **Refactoring** — Semantic code transformations with preview and undo
- **Codebase Analysis** — Systematic quality audit with prioritized recommendations
- **Code Generation** — Batch generation of constructors, accessors, builders, serialization
- **Security Surface** — AppSec report: dangerous constructs, secret-touching code, and source→sink taint flows (Teams)
- **Verify Refactor** — Confirm a refactor preserved behavior: contract, side-effect, and CFG-equivalence checks across two versions of a function (Pro)
- **Where Bugs Live** — Compose churn_hotspots × analyze_hotspots × co_change_clusters × ownership_map into a ranked, explained defect-risk list (Teams)
- **Onboarding Map** — Compose repo_outline + analyze_entry_points + churn_hotspots + ownership_map into a guided reading order with risk flags (Teams)
- **Dead in Production** — Compose analyze_dead_code ∩ coverage_overlay ∩ trace_overlay into a ranked safe-to-delete list (Teams)
- **Hot Path Refactor** — Compose profile_overlay + analyze_hotspots + analyze_coupling into a ranked refactor-priority list (hot × hard intersections first; Teams)
- **Safe to Merge** — Compose verify_diff_semantics + verify_test_impact + verify_side_effects into a merge / review / block verdict (Pro)
- **Refactor Receipt** — Compose verify_diff_semantics + verify_side_effects + verify_test_impact + verify_contract_preserved into an audit artifact proving a refactor preserved behavior (Pro)
- **Agent Safety Audit** — Compose secret_surface + taint_flow + analyze_impact + analyze_surface into an agent-edit safety report (Teams)
- **Architecture Audit Plus** — The architecture audit enriched with coverage_overlay + churn_hotspots + co_change_clusters + ownership_map — runtime and git evidence on top of structure (Teams)
- **Port Verify** — Compose verify_behavioral_equivalence (scope=port) + verify_port_parity + port_inventory drift into a port-correctness gate (Enterprise)
- **Migration Readiness Plus** — The migration assessment enriched with taint_flow + secret_surface + unsafe_surface + coverage_overlay + churn_hotspots + ownership_map (Enterprise)

## Commands

- `/explore` — Explore code structure using query tools
- `/refactor` — Perform refactoring operations
- `/review` — Review code for issues

## Tool Reference

See [TOOLS.md](TOOLS.md) for complete tool signatures and parameters.
