# act101 Plugin

AST-aware code transformer for AI agents. Analysis, refactoring, and verification over MCP, across 160+ grammars.

## Features

- **Tool groups**: Exploration, Navigation, Understanding, Refactoring, Verification, Architecture, Porting, History — run the `status` tool for the live surface
- **Preview mode**: See changes before applying, with full undo/redo history
- **160+ grammars**: from TypeScript, Python, Rust, Go, and Java to representational formats like JSON, YAML, and Markdown

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

Marketplace plugins require `act` already on `PATH`. Install the binary
first with the shell installer, Homebrew, or a manual release download;
the binary owns update and license behavior.

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

### Zed

Install `act` first with the shell installer, Homebrew, or a manual
release download, then install the Zed extension. The extension starts
`act mcp serve` using the `act` binary already on your `PATH`.

## Skills

One entry per directory in `skills/`; each skill's own file carries its tier and full usage.

- `agent-safety-audit` — Audit whether an AI agent edit is safe: secret surface, taint flow, change impact, and API surface composed into a safety report
- `analysis-protocol` — Shared analysis-protocol reference used by the analysis skills (not directly invocable; no SKILL.md by design)
- `architectural-refactoring` — Execute structural decompositions from an architectural analysis report: break cycles, split god classes, reduce coupling
- `architecture-audit` — Comprehensive architectural overview: structure, health, patterns, prioritized findings
- `boundary-analysis` — Find extraction candidates and analyze module boundaries before decomposing a component
- `change-impact` — "What breaks if I change X?" — fast impact assessment before modifying a file or symbol
- `code-generation` — Batch-generate boilerplate (constructors, accessors, builders, equality, serialization) from existing types
- `code-navigation` — Traverse large repositories efficiently: explore unfamiliar code, map dependencies, understand API surfaces
- `code-review` — Review code for bugs, complexity, unused symbols, and structural issues using AST-aware analysis
- `create-work-loop` — Generate a resumable work-loop tracker that drives a large program through plan → implement → review cycles
- `dead-in-production` — Safely remove code: statically unreferenced ∩ never covered by tests ∩ never executed in production
- `health-check` — Trend-aware code-health snapshot: what's getting worse, periodic quality check
- `hot-path-refactor` — Rank refactor targets by runtime profile hotness × static complexity and coupling
- `migration-assessment` — Assess migration/port readiness: what makes this codebase hard to rewrite
- `onboarding-map` — Guided reading order for an unfamiliar codebase, annotated with ownership and risk
- `port-verify` — Gate a cross-language port for correctness: behavioral equivalence, contract parity, manifest drift
- `refactor-receipt` — Emit durable content-addressed receipts proving a refactor was verified
- `refactoring` — Semantic refactoring with preview and undo: rename, extract, inline, move
- `safe-to-merge` — Deterministic merge verdict (MERGE / REVIEW / BLOCK / UNKNOWN) over every changed function via `act gate`
- `security-surface` — AppSec surface report: dangerous constructs, secret-touching code, source→sink taint flows
- `verify-refactor` — Verify a refactor preserved behavior: contract, side-effect, and CFG-equivalence checks
- `where-bugs-live` — Find the riskiest code by combining churn, complexity, co-change coupling, and ownership

## Commands

- `/explore` — Explore code structure using query tools
- `/refactor` — Perform refactoring operations
- `/review` — Review code for issues

## Tool Reference

See [TOOLS.md](TOOLS.md) for the tool contract, conventions, and discovery flow.
