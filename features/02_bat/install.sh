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
fetch_cached "https://api.github.com/repos/sharkdp/bat/releases/tags/v${BAT_VERSION}" \
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
[ -n "$EXPECTED" ] || { echo "ERROR: no sha256 digest for $ASSET in bat release metadata" >&2; exit 1; }

fetch_cached "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER"
install_bin "$TMP_FOLDER/bat-v${BAT_VERSION}-${ARCH}-unknown-linux-gnu/bat" bat

echo "==> bat $BAT_VERSION installed."
