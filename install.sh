#!/usr/bin/env bash
# act installer for Linux and macOS.
# Usage: curl -sSL https://act101.ai/install.sh | sh [-s -- <flags>]
#
# Flags:
#   --accept-terms-of-service=<yes|no|ask>  TOS handling (default: ask)
#   --enable-daemon=<yes|no|ask>            Daemon preference (default: ask)
#   --auto-start=<yes|no|ask>               Auto-start preference (default: ask)
#   --install-claude-plugin=<yes|no|ask>    Register with Claude Code (default: ask)
#   --prefix=<path>                         Install prefix
#   --version=<vX.Y.Z>                      Pin version
#
# Environment variables (alternative to flags):
#   ACT_ACCEPT_TOS, ACT_ENABLE_DAEMON, ACT_AUTO_START,
#   ACT_INSTALL_CLAUDE_PLUGIN, ACT_PREFIX, ACT_VERSION
#
# Uninstall:
#   curl -sSL https://act101.ai/install.sh | sh -s uninstall

# ACT_DEFAULT_VERSION is substituted at release time by the build-installers job.
: "${ACT_DEFAULT_VERSION:=v0.7.19}"
: "${ACT_GITHUB_REPO:=act101-ai/act101}"

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
    local os="$1" arch="$2"
    case "$os/$arch" in
        linux/x86_64) echo x86_64-unknown-linux-musl ;;
        linux/aarch64) echo aarch64-unknown-linux-gnu ;;
        darwin/x86_64) echo x86_64-apple-darwin ;;
        darwin/aarch64) echo aarch64-apple-darwin ;;
        *) echo "unsupported platform: $os/$arch" >&2; return 1 ;;
    esac
}

parse_tos_value() {
    local v="${1:-ask}"
    case "${v,,}" in
        ""|ask) echo ask ;;
        yes|accept|true|1|y) echo yes ;;
        no|false|0|n) echo no ;;
        *) echo "invalid TOS value: $v (use yes|no|ask)" >&2; return 1 ;;
    esac
}

parse_tristate() {
    local v="${1:-ask}"
    case "${v,,}" in
        ""|ask) echo ask ;;
        yes|true|1|y) echo yes ;;
        no|false|0|n) echo no ;;
        *) echo "invalid value: $v (use yes|no|ask)" >&2; return 1 ;;
    esac
}

# --- colors (respect NO_COLOR / ACT_NO_COLOR) ---
if [ -n "${NO_COLOR:-}" ] || [ -n "${ACT_NO_COLOR:-}" ] || [ ! -t 1 ]; then
    ORANGE="" GRAY="" WHITE="" BOLD="" RESET="" DIM=""
else
    ORANGE=$'\033[38;5;208m'
    GRAY=$'\033[38;5;245m'
    WHITE=$'\033[97m'
    BOLD=$'\033[1m'
    RESET=$'\033[0m'
    DIM=$'\033[2m'
fi

TRIPLETS_DOWNLOAD=(
    "arduously:collecting:things"
    "anxiously:counting:tokens"
    "acquiring:compressed:tarball"
    "another:cool:tool"
)
TRIPLETS_VERIFY=(
    "absolutely:checking:that"
    "assessing:cryptographic:truth"
    "anxiously:confirming:things"
    "authenticating:content:trustworthiness"
)
TRIPLETS_INSTALL=(
    "assembling:cool:tools"
    "actually:configuring:things"
    "aggressively:claiming:territory"
    "adding:capabilities:though"
)
TRIPLETS_TOS=(
    "attorneys:crafted:this"
    "acknowledging:conditions:transparently"
    "anxiously:consenting:though"
    "accepting:conditions:thoughtfully"
)
TRIPLETS_REGISTER=(
    "attaching:claude:tools"
    "augmenting:coding:talent"
    "agents:cooperating:today"
    "anxiously:connecting:things"
)

