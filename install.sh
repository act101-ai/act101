#!/bin/sh
# act installer for Linux and macOS (POSIX sh — works under dash, bash, ash, zsh).
# Usage: curl -sSL https://act101.ai/install.sh | sh [-s -- <flags>]
#
# Flags:
#   --accept-terms-of-service=<yes|no|ask>  TOS handling (default: ask)
#   --enable-daemon=<yes|no|ask>            Daemon preference (default: ask)
#   --auto-start=<yes|no|ask>               Auto-start preference (default: ask)
#   --install-claude-plugin=<yes|no|ask>    Register with Claude Code (default: ask)
#   --prefix=<path>                         Install prefix
#   --version=<vX.Y.Z>                      Pin version
#   --dry-run                               Print what would happen, make no changes
#   --debug                                 Verbose trace output (set -x)
#
# Environment variables (alternative to flags):
#   ACT_ACCEPT_TOS, ACT_ENABLE_DAEMON, ACT_AUTO_START,
#   ACT_INSTALL_CLAUDE_PLUGIN, ACT_PREFIX, ACT_VERSION,
#   ACT_DRY_RUN=1, ACT_DEBUG=1
#
# Uninstall:
#   curl -sSL https://act101.ai/install.sh | sh -s uninstall

# ACT_DEFAULT_VERSION is substituted at release time by the build-installers job.
: "${ACT_DEFAULT_VERSION:=v0.7.20}"
: "${ACT_GITHUB_REPO:=act101-ai/act101}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

detect_os() {
    case "$(uname -s)" in
        Linux) echo linux ;;
        Darwin) echo darwin ;;
        *) echo "unsupported OS: $(uname -s)" >&2; return 1 ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo x86_64 ;;
        arm64|aarch64) echo aarch64 ;;
        *) echo "unsupported arch: $(uname -m)" >&2; return 1 ;;
    esac
}

select_target() {
    os="$1" arch="$2"
    case "$os/$arch" in
        linux/x86_64) echo x86_64-unknown-linux-musl ;;
        linux/aarch64) echo aarch64-unknown-linux-gnu ;;
        darwin/x86_64) echo x86_64-apple-darwin ;;
        darwin/aarch64) echo aarch64-apple-darwin ;;
        *) echo "unsupported platform: $os/$arch" >&2; return 1 ;;
    esac
}

to_lower() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

parse_tos_value() {
    v="${1:-ask}"
    lv=$(to_lower "$v")
    case "$lv" in
        ""|ask) echo ask ;;
        yes|accept|true|1|y) echo yes ;;
        no|false|0|n) echo no ;;
        *) echo "invalid TOS value: $v (use yes|no|ask)" >&2; return 1 ;;
    esac
}

parse_tristate() {
    v="${1:-ask}"
    lv=$(to_lower "$v")
    case "$lv" in
        ""|ask) echo ask ;;
        yes|true|1|y) echo yes ;;
        no|false|0|n) echo no ;;
        *) echo "invalid value: $v (use yes|no|ask)" >&2; return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# Colors (respect NO_COLOR / ACT_NO_COLOR; disabled in non-interactive / dry-run)
# ---------------------------------------------------------------------------
if [ -n "${NO_COLOR:-}" ] || [ -n "${ACT_NO_COLOR:-}" ] || [ ! -t 1 ]; then
    ORANGE="" GRAY="" WHITE="" BOLD="" RESET="" DIM=""
else
    # Use printf so escape sequences are evaluated in a POSIX-portable way.
    ESC=$(printf '\033')
    ORANGE="${ESC}[38;5;208m"
    GRAY="${ESC}[38;5;245m"
    WHITE="${ESC}[97m"
    BOLD="${ESC}[1m"
    RESET="${ESC}[0m"
    DIM="${ESC}[2m"
fi

# ---------------------------------------------------------------------------
# Triplet scroller — POSIX-compatible (no arrays, no bash namerefs)
# ---------------------------------------------------------------------------
# Generate a pseudo-random integer in [0, N). POSIX shells don't have $RANDOM.
rand_idx() {
    n="$1"
    # Use awk to derive a random index from the PID and current seconds.
    awk -v n="$n" -v seed="$$$(date +%s 2>/dev/null)" \
        'BEGIN { srand(seed); printf "%d", int(rand() * n) }'
}

