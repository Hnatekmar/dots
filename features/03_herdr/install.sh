#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

HERDR_VERSION=0.9.5

if check_command_version herdr "$HERDR_VERSION"; then
    echo "==> herdr $HERDR_VERSION already installed, skipping"
    exit 0
fi

# herdr is not published on crates.io at this version, so the source fallback
# clones the pinned tag and builds the workspace directly.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    TMP_FOLDER=$(mktemp -d)
    trap 'rm -rf "$TMP_FOLDER"' EXIT
    echo "==> Building herdr $HERDR_VERSION from source..."
    git clone --depth 1 --branch "v${HERDR_VERSION}" \
        https://github.com/herdrdev/herdr.git "$TMP_FOLDER/herdr"
    cargo build --release --locked --manifest-path "$TMP_FOLDER/herdr/Cargo.toml"
    install_bin "$TMP_FOLDER/herdr/target/release/herdr" herdr
    echo "==> herdr $HERDR_VERSION installed."
    exit 0
fi

# herdr ships a bare executable per platform (no tarball, no checksums file), so
# the digest is pinned in features/checksums.txt.
PLATFORM="$(map_arch x86_64 aarch64)"
CACHE_KEY="herdr/${HERDR_VERSION}"
ASSET="herdr-linux-${PLATFORM}"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing herdr $HERDR_VERSION..."
EXPECTED="$(require_asset_sha256 "$ASSET")"

fetch_cached "https://github.com/herdrdev/herdr/releases/download/v${HERDR_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

install_bin "$TMP_FOLDER/$ASSET" herdr

echo "==> herdr $HERDR_VERSION installed."
