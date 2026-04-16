# act

**AST-aware code transformer for AI coding agents.** 17 MCP tools for
code analysis and refactoring across 40+ languages — typically 80–99%
fewer tokens than reading source files with built-in tools.

This repository is the **public distribution point** for `act`: plugin
files for the [Claude Code](https://claude.ai/code) marketplace and
pre-built binaries for every supported platform. Source code lives in
a separate, gated repository.

---

## Install

Pick the method that matches how you plan to use `act`. All methods
produce a single statically-linked (or system-dependency-free) executable.

### 1. Claude Code plugin (recommended for Claude Code users)

```bash
claude plugin marketplace add act101-ai/act101
claude plugin install act@act-marketplace
```

On first session start a small Node launcher downloads the matching
binary for your platform and caches it under `${CLAUDE_PLUGIN_DATA}/bin`.
Node 18+ on `PATH` is required.

Tool list and skills are described in the plugin README (shown to you
automatically after install, or viewable in `plugin/README.md`).

### 2. Shell installer (Linux, macOS)

```bash
curl -sSL https://raw.githubusercontent.com/act101-ai/act101/main/install.sh | sh
```

Optional flags (pass after `sh -s --`):

- `--accept-terms-of-service=yes` — accept TOS non-interactively.
- `--prefix=<dir>` — install prefix (defaults to `/usr/local/bin` as
  root, `~/.local/bin` otherwise).
- `--version=v0.7.17` — pin a specific release.

Uninstall: `curl -sSL https://raw.githubusercontent.com/act101-ai/act101/main/install.sh | sh -s uninstall`

### 3. PowerShell installer (Windows)

```powershell
irm https://raw.githubusercontent.com/act101-ai/act101/main/install.ps1 | iex
```

Accept TOS non-interactively:

```powershell
iex "& { $(irm https://raw.githubusercontent.com/act101-ai/act101/main/install.ps1) } -AcceptTermsOfService yes"
```

### 4. Manual download

Grab the archive for your platform from the [latest release](https://github.com/act101-ai/act101/releases/latest),
extract, and place `act` (or `act.exe`) on your `PATH`.

```bash
# Linux x86_64
curl -LO https://github.com/act101-ai/act101/releases/latest/download/act-x86_64-unknown-linux-musl.tar.gz
tar xzf act-x86_64-unknown-linux-musl.tar.gz
install -m 755 act ~/.local/bin/act
```

Verify the download against `SHA256SUMS.txt` from the same release.

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
runs. Under the Claude Code plugin, the MCP server surfaces the TOS
through two handshake tools (`tos_show` and `tos_accept`); Claude
Code's standard tool-consent UI is the acceptance surface.

Outside Claude Code, accept from a terminal:

```bash
act tos show     # read the terms
act tos accept   # record acceptance
```

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
