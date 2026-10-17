#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

DIRENV_VERSION=2.38.2

if check_command_version direnv "$DIRENV_VERSION"; then
    echo "==> direnv $DIRENV_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt static binary. direnv is a Go project, but the release binary is
# small and reliable, so there is no source fallback.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="direnv/${DIRENV_VERSION}"
ASSET="direnv.linux-${ARCH}"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing direnv $DIRENV_VERSION..."
fetch_cached "https://api.github.com/repos/direnv/direnv/releases/tags/v${DIRENV_VERSION}" \
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
[ -n "$EXPECTED" ] || { echo "ERROR: no sha256 digest for $ASSET in direnv release metadata" >&2; exit 1; }

fetch_cached "https://github.com/direnv/direnv/releases/download/v${DIRENV_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
install_bin "$TMP_FOLDER/$ASSET" direnv

echo "==> direnv $DIRENV_VERSION installed."