# Given a phase name, echo a single `a:c:t` triplet. Embeds the list directly
# so we don't rely on arrays or namerefs.
random_triplet() {
    phase="$1"
    idx=$(rand_idx 4)
    case "${phase}_${idx}" in
        DOWNLOAD_0) echo "arduously:collecting:things" ;;
        DOWNLOAD_1) echo "anxiously:counting:tokens" ;;
        DOWNLOAD_2) echo "acquiring:compressed:tarball" ;;
        DOWNLOAD_3) echo "another:cool:tool" ;;
        VERIFY_0) echo "absolutely:checking:that" ;;
        VERIFY_1) echo "assessing:cryptographic:truth" ;;
        VERIFY_2) echo "anxiously:confirming:things" ;;
        VERIFY_3) echo "authenticating:content:trustworthiness" ;;
        INSTALL_0) echo "assembling:cool:tools" ;;
        INSTALL_1) echo "actually:configuring:things" ;;
        INSTALL_2) echo "aggressively:claiming:territory" ;;
        INSTALL_3) echo "adding:capabilities:though" ;;
        TOS_0) echo "attorneys:crafted:this" ;;
        TOS_1) echo "acknowledging:conditions:transparently" ;;
        TOS_2) echo "anxiously:consenting:though" ;;
        TOS_3) echo "accepting:conditions:thoughtfully" ;;
        REGISTER_0) echo "attaching:claude:tools" ;;
        REGISTER_1) echo "augmenting:coding:talent" ;;
        REGISTER_2) echo "agents:cooperating:today" ;;
        REGISTER_3) echo "anxiously:connecting:things" ;;
        *) echo "working:on:it" ;;
    esac
}

print_triplet() {
    a="$1" c="$2" t="$3"
    printf "%s%s%s %s·%s %s%s%s %s·%s %s%s%s" \
        "$WHITE" "$a" "$RESET" "$GRAY" "$RESET" \
        "$WHITE" "$c" "$RESET" "$GRAY" "$RESET" \
        "$WHITE" "$t" "$RESET"
}

act_step() {
    phase="$1" result="$2"
    if [ -n "${ACT_NON_INTERACTIVE:-}" ] || [ ! -t 1 ]; then
        echo "  $phase  $result"
        return 0
    fi
    triplet=$(random_triplet "$phase")
    a=$(echo "$triplet" | cut -d: -f1)
    c=$(echo "$triplet" | cut -d: -f2)
    t=$(echo "$triplet" | cut -d: -f3)
    printf "  "
    print_triplet "$a" "$c" "$t"
    printf "       %s%s%s\n" "$GRAY" "$result" "$RESET"
}

act_banner() {
    printf "\n  %s%sact101%s\n\n" "$ORANGE" "$BOLD" "$RESET"
}

