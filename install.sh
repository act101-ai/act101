#!/usr/bin/env bash
# act installer for Linux and macOS.
# Usage: curl -sSL https://act101.ai/install.sh | sh [-s -- <flags>]
#
# Flags:
#   --accept-terms-of-service=<yes|no|ask>  TOS handling (default: ask)
#   --enable-daemon=<yes|no|ask>            Daemon preference (default: ask)
#   --auto-start=<yes|no|ask>               Auto-start preference (default: ask)
#   --prefix=<path>                         Install prefix
#   --version=<vX.Y.Z>                      Pin version
#
# Environment variables (alternative to flags):
#   ACT_ACCEPT_TOS, ACT_ENABLE_DAEMON, ACT_AUTO_START, ACT_PREFIX, ACT_VERSION
#
# Uninstall:
#   curl -sSL https://act101.ai/install.sh | sh -s uninstall

# ACT_DEFAULT_VERSION is substituted at release time by the build-installers job.
: "${ACT_DEFAULT_VERSION:=v0.7.18}"
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

# Allow bats to source this file without executing main.
if [ -n "${ACT_INSTALL_LIB:-}" ]; then return 0; fi

set -euo pipefail

# --- arg parsing ---
TOS="${ACT_ACCEPT_TOS:-}"
DAEMON="${ACT_ENABLE_DAEMON:-}"
AUTOSTART="${ACT_AUTO_START:-}"
PREFIX="${ACT_PREFIX:-}"
VERSION="${ACT_VERSION:-}"
MODE="install"

for arg in "$@"; do
    case "$arg" in
        uninstall) MODE="uninstall" ;;
        --accept-terms-of-service=*) TOS="${arg#*=}" ;;
        --enable-daemon=*) DAEMON="${arg#*=}" ;;
        --auto-start=*) AUTOSTART="${arg#*=}" ;;
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

echo "==> act $VERSION for $TARGET"

# --- download + verify ---
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
BASE="https://github.com/$ACT_GITHUB_REPO/releases/download/$VERSION"
ASSET="act-$TARGET.tar.gz"
curl -fSL -o "$TMPDIR/$ASSET" "$BASE/$ASSET"
curl -fSL -o "$TMPDIR/SHA256SUMS.txt" "$BASE/SHA256SUMS.txt"

EXPECTED="$(grep " $ASSET$" "$TMPDIR/SHA256SUMS.txt" | awk '{print $1}')"
ACTUAL="$(sha256sum "$TMPDIR/$ASSET" | awk '{print $1}')"
if [ -z "$EXPECTED" ] || [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "checksum mismatch for $ASSET" >&2; exit 1
fi

# --- extract + install ---
mkdir -p "$PREFIX"
tar xzf "$TMPDIR/$ASSET" -C "$TMPDIR"
install -m 755 "$TMPDIR/act" "$PREFIX/act"
echo "==> installed $PREFIX/act"

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
        "$PREFIX/act" tos accept --scripted ;;
    no)
        echo "!! TOS not accepted. Run '$PREFIX/act tos accept' before first use." ;;
    ask)
        if [ "$HAS_TTY" = 1 ]; then
            "$PREFIX/act" tos accept || { echo "TOS declined; install aborted"; exit 1; }
        else
            echo "!! TOS not accepted (non-interactive). Run '$PREFIX/act tos accept' before first use."
        fi ;;
esac

echo "==> Done. Run '$PREFIX/act --help' to get started."
