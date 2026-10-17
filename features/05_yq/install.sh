#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

YQ_VERSION=4.54.1

if check_command_version yq "$YQ_VERSION"; then
    echo "==> yq $YQ_VERSION already installed, skipping"
    exit 0
fi

# DOTS_BUILD_FROM_SOURCE=1 forces the `go install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building yq $YQ_VERSION from source..."
    go install "github.com/mikefarah/yq/v4@v${YQ_VERSION}"
    exit 0
fi

# Prebuilt static binary. yq's `checksums` asset packs many algorithms into one
# line per file, so use the GitHub release metadata digest instead.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="yq/${YQ_VERSION}"
BASE="https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}"
ASSET="yq_linux_${ARCH}"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing yq $YQ_VERSION..."
fetch_cached "https://api.github.com/repos/mikefarah/yq/releases/tags/v${YQ_VERSION}" \
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
[ -n "$EXPECTED" ] || { echo "ERROR: no sha256 digest for $ASSET in yq release metadata" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
install_bin "$TMP_FOLDER/$ASSET" yq

echo "==> yq $YQ_VERSION installed."
