# act101 — Zed extension

Registers [act101](https://act101.ai) as an MCP context server in Zed. act101
gives Zed's Agent AST-aware code analysis and refactoring across 100+ languages
(refactor, query, analyze) with undo/redo, preview mode, and guardrails.

## Install

Install or update the `act` binary first, then install **act101** from Zed's
Extensions view (`zed: extensions`). The extension launches `act mcp serve`
using the `act` binary already on your `PATH`; it does not download or cache
its own binary.

> If you instead manage act yourself with the CLI, run `act install zed` — that
> writes the same `context_servers.act101` entry into your `settings.json`. Use
> **one** path or the other, not both.

## Licensing

This extension (the glue that launches act) is MIT-licensed. The `act` binary
it starts is a separate, commercially-licensed product — see
<https://act101.ai>.
