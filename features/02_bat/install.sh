#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

BAT_VERSION=0.26.1

if check_command_version bat "$BAT_VERSION"; then
    echo "==> bat $BAT_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt gnu tarball. bat is a Rust project; the release binary is the
# supported install path (no cargo fallback).
ARCH="$(map_arch x86_64 aarch64)"
CACHE_KEY="bat/${BAT_VERSION}"
ASSET="bat-v${BAT_VERSION}-${ARCH}-unknown-linux-gnu.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing bat $BAT_VERSION..."
EXPECTED="$(require_asset_sha256 "$ASSET")"

fetch_cached "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER"
install_bin "$TMP_FOLDER/bat-v${BAT_VERSION}-${ARCH}-unknown-linux-gnu/bat" bat

echo "==> bat $BAT_VERSION installed."
