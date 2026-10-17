#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

FD_VERSION=10.4.2

if check_command_version fd "$FD_VERSION"; then
    echo "==> fd $FD_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt musl binary: statically linked, so one asset works on Fedora, Debian
# and Arch.
# DOTS_BUILD_FROM_SOURCE=1 forces the old `cargo install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building fd $FD_VERSION from source..."
    cargo install --locked "fd-find@${FD_VERSION}"
    exit 0
fi

TARGET="$(map_arch x86_64-unknown-linux-musl aarch64-unknown-linux-musl)"
CACHE_KEY="fd/${FD_VERSION}"
ASSET="fd-v${FD_VERSION}-${TARGET}.tar.gz"

# fd publishes no checksum files, so the digest is pinned in
# features/checksums.txt (keyed by asset name, which carries the target).
EXPECTED="$(require_asset_sha256 "$ASSET")"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing fd $FD_VERSION..."
fetch_cached "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" --strip-components=1
install_bin "$TMP_FOLDER/fd" fd

echo "==> fd $FD_VERSION installed."
