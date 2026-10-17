#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

HELM_VERSION=4.3.1

if check_command_version helm "$HELM_VERSION"; then
    echo "==> helm $HELM_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt static binary from Helm's official download host. Helm publishes a
# `.sha256sum` sidecar next to each tarball (the GitHub release only carries
# signed .asc copies), so verification uses the sidecar.
# DOTS_BUILD_FROM_SOURCE=1 is not supported for Helm; use the release binary.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="helm/${HELM_VERSION}"
BASE="https://get.helm.sh"
ASSET="helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing helm $HELM_VERSION..."
fetch_cached "$BASE/${ASSET}.sha256sum" "$CACHE_KEY/${ASSET}.sha256sum" "$TMP_FOLDER/${ASSET}.sha256sum"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/${ASSET}.sha256sum")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from helm ${ASSET}.sha256sum" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" --strip-components=1
install_bin "$TMP_FOLDER/helm" helm

echo "==> helm $HELM_VERSION installed."