act_random_triplet() {
    local -n arr=$1
    local idx=$(( RANDOM % ${#arr[@]} ))
    echo "${arr[$idx]}"
}

act_print_triplet() {
    local a="$1" c="$2" t="$3"
    printf "%s%s%s %s·%s %s%s%s %s·%s %s%s%s" \
        "$WHITE" "$a" "$RESET" "$GRAY" "$RESET" \
        "$WHITE" "$c" "$RESET" "$GRAY" "$RESET" \
        "$WHITE" "$t" "$RESET"
}

act_step() {
    local phase="$1" result="$2"
    if [ -n "${ACT_NON_INTERACTIVE:-}" ] || [ ! -t 1 ]; then
        echo "  $phase  $result"
        return
    fi
    local triplet
    triplet="$(act_random_triplet "TRIPLETS_${phase}")"
    local a c t
    IFS=: read -r a c t <<< "$triplet"
    printf "  "
    act_print_triplet "$a" "$c" "$t"
    printf "       %s%s%s\n" "$GRAY" "$result" "$RESET"
}

act_banner() {
    printf "\n  %s%sact101%s\n\n" "$ORANGE" "$BOLD" "$RESET"
}

act_finale() {
    local version="$1" tools="$2" langs="$3"
    printf "\n"
    printf "  %s┌──────────────────────────────────────────────┐%s\n" "$ORANGE" "$RESET"
    printf "  %s│%s  %sanalyze%s %s·%s %scode%s %s·%s %stransform%s                  %s│%s\n" \
        "$ORANGE" "$RESET" "$WHITE" "$RESET" "$GRAY" "$RESET" "$WHITE" "$RESET" "$GRAY" "$RESET" "$WHITE" "$RESET" "$ORANGE" "$RESET"
    printf "  %s│%s                                              %s│%s\n" "$ORANGE" "$RESET" "$ORANGE" "$RESET"
    printf "  %s│%s  act v%s · %s tools · %s+ languages    %s│%s\n" \
        "$ORANGE" "$RESET" "$version" "$tools" "$langs" "$ORANGE" "$RESET"
    printf "  %s│%s                                              %s│%s\n" "$ORANGE" "$RESET" "$ORANGE" "$RESET"
    printf "  %s│%s  Ask your agent, or run: act --help          %s│%s\n" "$ORANGE" "$RESET" "$ORANGE" "$RESET"
    printf "  %s└──────────────────────────────────────────────┘%s\n\n" "$ORANGE" "$RESET"
}

detect_hosts() {
    DETECTED_HOSTS=""
    if command -v claude >/dev/null 2>&1; then
        DETECTED_HOSTS="${DETECTED_HOSTS} claude-code"
    fi
    local home="${HOME:-}"
    [ -d "$home/.cursor" ] && DETECTED_HOSTS="${DETECTED_HOSTS} cursor"
    [ -d "$home/.windsurf" ] && DETECTED_HOSTS="${DETECTED_HOSTS} windsurf"
    { [ -d "${XDG_CONFIG_HOME:-$home/.config}/zed" ] || [ -d "$home/Library/Application Support/Zed" ]; } && DETECTED_HOSTS="${DETECTED_HOSTS} zed"
    command -v codex >/dev/null 2>&1 && DETECTED_HOSTS="${DETECTED_HOSTS} codex"
    [ -d "$home/.continue" ] && DETECTED_HOSTS="${DETECTED_HOSTS} continue"
    DETECTED_HOSTS="$(echo "$DETECTED_HOSTS" | xargs)"
    echo "$DETECTED_HOSTS"
}

# Allow bats to source this file without executing main.
if [ -n "${ACT_INSTALL_LIB:-}" ]; then return 0; fi

set -euo pipefail

act_banner

# --- arg parsing ---
TOS="${ACT_ACCEPT_TOS:-}"
DAEMON="${ACT_ENABLE_DAEMON:-}"
AUTOSTART="${ACT_AUTO_START:-}"
CLAUDE_PLUGIN="${ACT_INSTALL_CLAUDE_PLUGIN:-}"
PREFIX="${ACT_PREFIX:-}"
VERSION="${ACT_VERSION:-}"
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
        --help|-h)
            sed -n '1,25p' "$0" | grep -E '^#' | sed 's/^# \?//'
            exit 0 ;;
        *) echo "unknown argument: $arg" >&2; exit 2 ;;
    esac
done

TOS="$(parse_tos_value "$TOS")"
DAEMON="$(parse_tristate "$DAEMON")"
AUTOSTART="$(parse_tristate "$AUTOSTART")"
CLAUDE_PLUGIN="$(parse_tristate "$CLAUDE_PLUGIN")"

OS="$(detect_os)"
ARCH="$(detect_arch)"
TARGET="$(select_target "$OS" "$ARCH")"

# Default prefix: /usr/local/bin for root, $HOME/.local/bin otherwise
if [ -z "$PREFIX" ]; then
    if [ "$(id -u)" = 0 ]; then PREFIX="/usr/local/bin"; else PREFIX="$HOME/.local/bin"; fi
fi

# Config dir
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/act"
CONFIG_FILE="$CONFIG_DIR/install.toml"

# --- uninstall ---
if [ "$MODE" = uninstall ]; then
    BIN="$PREFIX/act"
    if [ -f "$BIN" ]; then rm -f "$BIN" && echo "removed $BIN"; else echo "not found: $BIN"; fi
    exit 0
fi

# --- resolve version ---
if [ -z "$VERSION" ]; then VERSION="$ACT_DEFAULT_VERSION"; fi
if [ "$VERSION" = latest ]; then
    VERSION="$(curl -fsSL "https://api.github.com/repos/$ACT_GITHUB_REPO/releases/latest" \
        | grep -E '"tag_name"' | head -1 | sed -E 's/.*"v?([^"]+)".*/\1/')"
    VERSION="v$VERSION"
