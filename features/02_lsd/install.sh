#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

LSD_VERSION=1.2.0

if check_command_version lsd "$LSD_VERSION"; then
    echo "==> lsd $LSD_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt musl binary: statically linked, so one asset works on Fedora, Debian
# and Arch. lsd publishes no checksum files, so the digest is pinned in
# features/checksums.txt.
# DOTS_BUILD_FROM_SOURCE=1 forces the old `cargo install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building lsd $LSD_VERSION from source..."
    cargo install --locked "lsd@${LSD_VERSION}"
    exit 0
fi

TARGET="$(map_arch x86_64-unknown-linux-musl aarch64-unknown-linux-musl)"
CACHE_KEY="lsd/${LSD_VERSION}"
ASSET="lsd-v${LSD_VERSION}-${TARGET}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing lsd $LSD_VERSION..."
EXPECTED="$(require_asset_sha256 "$ASSET")"

fetch_cached "https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" --strip-components=1
install_bin "$TMP_FOLDER/lsd" lsd

echo "==> lsd $LSD_VERSION installed."
