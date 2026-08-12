# act MCP Tools — Contract & Conventions

The `act` MCP server advertises its tool surface dynamically, and the surface
grows with releases. This file therefore does not enumerate tools or copy
parameter signatures — hand-maintained lists go stale. It documents how to
discover the live surface and the conventions every tool shares.

## Discovering the surface

1. Call `status` first in any new workspace. It returns the tool groups, the
   per-language refactoring-operation index, detected languages with LSP
   readiness, and `toolsets_enabled`.
2. Every advertised tool carries its authoritative parameter contract in its
   protocol `inputSchema`, and (with one cosmetic exception) a `Params:` line
   in its description. Read those — never guess parameters from memory or
   from this file.
3. Chain tools rather than guessing — `symbols` → `definition` → `references`
   → `rename` is the common path. Each tool's description names what it pairs
   with.
4. An operation absent from discovery output is unavailable for that language —
   do not fall back to freehand edits.

## Tool groups

| Group | Purpose |
|-------|---------|
| Status | Always-on: `status` (discovery) and `enable_toolset` (widen the advertised list) |
| Exploration | Understand codebase structure without reading files |
| Navigation | Jump to definitions and find all usages |
| Understanding | Understand code logic without reading bodies |
| Refactoring | AST-aware code transformations, safer than manual edits |
| Verification | Check and auto-fix code issues |
| Architecture | Analyze structure, coupling, and dead code |
| Porting | Track and execute cross-language code porting projects |
| History | Undo/redo any refactoring operation |

Run `status` for the live tools in each group. (The always-on Status pair is
named above; `status` itself reports the other eight groups.)

## Toolsets (progressive disclosure)

- Default: Exploration, Navigation and Refactoring — 17 tools, ~4,000 tokens of
  definitions, against ~23,000 for the whole catalog. The long tail
  (Architecture, Verification, Understanding, Porting, History) is one
  `enable_toolset` call away, and that tool's description names every group.
- A deployment can pin the advertised groups up front:
  `act mcp serve --toolsets "Navigation,Architecture"` advertises only those
  groups (plus the always-on pair). `--toolsets all` advertises everything.
- A restricted session widens itself at runtime: call `enable_toolset` with
  `toolsets: ["<Group>", …]` (group names from `status`) — the server emits
  `tools/list_changed` so the client re-lists.
- `status` and `enable_toolset` are always advertised, so a restricted session
  can always bootstrap and widen itself.

## Cross-cutting conventions

- **Preview before apply:** every mutating tool can dry-run, but the flag
  differs. Most take `preview` (default `false`) — set `preview: true` to get
  the would-be changes without touching files. `insert_body` and `fix_auto`
  instead take `commit` (default `false`), so they preview by default and only
  write when you pass `commit: true`. Read the tool's `inputSchema`; never
  assume which flag applies.
- **LSP:** tools that need a language server say so in their descriptions;
  `status` reports per-language LSP readiness. Parser-only tools (`skeleton`,
  `symbols`, …) work immediately, and LSP-backed tools degrade gracefully to
  tree-sitter where possible — check each tool's own description rather than
  assuming.
- **Positions are 1-indexed:** lines and columns both start at 1.
- **File creation:** operations create destination files (and parent
  directories) automatically — never pre-create a file for `move_symbol`,
  `extract-class`, `extract-interface`, or any destination-creating operation.
- **Absolute paths** are accepted everywhere.
- **Batching:** dispatch independent operations (different symbols, different
  files) in parallel; sequence only where one depends on another's output.
- **History:** committing operations record undoable checkpoints — see
  `history_list`, `history_undo`, `history_redo`.
- **Client name prefixes:** tool names are canonical protocol names; MCP
  clients may render a prefix (Claude Code shows `skeleton`, Codex CLI shows
  `act.skeleton`).
