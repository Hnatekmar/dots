#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

GLOW_VERSION=3.0.0

if check_command_version glow "$GLOW_VERSION"; then
    echo "==> glow $GLOW_VERSION already installed, skipping"
    exit 0
fi

# Charm's tarballs wrap everything in a versioned directory; only the binary
# is unpacked. DOTS_BUILD_FROM_SOURCE=1 forces the `go install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building glow $GLOW_VERSION from source..."
    # v3 moved off the GitHub module path.
    go install "charm.land/glow/v3@v${GLOW_VERSION}"
    exit 0
fi

ARCH="$(map_arch x86_64 arm64)"
CACHE_KEY="glow/${GLOW_VERSION}"
BASE="https://github.com/charmbracelet/glow/releases/download/v${GLOW_VERSION}"
ASSET="glow_${GLOW_VERSION}_Linux_${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing glow $GLOW_VERSION..."
fetch_cached "$BASE/checksums.txt" "$CACHE_KEY/checksums.txt" "$TMP_FOLDER/checksums.txt"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/checksums.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from glow checksums.txt" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" --strip-components=1 \
    "glow_${GLOW_VERSION}_Linux_${ARCH}/glow"
install_bin "$TMP_FOLDER/glow" glow

echo "==> glow $GLOW_VERSION installed."
