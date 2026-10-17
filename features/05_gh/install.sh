#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

GH_VERSION=2.102.0

if check_command_version gh "$GH_VERSION"; then
    echo "==> gh $GH_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt GitHub CLI tarball plus the release checksums file.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="gh/${GH_VERSION}"
BASE="https://github.com/cli/cli/releases/download/v${GH_VERSION}"
ASSET="gh_${GH_VERSION}_linux_${ARCH}.tar.gz"
SUMS="gh_${GH_VERSION}_checksums.txt"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing gh $GH_VERSION..."
fetch_cached "$BASE/$SUMS" "$CACHE_KEY/$SUMS" "$TMP_FOLDER/$SUMS"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/$SUMS")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from $SUMS" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER"
install_bin "$TMP_FOLDER/gh_${GH_VERSION}_linux_${ARCH}/bin/gh" gh

echo "==> gh $GH_VERSION installed."