act_finale() {
    version="$1" tools="$2" langs="$3"
    # Inner box width (between the two `│` characters) — the top/bottom border
    # uses 46 box-drawing dashes, so every content line must total 46 columns.
    inner=46
    line_b="  act v${version} · ${tools} tools · ${langs}+ languages"
    pad_b=$(printf '%*s' $((inner - ${#line_b})) '')
    printf "\n"
    printf "  %s┌──────────────────────────────────────────────┐%s\n" "$ORANGE" "$RESET"
    printf "  %s│%s  %sanalyze%s %s·%s %scode%s %s·%s %stransform%s                  %s│%s\n" \
        "$ORANGE" "$RESET" "$WHITE" "$RESET" "$GRAY" "$RESET" "$WHITE" "$RESET" "$GRAY" "$RESET" "$WHITE" "$RESET" "$ORANGE" "$RESET"
    printf "  %s│%s                                              %s│%s\n" "$ORANGE" "$RESET" "$ORANGE" "$RESET"
    printf "  %s│%s  act v%s · %s tools · %s+ languages%s%s│%s\n" \
        "$ORANGE" "$RESET" "$version" "$tools" "$langs" "$pad_b" "$ORANGE" "$RESET"
    printf "  %s│%s                                              %s│%s\n" "$ORANGE" "$RESET" "$ORANGE" "$RESET"
    printf "  %s│%s  Ask your agent, or run: act --help          %s│%s\n" "$ORANGE" "$RESET" "$ORANGE" "$RESET"
    printf "  %s└──────────────────────────────────────────────┘%s\n\n" "$ORANGE" "$RESET"
}

detect_hosts() {
    hosts=""
    home="${HOME:-}"
    # Claude Code: CLI on PATH, ~/.claude config dir, or the macOS app bundle.
    # The CLI isn't always installed (e.g. desktop-only setups), so falling
    # back to the config dir / app bundle keeps detection reliable.
    if command -v claude >/dev/null 2>&1 \
        || [ -d "$home/.claude" ] \
        || [ -d "/Applications/Claude.app" ]; then
        hosts="${hosts} claude-code"
    fi
    [ -d "$home/.cursor" ] && hosts="${hosts} cursor"
    [ -d "$home/.windsurf" ] && hosts="${hosts} windsurf"
    if [ -d "${XDG_CONFIG_HOME:-$home/.config}/zed" ] || [ -d "$home/Library/Application Support/Zed" ]; then
        hosts="${hosts} zed"
    fi
    command -v codex >/dev/null 2>&1 && hosts="${hosts} codex"
    [ -d "$home/.continue" ] && hosts="${hosts} continue"
    echo "$hosts" | tr -s ' ' | sed -e 's/^ *//' -e 's/ *$//'
}

# ---------------------------------------------------------------------------
# Dry-run helpers
# ---------------------------------------------------------------------------
# DRY prefix: when in dry-run mode, print what would run instead of running.
dry_run() {
    if [ -n "${DRY_RUN:-}" ]; then
        printf "  %s[dry-run]%s %s\n" "$GRAY" "$RESET" "$*"
        return 0
    fi
    return 1
}

# Execute a command unless dry-run is set. Prints the command under --debug.
run_cmd() {
    if dry_run "$*"; then
        return 0
    fi
    if [ -n "${ACT_DEBUG:-}" ]; then
        printf "  %s\$%s %s\n" "$GRAY" "$RESET" "$*" >&2
    fi
    "$@"
}

# Register the act101 plugin with Claude Code.
# Runs `marketplace add → marketplace update → plugin install`. The `update`
# step works around a pre-2.1.70 Claude Code race where `plugin install`
# immediately after `marketplace add` can fail with "Plugin not found in
# marketplace" before the marketplace listing is refreshed.
register_claude_plugin() {
    if ! command -v claude >/dev/null 2>&1; then
        echo "  Claude Code CLI not on PATH; skipping plugin registration."
        return 1
    fi
    if ! run_cmd claude plugin marketplace add act101-ai/act101; then
        echo "  'claude plugin marketplace add' failed; skipping registration."
        return 1
    fi
    run_cmd claude plugin marketplace update act101-marketplace || true
    if ! run_cmd claude plugin install act101@act101-marketplace; then
        echo "  'claude plugin install' failed. Try manually:"
        echo "    claude plugin marketplace update act101-marketplace"
        echo "    claude plugin install act101@act101-marketplace"
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Library hook — allow bats to source this file without executing main.
# ---------------------------------------------------------------------------
if [ -n "${ACT_INSTALL_LIB:-}" ]; then return 0 2>/dev/null || exit 0; fi

set -eu

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
TOS="${ACT_ACCEPT_TOS:-}"
DAEMON="${ACT_ENABLE_DAEMON:-}"
AUTOSTART="${ACT_AUTO_START:-}"
CLAUDE_PLUGIN="${ACT_INSTALL_CLAUDE_PLUGIN:-}"
PREFIX="${ACT_PREFIX:-}"
VERSION="${ACT_VERSION:-}"
DRY_RUN="${ACT_DRY_RUN:-}"
MODE="install"

for arg in "$@"; do
    case "$arg" in
        uninstall) MODE="uninstall" ;;
        --accept-terms-of-service=*) TOS="${arg#*=}" ;;
        --enable-daemon=*) DAEMON="${arg#*=}" ;;
        --auto-start=*) AUTOSTART="${arg#*=}" ;;
        --install-claude-plugin=*) CLAUDE_PLUGIN="${arg#*=}" ;;
        --prefix=*) PREFIX="${arg#*=}" ;;
        --version=*) VERSION="${arg#*=}" ;;
        --dry-run) DRY_RUN=1 ;;
        --debug) ACT_DEBUG=1 ;;
        --help|-h)
            # Print the leading comment block as help text (skip the shebang
            # on line 1, print every subsequent `#`-prefixed line, stop at
            # the first non-comment line).
            awk 'NR==1 && /^#!/ { next }
                 /^#/ { sub(/^# ?/, ""); sub(/^#$/, ""); print; next }
                 { exit }' "$0" 2>/dev/null || \
                cat <<'USAGE'
act installer. See https://act101.ai/install.sh
Flags: --dry-run, --debug, --prefix=PATH, --version=vX.Y.Z,
       --accept-terms-of-service=<yes|no|ask>, --enable-daemon=<yes|no|ask>,
       --auto-start=<yes|no|ask>, --install-claude-plugin=<yes|no|ask>
USAGE
            exit 0 ;;
        *) echo "unknown argument: $arg" >&2; exit 2 ;;
    esac
