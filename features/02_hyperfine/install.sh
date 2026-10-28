#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

HYPERFINE_VERSION=2.0.0

if check_command_version hyperfine "$HYPERFINE_VERSION"; then
    echo "==> hyperfine $HYPERFINE_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt musl binary: statically linked, so one asset works on Fedora, Debian
# and Arch. DOTS_BUILD_FROM_SOURCE=1 forces the old `cargo install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building hyperfine $HYPERFINE_VERSION from source..."
    cargo install --locked "hyperfine@${HYPERFINE_VERSION}"
    exit 0
fi

TARGET="$(map_arch x86_64-unknown-linux-musl aarch64-unknown-linux-musl)"
CACHE_KEY="hyperfine/${HYPERFINE_VERSION}"
ASSET="hyperfine-v${HYPERFINE_VERSION}-${TARGET}.tar.gz"

# hyperfine publishes no checksum files (like its sibling fd), so the digest is
# pinned in features/checksums.txt.
EXPECTED="$(require_asset_sha256 "$ASSET")"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing hyperfine $HYPERFINE_VERSION..."
fetch_cached "https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" --strip-components=1
install_bin "$TMP_FOLDER/hyperfine" hyperfine

echo "==> hyperfine $HYPERFINE_VERSION installed."
