#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

STERN_VERSION=1.35.0

if check_command_version stern "$STERN_VERSION"; then
    echo "==> stern $STERN_VERSION already installed, skipping"
    exit 0
fi

# stern tarballs hold the binary at the archive root. DOTS_BUILD_FROM_SOURCE=1
# forces the `go install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building stern $STERN_VERSION from source..."
    go install "github.com/stern/stern@v${STERN_VERSION}"
    exit 0
fi

ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="stern/${STERN_VERSION}"
BASE="https://github.com/stern/stern/releases/download/v${STERN_VERSION}"
ASSET="stern_${STERN_VERSION}_linux_${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing stern $STERN_VERSION..."
fetch_cached "$BASE/checksums.txt" "$CACHE_KEY/checksums.txt" "$TMP_FOLDER/checksums.txt"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/checksums.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from stern checksums.txt" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" stern
install_bin "$TMP_FOLDER/stern" stern

echo "==> stern $STERN_VERSION installed."
