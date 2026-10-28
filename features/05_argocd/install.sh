#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

ARGOCD_VERSION=3.5.6

if check_command_version argocd "$ARGOCD_VERSION"; then
    echo "==> argocd $ARGOCD_VERSION already installed, skipping"
    exit 0
fi

# Argo CD publishes the CLI as a bare binary plus one cli_checksums.txt for
# every platform. It is a big binary (~250 MB) — the Kubernetes client library
# dominates — so building from source is not offered.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="argocd/${ARGOCD_VERSION}"
BASE="https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}"
ASSET="argocd-linux-${ARCH}"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing argocd $ARGOCD_VERSION..."
fetch_cached "$BASE/cli_checksums.txt" "$CACHE_KEY/cli_checksums.txt" "$TMP_FOLDER/cli_checksums.txt"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/cli_checksums.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from argocd cli_checksums.txt" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
install_bin "$TMP_FOLDER/$ASSET" argocd

echo "==> argocd $ARGOCD_VERSION installed."
