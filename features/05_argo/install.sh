#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

ARGO_VERSION=4.1.6

if check_command_version argo "$ARGO_VERSION"; then
    echo "==> argo $ARGO_VERSION already installed, skipping"
    exit 0
fi

# Argo Workflows ships its CLI gzipped: argo-linux-<arch>.gz next to
# argo-workflows-cli-checksums.txt. Building it from source is a ~200 MB Go
# binary, so only the release artifact is supported.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="argo/${ARGO_VERSION}"
BASE="https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_VERSION}"
ASSET="argo-linux-${ARCH}.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing argo $ARGO_VERSION..."
fetch_cached "$BASE/argo-workflows-cli-checksums.txt" \
    "$CACHE_KEY/argo-workflows-cli-checksums.txt" "$TMP_FOLDER/argo-workflows-cli-checksums.txt"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/argo-workflows-cli-checksums.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from argo-workflows-cli-checksums.txt" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
gunzip -f "$TMP_FOLDER/$ASSET"
install_bin "${TMP_FOLDER}/${ASSET%.gz}" argo

echo "==> argo $ARGO_VERSION installed."
