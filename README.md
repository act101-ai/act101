# act101

**AST-aware code transformer for AI coding agents.** 179 code navigation,
refactoring, and analysis operations across 159 languages and representational
grammars — ~85% fewer tokens than file-based operations (benchmark average).

This repository is the **public distribution point** for `act101`: plugin
files for the [Claude Code](https://claude.ai/code) and
[Codex](https://developers.openai.com/codex) marketplaces and pre-built
binaries for every supported platform.

---

## What's new

### v1.0.11
- Fixed: Codex marketplace invoking act101 MCP server as http
- Added: streaming traces for analysis tools to improve agent feedback

### v1.0.10
- Added: exponential back-off for version update
- Added: install support for opencode
- Added: marketplace support for Codex
- Added: GDShader query tools

Full release history in [CHANGELOG.md](https://github.com/act101-ai/act101/blob/main/CHANGELOG.md).

---

## Install

All install paths produce a single dependency-free native executable. 
The recommended path is the shell installer — it handles binary download, 
Terms of Service, and optionally wires the Claude Code plugin in one step.

### 1. Shell installer (Linux, macOS) — recommended

```bash
curl -sSL https://raw.githubusercontent.com/act101-ai/act101/main/install.sh | sh
```

The installer downloads the matching binary for your platform, verifies
it against `SHA256SUMS.txt`, places it on your `PATH`, walks the
Terms of Service, and offers to register it with Claude Code.

Non-interactive flags (pass after `sh -s --`):

- `--accept-terms-of-service=yes` — accept TOS non-interactively.
- `--install-claude-plugin=<yes|no|ask>` — control Claude Code plugin
  registration. Default is `ask` in interactive shells, `no` otherwise.
- `--prefix=<dir>` — install prefix (defaults to `/usr/local/bin` as
  root, `~/.local/bin` otherwise).
- `--version=v0.7.19` — pin a specific release.
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
iex "& { $(irm https://raw.githubusercontent.com/act101-ai/act101/main/install.ps1) } -AcceptTermsOfService yes -InstallClaudePlugin yes"
```

### 3. Claude Code marketplace (if you already have `act` on `PATH`)

If the shell installer has already placed `act` on your `PATH`, or you
built from source, you can register the plugin directly with Claude
Code:

```bash
claude plugin marketplace add act101-ai/act101
claude plugin install act101@act101-marketplace
```

On first session start the plugin's launcher locates the `act` binary
already on your `PATH` (version-matched). If none is present it falls
back to downloading one under `${CLAUDE_PLUGIN_DATA}/bin`. Node 18+ on
`PATH` is required for the launcher either way.

Tool list and skills are described in `plugin/README.md`.

### 4. Codex marketplace (if you already have `act` on `PATH`)

If you've already installed `act` via the shell installer, Homebrew, or
built from source, you can register the plugin directly with Codex
without re-downloading the binary:

```bash
codex plugin marketplace add act101-ai/act101
```

That registers the marketplace. To activate the `act101` plugin in
your sessions, open Codex and run the `/plugins` slash command, then
select **act101** → **Install plugin**. Codex 0.124.0 has no
non-interactive install verb yet; the slash command is the install
action.

The same launcher and binary-resolution rules from §3 apply. Codex does
not pre-warm the binary at session start, so the first MCP call after a
fresh install pays a one-time download cost if no `act` is on `PATH`.

### 5. opencode (if you already have `act` on `PATH`)

If you've already installed `act` via the shell installer or built from
source, register `act101` with [opencode](https://opencode.ai) in one
command:

```bash
act install opencode
```

This writes the `act101` MCP server entry into
`~/.config/opencode/opencode.json` (preserving any other `mcp.*` entries
and JSONC comments) and deploys the act101 skill set into
`~/.config/opencode/skills/`. Existing skill directories are skipped;
pass `--force` to overwrite.

To remove everything in one step:

```bash
act uninstall opencode
```

Uninstall walks the install manifest in `install.toml` and deletes only
the files act wrote — user-added files in the same directories are
preserved.

### 6. Manual download

Grab the archive for your platform from the
[latest release](https://github.com/act101-ai/act101/releases/latest),
verify against `SHA256SUMS.txt`, extract, and place `act` (or
`act.exe`) on your `PATH`.

```bash
# Linux x86_64 (static musl build)
curl -LO https://github.com/act101-ai/act101/releases/latest/download/act-x86_64-unknown-linux-musl.tar.gz
tar xzf act-x86_64-unknown-linux-musl.tar.gz
install -m 755 act ~/.local/bin/act
```

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

The Linux musl build is statically linked and has no libc version
requirement — use it if you see `GLIBC_X.YY not found` from the glibc
build.

---

## First-run Terms of Service

`act` requires one-time Terms of Service acceptance before any tool
runs. The shell installer walks you through it. Outside the installer,
accept from a terminal:

```bash
act tos show     # read the terms
act tos accept   # record acceptance
```

Under the Claude Code plugin, the MCP server always starts but gates
every tool behind the TOS. Use the `tos_show` and `tos_accept` tools —
Claude Code's standard tool-consent UI is the acceptance surface.

---

## Generous free tier

**act101 is free for personal and open-source use — forever.** No license
key, no account, no expiration. All query tools, all core languages,
rename, fix-auto, and three analysis tools — included permanently.

The free tier is a complete navigation and token-efficiency tool, not
a time-limited trial. Paid tiers (Pro, Teams, Enterprise) unlock
additional mutations, analysis tools, premium languages, and commercial
use. See [pricing](https://act101.ai/pricing) for details.

### Planned (not yet wired)

- **OAuth registration** for license management — `act login` will open a
  browser-based flow tied to an account.

---

## Tips & tricks

- **Prefer `act` over reading files.** `act skeleton <file>` returns a
  file's API (signatures, types, exports) without bodies — usually
  5–10× fewer tokens than reading the raw file.
- **Use `act symbols` to navigate unfamiliar code.** Lists every
  symbol in a file with kind and location. Pair with `act definition`
  and `act references` for jump-to and find-usages.
- **`act status` prints detected languages, LSP readiness, and every
  available tool** for the current workspace. Start here when
  something behaves unexpectedly.
- **`act diagnostics`** returns LSP errors/warnings without running a
  build. Scope by passing a directory or file.
- **Refactor previews are cheap.** Every refactor (`rename`,
  `extract_function`, `move_symbol`, `inline`, …) supports
  `preview: true` — inspect the change set before it touches disk.
- **Undo is one call.** `act history undo` reverses the last
  refactor. `act history list` shows what's reversible.
- **LSP is optional.** Single-file refactors (rename-in-file,
  extract-variable, etc.) work without an LSP. Cross-file operations
  (rename-across-repo, move, find-references) benefit from one.
- **Set `ACT_LOG_LEVEL=debug`** when diagnosing plugin or MCP issues;
  logs go to stderr and don't interfere with MCP stdout.

---

## Links

- **Releases & binaries:** [github.com/act101-ai/act101/releases](https://github.com/act101-ai/act101/releases)
- **Issues & feedback:** open an issue in this repo.
- **Homepage:** [act101.ai](https://act101.ai)
