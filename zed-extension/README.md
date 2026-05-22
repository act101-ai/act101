# act101 — Zed extension

Registers [act101](https://act101.ai) as an MCP context server in Zed. act101
gives Zed's Agent AST-aware code analysis and refactoring across 100+ languages
(refactor, query, analyze) with undo/redo, preview mode, and guardrails.

## Install

Install **act101** from Zed's Extensions view (`zed: extensions`). On first use
the extension downloads the `act` binary for your platform from the
[act101 releases](https://github.com/act101-ai/act101/releases) and launches
`act mcp serve`. No separate install step is required.

> If you instead manage act yourself with the CLI, run `act install zed` — that
> writes the same `context_servers.act101` entry into your `settings.json`. Use
> **one** path or the other, not both.

## Licensing

This extension (the glue that downloads and launches act) is MIT-licensed. The
`act` binary it downloads is a separate, commercially-licensed product — see
<https://act101.ai>.
