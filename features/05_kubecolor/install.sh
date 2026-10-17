#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

KUBECOLOR_VERSION=0.8.0

# `--kubecolor-version` reports kubecolor's own version without invoking
# kubectl, so this works even before the 05_kubectl feature has run.
if check_command_version kubecolor "$KUBECOLOR_VERSION"; then
    echo "==> kubecolor $KUBECOLOR_VERSION already installed, skipping"
    exit 0
fi

# DOTS_BUILD_FROM_SOURCE=1 forces the `go install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building kubecolor $KUBECOLOR_VERSION from source..."
    go install "github.com/kubecolor/kubecolor@v${KUBECOLOR_VERSION}"
    exit 0
fi

ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="kubecolor/${KUBECOLOR_VERSION}"
BASE="https://github.com/kubecolor/kubecolor/releases/download/v${KUBECOLOR_VERSION}"
ASSET="kubecolor_${KUBECOLOR_VERSION}_linux_${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing kubecolor $KUBECOLOR_VERSION..."
fetch_cached "$BASE/checksums.txt" "$CACHE_KEY/checksums.txt" "$TMP_FOLDER/checksums.txt"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/checksums.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from kubecolor checksums.txt" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" kubecolor
install_bin "$TMP_FOLDER/kubecolor" kubecolor

echo "==> kubecolor $KUBECOLOR_VERSION installed."
