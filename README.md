# act

**AST-aware code transformer for AI coding agents.** 65+ MCP tools for
code analysis and refactoring across 190+ languages and representational
grammars — typically 80–99% fewer tokens than reading source files with
built-in tools.

This repository is the **public distribution point** for `act`: plugin
files for the [Claude Code](https://claude.ai/code) marketplace and
pre-built binaries for every supported platform. Source code lives in
a separate, gated repository.

---

## Install

All install paths produce a single statically-linked (or
dependency-free) executable. The recommended path is the shell
installer — it handles binary download, Terms of Service, and
optionally wires the Claude Code plugin in one step.

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
- `--version=v0.7.18` — pin a specific release.

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

### 4. Manual download

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

**act is free for personal and open-source use — forever.** No license
key, no account, no expiration. All query tools, all core languages,
rename, fix-auto, and three analysis tools — included permanently.

The free tier is a complete navigation and token-efficiency tool, not
a time-limited trial. Paid tiers (Pro, Teams, Enterprise) unlock
additional mutations, analysis tools, premium languages, and commercial
use. See [pricing](https://act101.ai/pricing) for details.

### Planned (not yet wired)

- **License key activation** for paid tiers — `act license activate
  <key>` will record and validate the key locally.
- **OAuth registration** for seat management — `act login` will open a
  browser-based flow tied to an account.

Neither is required for the free tier.

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
