#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

KUBECONFORM_VERSION=0.8.0

if check_command_version kubeconform "$KUBECONFORM_VERSION"; then
    echo "==> kubeconform $KUBECONFORM_VERSION already installed, skipping"
    exit 0
fi

# The tarball holds the binary at the root; upstream's checksum file is named
# CHECKSUMS (no .txt). DOTS_BUILD_FROM_SOURCE=1 forces the `go install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building kubeconform $KUBECONFORM_VERSION from source..."
    go install "github.com/yannh/kubeconform/cmd/kubeconform@v${KUBECONFORM_VERSION}"
    exit 0
fi

ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="kubeconform/${KUBECONFORM_VERSION}"
BASE="https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}"
ASSET="kubeconform-linux-${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing kubeconform $KUBECONFORM_VERSION..."
fetch_cached "$BASE/CHECKSUMS" "$CACHE_KEY/CHECKSUMS" "$TMP_FOLDER/CHECKSUMS"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/CHECKSUMS")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from kubeconform CHECKSUMS" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" kubeconform
install_bin "$TMP_FOLDER/kubeconform" kubeconform

echo "==> kubeconform $KUBECONFORM_VERSION installed."
