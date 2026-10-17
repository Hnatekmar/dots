#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

HUNK_VERSION=0.23.0

# Hunk is a Bun/TypeScript application whose upstream source build needs Bun,
# which this repo does not provision. Always use the standalone release binary;
# DOTS_BUILD_FROM_SOURCE only applies to the Go/Rust features.
#
# git integration: per Hunk's docs, `hunk pager` inspects stdin, renders patches
# in the review UI, and falls back to a plain text pager for non-diff output.
configure_git_pager() {
    local current
    current="$(git config --global --get core.pager || true)"
    if [ "$current" = "hunk pager" ]; then
        echo "==> git core.pager already set to 'hunk pager', skipping"
        return 0
    fi
    git config --global core.pager "hunk pager"
    echo "==> git core.pager set to 'hunk pager' (git diff/show open in Hunk)"
}

echo "==> Configuring git to use Hunk for diffs..."
configure_git_pager

if check_command_version hunk "$HUNK_VERSION"; then
    echo "==> hunk $HUNK_VERSION already installed, skipping"
    exit 0
fi

PLATFORM="$(map_arch x64 arm64)"
CACHE_KEY="hunk/${HUNK_VERSION}"
ASSET="hunkdiff-linux-${PLATFORM}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing hunk $HUNK_VERSION..."
fetch_cached "https://api.github.com/repos/modem-dev/hunk/releases/tags/v${HUNK_VERSION}" \
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
[ -n "$EXPECTED" ] || { echo "ERROR: no sha256 digest for $ASSET in hunk release metadata" >&2; exit 1; }

fetch_cached "https://github.com/modem-dev/hunk/releases/download/v${HUNK_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" --strip-components=1
install_bin "$TMP_FOLDER/hunk" hunk

echo "==> hunk $HUNK_VERSION installed."