done

if [ -n "${ACT_DEBUG:-}" ]; then
    set -x
fi

TOS=$(parse_tos_value "$TOS")
DAEMON=$(parse_tristate "$DAEMON")
AUTOSTART=$(parse_tristate "$AUTOSTART")
CLAUDE_PLUGIN=$(parse_tristate "$CLAUDE_PLUGIN")

OS=$(detect_os)
ARCH=$(detect_arch)
TARGET=$(select_target "$OS" "$ARCH")

# Default prefix: /usr/local/bin for root, $HOME/.local/bin otherwise.
if [ -z "$PREFIX" ]; then
    if [ "$(id -u)" = 0 ]; then PREFIX="/usr/local/bin"; else PREFIX="$HOME/.local/bin"; fi
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/act"
CONFIG_FILE="$CONFIG_DIR/install.toml"

act_banner

if [ -n "${DRY_RUN:-}" ]; then
    printf "  %s[dry-run mode — no changes will be made]%s\n\n" "$GRAY" "$RESET"
    cat <<INFO
  platform:      $OS/$ARCH
  target:        $TARGET
  prefix:        $PREFIX
  config dir:    $CONFIG_DIR
  config file:   $CONFIG_FILE
  tos:           $TOS
  daemon:        $DAEMON
  auto-start:    $AUTOSTART
  claude-plugin: $CLAUDE_PLUGIN
  version:       ${VERSION:-$ACT_DEFAULT_VERSION}
  github repo:   $ACT_GITHUB_REPO

INFO
fi

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------
if [ "$MODE" = uninstall ]; then
    BIN="$PREFIX/act"
    if [ -f "$BIN" ]; then
        run_cmd rm -f "$BIN" && echo "removed $BIN"
    else
        echo "not found: $BIN"
    fi
    exit 0
fi

# ---------------------------------------------------------------------------
# Resolve version
# ---------------------------------------------------------------------------
if [ -z "$VERSION" ]; then VERSION="$ACT_DEFAULT_VERSION"; fi
if [ "$VERSION" = latest ]; then
    VERSION=$(curl -fsSL "https://api.github.com/repos/$ACT_GITHUB_REPO/releases/latest" \
        | grep -E '"tag_name"' | head -1 | sed -E 's/.*"(v?[^"]+)".*/\1/')
    case "$VERSION" in v*) : ;; *) VERSION="v$VERSION" ;; esac
fi
VER_NO_V="${VERSION#v}"

# ---------------------------------------------------------------------------
# Download + verify
# ---------------------------------------------------------------------------
TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t act-install)
trap 'rm -rf "$TMPDIR"' EXIT INT TERM
BASE="https://github.com/$ACT_GITHUB_REPO/releases/download/$VERSION"
ASSET="act-$TARGET.tar.gz"

if [ -n "${DRY_RUN:-}" ]; then
    echo "  Would download: $BASE/$ASSET"
    echo "  Would download: $BASE/SHA256SUMS.txt"
    echo "  Would verify SHA-256"
    echo "  Would extract and install to $PREFIX/act"
