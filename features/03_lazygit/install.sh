#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

LAZYGIT_VERSION=0.63.1

# Prebuilt release binary is pure Go (static) and reports a real version, so
# this feature version-gates properly instead of only checking presence.
# Source builds (DOTS_BUILD_FROM_SOURCE=1) have no ldflags and report
# version=unversioned, so that path keeps the presence check.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    if [ "${DOTS_FORCE:-0}" != "1" ] && command -v lazygit &>/dev/null; then
        echo "==> lazygit already installed, skipping"
        exit 0
    fi
    echo "==> Building lazygit $LAZYGIT_VERSION from source..."
    go install "github.com/jesseduffield/lazygit@v${LAZYGIT_VERSION}"
    echo "==> lazygit $LAZYGIT_VERSION installed."
    exit 0
fi

if check_command_version lazygit "$LAZYGIT_VERSION"; then
    echo "==> lazygit $LAZYGIT_VERSION already installed, skipping"
    exit 0
fi

ARCH="$(map_arch x86_64 arm64)"
CACHE_KEY="lazygit/${LAZYGIT_VERSION}"
BASE="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}"
# Release asset names use a lowercase "linux" (unlike gum's "Linux").
ASSET="lazygit_${LAZYGIT_VERSION}_linux_${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing lazygit $LAZYGIT_VERSION..."
fetch_cached "$BASE/checksums.txt" "$CACHE_KEY/checksums.txt" "$TMP_FOLDER/checksums.txt"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/checksums.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from lazygit checksums.txt" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" lazygit
install_bin "$TMP_FOLDER/lazygit" lazygit

echo "==> lazygit $LAZYGIT_VERSION installed."
