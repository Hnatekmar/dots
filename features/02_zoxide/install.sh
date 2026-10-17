#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

ZOXIDE_VERSION=0.10.0

if check_command_version zoxide "$ZOXIDE_VERSION"; then
    echo "==> zoxide $ZOXIDE_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt musl binary: statically linked, so one asset works on Fedora, Debian
# and Arch. zoxide publishes no checksum files, so the digest is pinned in
# features/checksums.txt.
# DOTS_BUILD_FROM_SOURCE=1 forces the old `cargo install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building zoxide $ZOXIDE_VERSION from source..."
    cargo install --locked "zoxide@${ZOXIDE_VERSION}"
    exit 0
fi

TARGET="$(map_arch x86_64-unknown-linux-musl aarch64-unknown-linux-musl)"
CACHE_KEY="zoxide/${ZOXIDE_VERSION}"
ASSET="zoxide-${ZOXIDE_VERSION}-${TARGET}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing zoxide $ZOXIDE_VERSION..."
EXPECTED="$(require_asset_sha256 "$ASSET")"

fetch_cached "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER"
install_bin "$TMP_FOLDER/zoxide" zoxide

echo "==> zoxide $ZOXIDE_VERSION installed."
