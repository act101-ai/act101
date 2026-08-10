# plugin KNOWLEDGE BASE

## OVERVIEW

`plugin/` documents and packages the OpenCode/Claude-facing act integration: MCP tool contracts, commands, agents, skills, installation, and manifest metadata.

## STRUCTURE

```text
plugin/
├── .claude-plugin/
│   └── plugin.json    # package manifest (CI-owned; variants in .codex-plugin/, .cursor-plugin/)
├── README.md          # install and usage overview
├── TOOLS.md           # MCP tool contract, conventions, and discovery
├── agents/            # agent workflows
├── commands/          # slash command docs
└── skills/            # skill docs
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Tool contract | `TOOLS.md` | Discovery flow, toolsets, preview/LSP/file-creation conventions. |
| Explorer/review workflow | `agents/code-explorer.md`, `commands/explore.md`, `commands/review.md` | Parser-only first, LSP second where needed. |
| Refactor workflow | `commands/refactor.md` | Preview/apply/undo sequence. |
| Packaging | `.claude-plugin/plugin.json` (+ per-client variants), root plugin scripts | Keep metadata and generated packages in sync. |

## CONVENTIONS

- Preview before apply is the safe default for refactor tools.
- Parser-only queries are the first pass; LSP-backed queries require server readiness and may degrade gracefully.
- Tool docs must match actual MCP schema in `crates/act-cli/src/mcp/`.
- Agent/command docs should be operational and terse; avoid marketing copy here.

## ANTI-PATTERNS

- Do not document a plugin command/tool that is not backed by the current CLI/MCP implementation.
- Do not claim LSP is mandatory where act gracefully falls back to tree-sitter.
- Do not let plugin manifests drift from package/version scripts.
