#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

UV_VERSION=0.13.1

if check_command_version uv "$UV_VERSION"; then
    echo "==> uv $UV_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt release tarball; it contains both `uv` and `uvx`. astral-sh publishes
# a `.sha256` sidecar next to every asset, so no pinned digest is needed.
ARCH="$(map_arch x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu)"
CACHE_KEY="uv/${UV_VERSION}"
ASSET="uv-${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing uv $UV_VERSION..."
fetch_cached "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${ASSET}.sha256" \
    "$CACHE_KEY/${ASSET}.sha256" "$TMP_FOLDER/${ASSET}.sha256"
EXPECTED=$(cut -d' ' -f1 "$TMP_FOLDER/${ASSET}.sha256")
[ -n "$EXPECTED" ] || { echo "ERROR: empty checksum file for $ASSET" >&2; exit 1; }

fetch_cached "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER"
install_bin "$TMP_FOLDER/uv-${ARCH}/uv" uv
install_bin "$TMP_FOLDER/uv-${ARCH}/uvx" uvx

echo "==> uv $UV_VERSION installed."
