#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

TOFU_VERSION=1.13.1

if check_command_version tofu "$TOFU_VERSION"; then
    echo "==> opentofu $TOFU_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt tarball with the release's SHA256SUMS file.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="opentofu/${TOFU_VERSION}"
BASE="https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}"
ASSET="tofu_${TOFU_VERSION}_linux_${ARCH}.tar.gz"
SUMS="tofu_${TOFU_VERSION}_SHA256SUMS"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing OpenTofu $TOFU_VERSION..."
fetch_cached "$BASE/$SUMS" "$CACHE_KEY/$SUMS" "$TMP_FOLDER/$SUMS"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/$SUMS")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from $SUMS" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER"
install_bin "$TMP_FOLDER/tofu" tofu

echo "==> OpenTofu $TOFU_VERSION installed."
