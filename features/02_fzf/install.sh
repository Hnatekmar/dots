#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

FZF_VERSION=0.74.5

if check_command_version fzf "$FZF_VERSION"; then
    echo "==> fzf $FZF_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt static binary: one linux asset covers Fedora, Debian and Arch.
# fzf publishes a checksums file, but its name ("fzf_<ver>_checksums.txt")
# differs from every asset it lists, so the digest comes from the GitHub
# release metadata instead (same approach as fd and Neovim).
# DOTS_BUILD_FROM_SOURCE=1 forces the old `go install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building fzf $FZF_VERSION from source..."
    go install "github.com/junegunn/fzf@v${FZF_VERSION}"
    exit 0
fi

ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="fzf/${FZF_VERSION}"
ASSET="fzf-${FZF_VERSION}-linux_${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing fzf $FZF_VERSION..."
fetch_cached "https://api.github.com/repos/junegunn/fzf/releases/tags/v${FZF_VERSION}" \
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
[ -n "$EXPECTED" ] || { echo "ERROR: no sha256 digest for $ASSET in fzf release metadata" >&2; exit 1; }

fetch_cached "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" fzf
install_bin "$TMP_FOLDER/fzf" fzf

echo "==> fzf $FZF_VERSION installed."
