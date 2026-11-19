#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

ORAS_VERSION=1.4.0

if check_command_version oras "$ORAS_VERSION"; then
    echo "==> oras $ORAS_VERSION already installed, skipping"
    exit 0
fi

# oras tarballs hold the binary and LICENSE at the archive root, and the
# checksum file is named oras_<version>_checksums.txt (not checksums.txt).
# DOTS_BUILD_FROM_SOURCE=1 forces the `go install` path; the version is a
# constant in the tagged source, so the binary still reports 1.4.0 and the
# gate stays idempotent.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building oras $ORAS_VERSION from source..."
    go install "oras.land/oras/cmd/oras@v${ORAS_VERSION}"
    exit 0
fi

ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="oras/${ORAS_VERSION}"
BASE="https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}"
ASSET="oras_${ORAS_VERSION}_linux_${ARCH}.tar.gz"
SUMS="oras_${ORAS_VERSION}_checksums.txt"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing oras $ORAS_VERSION..."
fetch_cached "$BASE/$SUMS" "$CACHE_KEY/$SUMS" "$TMP_FOLDER/$SUMS"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/$SUMS")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from $SUMS" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" oras
install_bin "$TMP_FOLDER/oras" oras

echo "==> oras $ORAS_VERSION installed."
