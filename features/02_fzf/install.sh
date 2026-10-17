#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

FZF_VERSION=0.74.5

if check_command_version fzf "$FZF_VERSION"; then
    echo "==> fzf $FZF_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt static binary: one linux asset covers Fedora, Debian and Arch.
# fzf publishes a checksums file covering every asset, so no pinned digest is
# needed and no GitHub API call is made.
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
fetch_cached "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf_${FZF_VERSION}_checksums.txt" \
    "$CACHE_KEY/checksums.txt" "$TMP_FOLDER/checksums.txt"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/checksums.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from fzf checksums file" >&2; exit 1; }

fetch_cached "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" fzf
install_bin "$TMP_FOLDER/fzf" fzf

echo "==> fzf $FZF_VERSION installed."
