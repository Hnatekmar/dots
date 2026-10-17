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

# herdr ships a bare executable per platform (no tarball, no checksums file),
# so the digest comes from the GitHub release metadata.
PLATFORM="$(map_arch x86_64 aarch64)"
CACHE_KEY="herdr/${HERDR_VERSION}"
ASSET="herdr-linux-${PLATFORM}"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing herdr $HERDR_VERSION..."
fetch_cached "https://api.github.com/repos/herdrdev/herdr/releases/tags/v${HERDR_VERSION}" \
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
[ -n "$EXPECTED" ] || { echo "ERROR: no sha256 digest for $ASSET in herdr release metadata" >&2; exit 1; }

fetch_cached "https://github.com/herdrdev/herdr/releases/download/v${HERDR_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

install_bin "$TMP_FOLDER/$ASSET" herdr

echo "==> herdr $HERDR_VERSION installed."
