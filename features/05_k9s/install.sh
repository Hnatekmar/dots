#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

K9S_VERSION=0.51.0

if check_command_version k9s "$K9S_VERSION"; then
    echo "==> k9s $K9S_VERSION already installed, skipping"
    exit 0
fi

# DOTS_BUILD_FROM_SOURCE=1 forces the `go install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building k9s $K9S_VERSION from source..."
    go install "github.com/derailed/k9s@v${K9S_VERSION}"
    exit 0
fi

ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="k9s/${K9S_VERSION}"
BASE="https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}"
ASSET="k9s_Linux_${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing k9s $K9S_VERSION..."
fetch_cached "$BASE/checksums.sha256" "$CACHE_KEY/checksums.sha256" "$TMP_FOLDER/checksums.sha256"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/checksums.sha256")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from k9s checksums.sha256" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" k9s
install_bin "$TMP_FOLDER/k9s" k9s

echo "==> k9s $K9S_VERSION installed."