fi
VER_NO_V="${VERSION#v}"

# --- download + verify ---
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
BASE="https://github.com/$ACT_GITHUB_REPO/releases/download/$VERSION"
ASSET="act-$TARGET.tar.gz"
curl -fSL -o "$TMPDIR/$ASSET" "$BASE/$ASSET"
curl -fSL -o "$TMPDIR/SHA256SUMS.txt" "$BASE/SHA256SUMS.txt"
act_step "DOWNLOAD" "$ASSET"

EXPECTED="$(grep " $ASSET$" "$TMPDIR/SHA256SUMS.txt" | awk '{print $1}')"
ACTUAL="$(sha256sum "$TMPDIR/$ASSET" | awk '{print $1}')"
if [ -z "$EXPECTED" ] || [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "checksum mismatch for $ASSET" >&2; exit 1
fi
act_step "VERIFY" "SHA-256 ✓"

# --- extract + install ---
mkdir -p "$PREFIX"
tar xzf "$TMPDIR/$ASSET" -C "$TMPDIR"
install -m 755 "$TMPDIR/act" "$PREFIX/act"
act_step "INSTALL" "$PREFIX/act"

# PATH warning for non-root
if [ "$(id -u)" != 0 ] && ! echo ":$PATH:" | grep -q ":$PREFIX:"; then
    echo "!! $PREFIX is not on \$PATH. Add: export PATH=\"$PREFIX:\$PATH\""
fi

# --- write install.toml ---
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<EOF
[install]
version = "$VER_NO_V"
prefix = "$PREFIX"
installed_at = "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

[runtime]
enable_daemon = "$DAEMON"
auto_start = "$AUTOSTART"
EOF

# --- TOS handling ---
HAS_TTY=0; [ -t 0 ] && HAS_TTY=1
case "$TOS" in
    yes)
        "$PREFIX/act" tos accept --yes 2>/dev/null
        act_step "TOS" "✓"
        ;;
    no)
        echo "  Terms: https://act101.ai/terms (not yet accepted)"
        ;;
    ask)
        if [ "$HAS_TTY" = 1 ]; then
            printf "\n  Terms of service: %shttps://act101.ai/terms%s\n" "$WHITE" "$RESET"
            printf "  Accept? [Y/n] "
            read -r reply </dev/tty || reply=""
            case "${reply,,}" in
                ""|y|yes)
                    "$PREFIX/act" tos accept --yes 2>/dev/null
                    act_step "TOS" "✓"
                    ;;
                *)
                    echo "  TOS declined; install aborted"
                    exit 1
                    ;;
            esac
        else
            echo "  Terms: https://act101.ai/terms (run 'act tos accept' before first use)"
        fi
        ;;
esac

# --- Host detection ---
DETECTED="$(detect_hosts)"

for host in $DETECTED; do
    case "$host" in
        claude-code)
            case "$CLAUDE_PLUGIN" in
                yes)
                    "$PREFIX/act" install claude-code 2>/dev/null
                    act_step "REGISTER" "Claude Code ✓"
                    ;;
                no) : ;;
                ask)
                    if [ "$HAS_TTY" = 1 ]; then
                        printf "  Register with Claude Code? [Y/n] "
                        read -r reply </dev/tty || reply=""
                        case "${reply,,}" in
                            ""|y|yes)
                                "$PREFIX/act" install claude-code 2>/dev/null
                                act_step "REGISTER" "Claude Code ✓"
                                ;;
                            *) echo "  Skipped." ;;
                        esac
                    fi
                    ;;
            esac
            ;;
        *)
            echo "  Detected ${host} — run 'act guidance' for setup"
            ;;
    esac
done

if command -v "$PREFIX/act" >/dev/null 2>&1; then
    STATUS_JSON="$("$PREFIX/act" --format json status 2>/dev/null || echo '{}')"
    TOOLS="$(echo "$STATUS_JSON" | sed -n 's/.*"tool_count":\([0-9]*\).*/\1/p')"
    LANGS="$(echo "$STATUS_JSON" | sed -n 's/.*"language_count":\([0-9]*\).*/\1/p')"
    [ -z "$TOOLS" ] && TOOLS="?"
    [ -z "$LANGS" ] && LANGS="100"
    act_finale "$VER_NO_V" "$TOOLS" "$LANGS"
else
    echo "==> Done. Run 'act --help' to get started."
fi
