#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

GUM_VERSION=0.16.2

if check_command_version gum "$GUM_VERSION"; then
    echo "==> gum $GUM_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt release tarball: goreleaser publishes one per arch plus
# checksums.txt. gum is pure Go, so the binary is static and distro-agnostic.
# DOTS_BUILD_FROM_SOURCE=1 forces the old `go install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building gum $GUM_VERSION from source..."
    go install "github.com/charmbracelet/gum@v${GUM_VERSION}"
    exit 0
fi

ARCH="$(map_arch x86_64 arm64)"
CACHE_KEY="gum/${GUM_VERSION}"
BASE="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}"
ASSET="gum_${GUM_VERSION}_Linux_${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing gum $GUM_VERSION..."
fetch_cached "$BASE/checksums.txt" "$CACHE_KEY/checksums.txt" "$TMP_FOLDER/checksums.txt"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/checksums.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from gum checksums.txt" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" --strip-components=1
install_bin "$TMP_FOLDER/gum" gum

echo "==> gum $GUM_VERSION installed."
