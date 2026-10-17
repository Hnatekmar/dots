#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

NODE_VERSION=24.22.0

if check_command_version node "$NODE_VERSION"; then
    echo "==> node $NODE_VERSION already installed, skipping"
    exit 0
fi

# Node ships an official tarball with node, npm, npx and corepack. Install it
# under ~/.local/node; bootstrap.sh, .profile and .zshrc put its bin directory
# on PATH. Use .tar.gz (not .tar.xz) so no extra xz prerequisite is needed.
ARCH="$(map_arch x64 arm64)"
CACHE_KEY="node/${NODE_VERSION}"
ASSET="node-v${NODE_VERSION}-linux-${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing Node.js $NODE_VERSION..."
fetch_cached "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" \
    "$CACHE_KEY/SHASUMS256.txt" "$TMP_FOLDER/SHASUMS256.txt"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/SHASUMS256.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from Node.js SHASUMS256.txt" >&2; exit 1; }

fetch_cached "https://nodejs.org/dist/v${NODE_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER"

# Replace the old tree only after checksum verification and extraction.
rm -rf "$HOME/.local/node"
mv "$TMP_FOLDER/${ASSET%.tar.gz}" "$HOME/.local/node"

echo "==> node $NODE_VERSION installed to ~/.local/node."
