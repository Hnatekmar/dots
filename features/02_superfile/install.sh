#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

SUPERFILE_VERSION=1.6.0

if check_command_version spf "$SUPERFILE_VERSION"; then
    echo "==> superfile $SUPERFILE_VERSION already installed, skipping"
    exit 0
fi

# superfile is a Go TUI file manager; the binary is named `spf`.
# DOTS_BUILD_FROM_SOURCE=1 forces the `go install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building superfile $SUPERFILE_VERSION from source..."
    go install "github.com/yorukot/superfile@v${SUPERFILE_VERSION}"
    exit 0
fi

# The linux tarballs ship under ./dist/<asset>/spf, and upstream publishes
# superfile-v<version>-checksums.txt next to them, so no pinned digest is needed.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="superfile/${SUPERFILE_VERSION}"
BASE="https://github.com/yorukot/superfile/releases/download/v${SUPERFILE_VERSION}"
ASSET="superfile-linux-v${SUPERFILE_VERSION}-${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing superfile $SUPERFILE_VERSION..."
fetch_cached "$BASE/superfile-v${SUPERFILE_VERSION}-checksums.txt" \
    "$CACHE_KEY/checksums.txt" "$TMP_FOLDER/checksums.txt"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/checksums.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from superfile checksums.txt" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

# Paths inside the archive are ./dist/<asset>/spf: three components to strip.
# The mac-built tarball carries libarchive xattr headers, which GNU tar warns
# about on stderr; they are harmless, so silence just that warning.
tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" --strip-components=3 \
    --warning=no-unknown-keyword
install_bin "$TMP_FOLDER/spf" spf

echo "==> superfile $SUPERFILE_VERSION installed."
