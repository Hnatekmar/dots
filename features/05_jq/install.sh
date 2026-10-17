#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

JQ_VERSION=1.8.2

if check_command_version jq "$JQ_VERSION"; then
    echo "==> jq $JQ_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt static binary plus the release's sha256sum.txt. jq is a C project,
# so there is no Go/Rust source fallback.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="jq/${JQ_VERSION}"
BASE="https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}"
ASSET="jq-linux-${ARCH}"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing jq $JQ_VERSION..."
fetch_cached "$BASE/sha256sum.txt" "$CACHE_KEY/sha256sum.txt" "$TMP_FOLDER/sha256sum.txt"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/sha256sum.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from jq sha256sum.txt" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
install_bin "$TMP_FOLDER/$ASSET" jq

echo "==> jq $JQ_VERSION installed."
