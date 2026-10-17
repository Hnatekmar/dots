#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

ZOXIDE_VERSION=0.10.0

if check_command_version zoxide "$ZOXIDE_VERSION"; then
    echo "==> zoxide $ZOXIDE_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt musl binary: statically linked, so one asset works on Fedora, Debian
# and Arch. zoxide publishes no checksum files, so the digest comes from the
# GitHub release metadata (same approach as fd and Neovim).
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
fetch_cached "https://api.github.com/repos/ajeetdsouza/zoxide/releases/tags/v${ZOXIDE_VERSION}" \
    "$CACHE_KEY/release.json" "$TMP_FOLDER/release.json"

EXPECTED=$(python3 -c '
import json, sys
with open(sys.argv[1]) as fh:
    data = json.load(fh)
for asset in data.get("assets", []):
    if asset["name"] == sys.argv[2]:
        digest = asset.get("digest") or ""
        if digest.startswith("sha256:"):
            print(digest[7:])
        break
' "$TMP_FOLDER/release.json" "$ASSET")
[ -n "$EXPECTED" ] || { echo "ERROR: no sha256 digest for $ASSET in zoxide release metadata" >&2; exit 1; }

fetch_cached "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER"
install_bin "$TMP_FOLDER/zoxide" zoxide

echo "==> zoxide $ZOXIDE_VERSION installed."
