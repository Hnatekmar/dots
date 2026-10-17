#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

RIPGREP_VERSION=15.2.0

if check_command_version rg "$RIPGREP_VERSION"; then
    echo "==> ripgrep $RIPGREP_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt musl binary: statically linked, so one asset works on Fedora, Debian
# and Arch. Releases ship a .sha256 sidecar next to every tarball.
# DOTS_BUILD_FROM_SOURCE=1 forces the old `cargo install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building ripgrep $RIPGREP_VERSION from source..."
    cargo install --locked "ripgrep@${RIPGREP_VERSION}"
    exit 0
fi

TARGET="$(map_arch x86_64-unknown-linux-musl aarch64-unknown-linux-musl)"
CACHE_KEY="ripgrep/${RIPGREP_VERSION}"
BASE="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}"
ASSET="ripgrep-${RIPGREP_VERSION}-${TARGET}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing ripgrep $RIPGREP_VERSION..."
fetch_cached "$BASE/${ASSET}.sha256" "$CACHE_KEY/${ASSET}.sha256" "$TMP_FOLDER/${ASSET}.sha256"
EXPECTED=$(cut -d' ' -f1 "$TMP_FOLDER/${ASSET}.sha256")
[ -n "$EXPECTED" ] || { echo "ERROR: empty checksum file for $ASSET" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" --strip-components=1
install_bin "$TMP_FOLDER/rg" rg

echo "==> ripgrep $RIPGREP_VERSION installed."