else
    run_cmd curl -fSL -o "$TMPDIR/$ASSET" "$BASE/$ASSET"
    run_cmd curl -fSL -o "$TMPDIR/SHA256SUMS.txt" "$BASE/SHA256SUMS.txt"
    act_step "DOWNLOAD" "$ASSET"

    EXPECTED=$(grep " $ASSET$" "$TMPDIR/SHA256SUMS.txt" | awk '{print $1}')
    if command -v sha256sum >/dev/null 2>&1; then
        ACTUAL=$(sha256sum "$TMPDIR/$ASSET" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        ACTUAL=$(shasum -a 256 "$TMPDIR/$ASSET" | awk '{print $1}')
    else
        echo "error: neither sha256sum nor shasum is available" >&2
        exit 1
    fi
    if [ -z "$EXPECTED" ] || [ "$EXPECTED" != "$ACTUAL" ]; then
        echo "checksum mismatch for $ASSET (expected=$EXPECTED actual=$ACTUAL)" >&2
        exit 1
    fi
    act_step "VERIFY" "SHA-256 ✓"

    run_cmd mkdir -p "$PREFIX"
    run_cmd tar xzf "$TMPDIR/$ASSET" -C "$TMPDIR"
    run_cmd install -m 755 "$TMPDIR/act" "$PREFIX/act"
    act_step "INSTALL" "$PREFIX/act"
fi

# PATH warning for non-root.
if [ "$(id -u)" != 0 ] && ! echo ":$PATH:" | grep -q ":$PREFIX:"; then
    echo "!! $PREFIX is not on \$PATH. Add: export PATH=\"$PREFIX:\$PATH\""
fi

# ---------------------------------------------------------------------------
# Write install.toml
# ---------------------------------------------------------------------------
INSTALL_TOML_CONTENT="[install]
version = \"$VER_NO_V\"
prefix = \"$PREFIX\"
installed_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"

[runtime]
enable_daemon = \"$DAEMON\"
auto_start = \"$AUTOSTART\"
"

if [ -n "${DRY_RUN:-}" ]; then
    echo
    echo "  Would write $CONFIG_FILE:"
    printf '%s' "$INSTALL_TOML_CONTENT" | sed 's/^/    /'
else
    run_cmd mkdir -p "$CONFIG_DIR"
    printf '%s' "$INSTALL_TOML_CONTENT" > "$CONFIG_FILE"
fi

# ---------------------------------------------------------------------------
# TOS handling
# ---------------------------------------------------------------------------
HAS_TTY=0; [ -t 0 ] && HAS_TTY=1
ACT_BIN="$PREFIX/act"

accept_tos_now() {
    if [ -n "${DRY_RUN:-}" ]; then
        echo "  Would run: $ACT_BIN tos accept --yes"
        act_step "TOS" "✓ (dry-run)"
    else
        run_cmd "$ACT_BIN" tos accept --yes 2>/dev/null || true
        act_step "TOS" "✓"
    fi
}

case "$TOS" in
    yes) accept_tos_now ;;
    no)  echo "  Terms: https://act101.ai/terms (not yet accepted)" ;;
    ask)
        if [ "$HAS_TTY" = 1 ]; then
            printf "\n  Terms of service: %shttps://act101.ai/terms%s\n" "$WHITE" "$RESET"
            printf "  Accept? [Y/n] "
            reply=""
            read -r reply </dev/tty 2>/dev/null || reply=""
            reply=$(to_lower "$reply")
            case "$reply" in
                ""|y|yes) accept_tos_now ;;
                *) echo "  TOS declined; install aborted"; exit 1 ;;
            esac
        else
            echo "  Terms: https://act101.ai/terms (run 'act tos accept' before first use)"
        fi
        ;;
esac

# ---------------------------------------------------------------------------
# Host detection + registration
# ---------------------------------------------------------------------------
DETECTED=$(detect_hosts)

for host in $DETECTED; do
    case "$host" in
        claude-code)
            echo "  Detected Claude Code"
            case "$CLAUDE_PLUGIN" in
                yes)
                    if register_claude_plugin; then
                        act_step "REGISTER" "Claude Code ✓${DRY_RUN:+ (dry-run)}"
                    fi
                    ;;
                no) : ;;
                ask)
                    if [ "$HAS_TTY" = 1 ]; then
                        printf "  Register with Claude Code? [Y/n] "
                        reply=""
                        read -r reply </dev/tty 2>/dev/null || reply=""
                        reply=$(to_lower "$reply")
                        case "$reply" in
                            ""|y|yes)
                                if register_claude_plugin; then
                                    act_step "REGISTER" "Claude Code ✓${DRY_RUN:+ (dry-run)}"
                                fi
                                ;;
                            *) echo "  Skipped." ;;
                        esac
                    else
                        echo "  Register later: claude plugin marketplace add act101-ai/act101"
                        echo "                  claude plugin marketplace update act101-marketplace"
                        echo "                  claude plugin install act101@act101-marketplace"
                    fi
                    ;;
            esac
            ;;
        *)
            echo "  Detected ${host} — run 'act guidance' for setup"
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Finale
# ---------------------------------------------------------------------------
if [ -n "${DRY_RUN:-}" ]; then
    echo
    echo "  [dry-run complete — re-run without --dry-run to install]"
    exit 0
fi

if [ -x "$ACT_BIN" ]; then
    STATUS_JSON=$("$ACT_BIN" --format json status 2>/dev/null || echo '{}')
    TOOLS=$(echo "$STATUS_JSON" | sed -n 's/.*"tool_count":\([0-9]*\).*/\1/p')
    LANGS=$(echo "$STATUS_JSON" | sed -n 's/.*"language_count":\([0-9]*\).*/\1/p')
    [ -z "$TOOLS" ] && TOOLS="?"
    [ -z "$LANGS" ] && LANGS="100"
    act_finale "$VER_NO_V" "$TOOLS" "$LANGS"
else
    echo "==> Done. Run 'act --help' to get started."
fi
