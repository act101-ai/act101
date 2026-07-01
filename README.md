# act101 — Analyze. Act. Attest.

> **An LLM editing your code is a guess. act101 turns it into a transform — with a receipt and one-command rollback.**

act101 is an AST-aware code transformer — a single native binary that performs precise
navigation, refactoring, and analysis across **163 languages and representational
grammars**, then **proves each change preserved behavior before it can merge**. It runs
surgical operations instead of rewriting whole files — roughly **85% fewer tokens on
average, up to 99% on reference queries**.

**Two first-class interfaces, one engine.** Run `act` directly from your terminal, or
start it as an MCP server inside **Claude Code**, **Cursor**, **Codex**, **Zed**, and
**opencode**. Every operation is available on both — neither is a wrapper or an
afterthought.

<p align="left">
  <a href="#install"><b>⬇️  Install free</b></a> &nbsp;·&nbsp;
  <a href="https://act101.ai/online"><b>🔍  Scan your repo free →</b></a> &nbsp;·&nbsp;
  <a href="https://act101.ai/pricing"><b>Pricing</b></a> &nbsp;·&nbsp;
  <a href="https://act101.ai"><b>act101.ai</b></a>
</p>

This repository is the **public distribution point** for act101: plugin files for the
[Claude Code](https://claude.ai/code), [Codex](https://developers.openai.com/codex),
and [Cursor](https://cursor.com) marketplaces, the Zed extension, and pre-built binaries
for every supported platform.

---

## Why act101

AI agents write plausible code fast — and plausible-but-wrong code just as fast. Reading
whole files to reason about a change burns tokens; find-and-replace edits silently break
callers. act101 replaces both with structure-aware operations and a verification gate:

- **Analyze** — map an unfamiliar codebase without reading it. `act query skeleton`
  returns a file's API (signatures, types, exports) at ~5–10× fewer tokens than the raw
  file; **33 analyzers** surface coupling, cycles, dead code, hotspots, test gaps, and
  porting readiness.
- **Act** — **182 refactoring operations** across **163 grammars**: rename, extract,
  inline, move, split, convert, generate — every reference updated across the repo, with
  a cheap `--preview` and one-command `act history undo`.
- **Attest** — before a change merges, `act gate` runs the tests that reach it, diffs
  the function contract and observable side effects, and emits a signed receipt. Pass →
  merge with rollback armed. Fail → blocked, with the exact check that failed.

```text
act gate · refactor verified   fn computeTotal()   src/cart.ts
──────────────────────────────────────────────────────────────
  behavioral diff (3 tests reaching change)      PRESERVED
  contract (signatures / declared effects)       PRESERVED
  side-effects (I/O, globals, hidden state)      CLEAN
──────────────────────────────────────────────────────────────
  VERDICT  ✓ MERGE      checkpoint + rollback ready
```

Equivalence is proven over the tests that reach the change — not a whole-program proof.
act101 tells you the coverage so you know exactly what was verified.

---

## 🔍 act101 online — scan any repo, free

Point act101 at a GitHub repository and get an architectural + AI-code security scan
with a health score — no install required.

- **Public repositories: free, forever.**
- **Private repositories: one free scan** — the full GitHub Marketplace app is coming soon.

**→ Start scanning at [act101.ai/online](https://act101.ai/online)**

---

## Install

Every install path produces a single, dependency-free native executable. The shell
installer is the recommended path — it downloads and verifies the binary and can wire up
the Claude Code plugin in one step.

### 1. Shell installer (Linux, macOS) — recommended

```bash
curl -sSL https://raw.githubusercontent.com/act101-ai/act101/main/install.sh | sh
```

The installer downloads the matching binary for your platform, verifies it against
`SHA256SUMS.txt`, places it on your `PATH`, and offers to register it with Claude Code.

Non-interactive flags (pass after `sh -s --`):

- `--install-claude-plugin=<yes|no|ask>` — control Claude Code plugin registration.
  Default is `ask` in interactive shells, `no` otherwise.
- `--prefix=<dir>` — install prefix (defaults to `/usr/local/bin` as root,
  `~/.local/bin` otherwise).
- `--version=v2.0.2` — pin a specific release.
- `--dry-run` — print what would happen without making any changes.
- `--debug` — verbose trace output (enables `set -x`).

Uninstall:

```bash
curl -sSL https://raw.githubusercontent.com/act101-ai/act101/main/install.sh | sh -s -- uninstall
```

### 2. PowerShell installer (Windows)

```powershell
irm https://raw.githubusercontent.com/act101-ai/act101/main/install.ps1 | iex
```

Non-interactive:

```powershell
iex "& { $(irm https://raw.githubusercontent.com/act101-ai/act101/main/install.ps1) } -InstallClaudePlugin yes"
```

### 3. Claude Code marketplace (if you already have `act` on `PATH`)

If the shell installer has already placed `act` on your `PATH`, or you built from
source, register the plugin directly with Claude Code:

```bash
claude plugin marketplace add act101-ai/act101
claude plugin install act101@act101-marketplace
```

The plugin starts `act mcp serve` using the `act` binary already on your `PATH`. Install
or update the binary with the shell installer, Homebrew, or a manual release download
before installing the plugin. Tool list and skills are described in `plugin/README.md`.

### 4. Codex marketplace (if you already have `act` on `PATH`)

```bash
codex plugin marketplace add act101-ai/act101
```

That registers the marketplace. To activate the act101 plugin, open Codex, run the
`/plugins` slash command, then select **act101** → **Install plugin**. (Codex 0.124.0
has no non-interactive install verb yet; the slash command is the install action.) The
Codex plugin starts `act mcp serve` using the `act` binary already on your `PATH`.

### 5. opencode (if you already have `act` on `PATH`)

Register act101 with [opencode](https://opencode.ai) in one command:

```bash
act install opencode
```

This writes the act101 MCP server entry into `~/.config/opencode/opencode.json`
(preserving any other `mcp.*` entries and JSONC comments) and deploys the act101 skill
set into `~/.config/opencode/skills/`. Existing skill directories are skipped; pass
`--force` to overwrite. Remove everything with `act uninstall opencode`, which walks the
install manifest and deletes only the files act wrote.

### 6. Cursor (if you already have `act` on `PATH`)

Register act101 with [Cursor](https://cursor.com) in one command:

```bash
act install cursor
```

This writes the act101 MCP server entry into `~/.cursor/mcp.json` (preserving any other
servers and JSONC comments). Restart Cursor to load it. Or one-click:

[![Add act101 to Cursor](https://img.shields.io/badge/Add%20to-Cursor-000000?logo=cursor)](cursor://anysphere.cursor-deeplink/mcp/install?name=act101&config=eyJjb21tYW5kIjoiYWN0IiwiYXJncyI6WyJtY3AiLCJzZXJ2ZSJdLCJlbnYiOnsiQUNUX0xPR19MRVZFTCI6Indhcm4ifX0=)

Remove with `act uninstall cursor`.

### 7. Zed (if you already have `act` on `PATH`)

Install `act` first (shell installer, Homebrew, or a manual release download). The Zed
extension starts `act mcp serve` using the `act` binary already on your `PATH`; it does
not download or cache its own binary.

### 8. Manual download

Grab the archive for your platform from the
[latest release](https://github.com/act101-ai/act101/releases/latest), verify against
`SHA256SUMS.txt`, extract, and place `act` (or `act.exe`) on your `PATH`.

```bash
# Linux x86_64 (static musl build)
curl -LO https://github.com/act101-ai/act101/releases/latest/download/act-x86_64-unknown-linux-musl.tar.gz
tar xzf act-x86_64-unknown-linux-musl.tar.gz
install -m 755 act ~/.local/bin/act
```

---

## Free forever, upgrade when you need to

**act101 is free for personal and open-source use — forever.** No license key, no
account, no expiration. The free **Builder** edition is a complete navigation and
token-efficiency toolkit: every query tool, all core languages, rename, fix-auto, and a
suite of analyzers — not a time-limited trial.

Paid editions unlock more refactors, deeper analysis, premium languages, and commercial
use:

| Edition | Adds |
|--------------|------|
| **Builder** (free) | All query tools, core languages, rename, fix-auto, core analyzers |
| **Engineering** | Advanced refactors + analysis for day-to-day teams |
| **Architecture** | Full analyzer suite: coupling, cycles, seams, migration readiness |
| **Elite** | Premium languages + the complete refactor and porting surface |
| **Enterprise** | Commercial use at scale — [talk to sales](https://act101.ai/pricing) |

See **[act101.ai/pricing](https://act101.ai/pricing)** for what each edition includes.
Operations gated above Builder are annotated in `--help` with their edition.

---

## Pay down tech debt this week — free

Start a **7-day trial** and every edition unlocks — all analyzers, all refactors, all
languages, no credit card. That's enough to run act101's **quality loop** end to end and
actually retire tech debt, not just measure it:

```bash
act trial start          # opens your browser to sign up, then activates automatically
```

Then run the loop — in your agent with act101's skills, or straight from the CLI:

1. **Audit** — `/architecture-audit` (or `act analyze` directly) maps the codebase and
   ranks circular dependencies, coupling hotspots, god modules, and dead code into a
   prioritized report.
2. **Refactor** — `/architectural-refactoring` (or `act refactor <op>`) executes the
   decompositions from that report: break cycles, split modules, extract seams — every
   reference updated across the repo.
3. **Attest** — `act gate` gives a MERGE / REVIEW / BLOCK verdict per changed function
   so nothing merges until behavior is preserved, and `act history undo` reverses
   anything you don't like.

Repeat until the audit comes back clean. It's the same **analyze → act → attest** loop,
pointed at your own worst files — free for the length of the trial.

---

## CLI

`act` is a single binary exposing code navigation, refactoring, analysis, verification,
and porting. Every command answers `--help`; paid operations name their edition in the
help text. Run `act docs` for the full generated reference, or browse
[/docs/](https://act101.ai/docs/).

| Command | What it does |
|---------|--------------|
| `act query` | Read code structure, references, diagnostics, types (19 query types) |
| `act inspect` | Discover available actions at a location |
| `act refactor` | Semantic code transformations (182 operations; e.g. `act refactor extract-variable`) |
| `act insert` | Add new code at AST-aware locations (`act insert body`) |
| `act fix` | Apply quick fixes from diagnostics |
| `act history` | Undo, redo, list checkpoints |
| `act analyze` | Structural analysis: patterns, coupling, cycles, dead-code, hotspots, … |
| `act gate` | Merge verdict over a diff: MERGE / REVIEW / BLOCK per changed function |
| `act scan` | AI-code security scan + health score |
| `act port` | Cross-language porting: contract, inventory, ordering, manifest |
| `act mcp` | Run the MCP server (stdio or HTTP/HTTPS) for agent integration |
| `act docs` | Emit language + tool documentation (markdown, html, or json) |
| `act license` | Activate, status, trial; `act update` / `act completions` also available |

Discover the surface programmatically:

```bash
act --list-commands      # every top-level command (JSON)
act --list-operations    # every refactor op + its tier + MCP tool name (JSON)
act catalog              # grammars + operations + per-op tier/CLI/MCP metadata (JSON)
act status               # detected languages, LSP readiness, available tools
```

---

## Tips & tricks

- **Prefer `act` over reading files.** `act query skeleton <file>` returns a file's API
  (signatures, types, exports) without bodies — usually 5–10× fewer tokens than the raw
  file.
- **Use `act query symbols` to navigate unfamiliar code.** Lists every symbol in a file
  with kind and location. Pair with `act query definition` and `act query references`
  for jump-to and find-usages, or start with `act query repo-outline` for the whole tree.
- **`act status`** prints detected languages, LSP readiness, and every available tool
  for the current workspace. Start here when something behaves unexpectedly.
- **`act query diagnostics`** returns LSP errors/warnings without running a build. Scope
  by passing a directory or file.
- **Refactor previews are cheap.** Every refactor accepts `--preview` (the default) —
  inspect the change set before it touches disk.
- **Undo is one call.** `act history undo` reverses the last refactor; `act history list`
  shows what's reversible.
- **LSP is optional.** Single-file refactors work without an LSP. Cross-file operations
  (rename-across-repo, `act refactor move`, find-references) benefit from one.
- **Set `ACT_LOG_LEVEL=debug`** when diagnosing plugin or MCP issues; logs go to stderr
  and don't interfere with MCP stdout.

---

## Supported platforms

| OS      | Architecture | Archive                                        |
|---------|--------------|------------------------------------------------|
| Linux   | x86_64       | `act-x86_64-unknown-linux-musl.tar.gz` (static) |
| Linux   | x86_64       | `act-x86_64-unknown-linux-gnu.tar.gz`           |
| Linux   | aarch64      | `act-aarch64-unknown-linux-gnu.tar.gz`          |
| macOS   | x86_64       | `act-x86_64-apple-darwin.tar.gz`                |
| macOS   | aarch64      | `act-aarch64-apple-darwin.tar.gz`               |
| Windows | x86_64       | `act-x86_64-pc-windows-msvc.zip`                |
| Windows | aarch64      | `act-aarch64-pc-windows-msvc.zip`               |

The Linux musl build is statically linked and has no libc version requirement — use it
if you see `GLIBC_X.YY not found` from the glibc build.

---

## Links

- **Scan your repo:** [act101.ai/online](https://act101.ai/online)
- **Pricing & editions:** [act101.ai/pricing](https://act101.ai/pricing)
- **Docs:** [act101.ai/docs](https://act101.ai/docs/)
- **Releases & binaries:** [github.com/act101-ai/act101/releases](https://github.com/act101-ai/act101/releases)
- **Release history:** [CHANGELOG.md](https://github.com/act101-ai/act101/blob/main/CHANGELOG.md)
- **Issues & feedback:** open an issue in this repo.
- **Homepage:** [act101.ai](https://act101.ai)
