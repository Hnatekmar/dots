#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

YQ_VERSION=4.54.1

if check_command_version yq "$YQ_VERSION"; then
    echo "==> yq $YQ_VERSION already installed, skipping"
    exit 0
fi

# DOTS_BUILD_FROM_SOURCE=1 forces the `go install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building yq $YQ_VERSION from source..."
    go install "github.com/mikefarah/yq/v4@v${YQ_VERSION}"
    exit 0
fi

# Prebuilt static binary. yq's `checksums` asset packs many algorithms into one
# line per file and is not reliably parseable, so the digest is pinned in
# features/checksums.txt.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="yq/${YQ_VERSION}"
BASE="https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}"
ASSET="yq_linux_${ARCH}"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing yq $YQ_VERSION..."
EXPECTED="$(require_asset_sha256 "$ASSET")"

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
install_bin "$TMP_FOLDER/$ASSET" yq

echo "==> yq $YQ_VERSION installed."
