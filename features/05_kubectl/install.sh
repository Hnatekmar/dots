#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

KUBECTL_VERSION=1.37.1

if check_command_version kubectl "$KUBECTL_VERSION"; then
    echo "==> kubectl $KUBECTL_VERSION already installed, skipping"
    exit 0
fi

# kubectl is published on dl.k8s.io next to a .sha256 sidecar (the same pattern
# used by ripgrep). Building it from source is not practical, so this feature
# always installs the prebuilt binary.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="kubectl/${KUBECTL_VERSION}"
BASE="https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing kubectl $KUBECTL_VERSION..."
fetch_cached "$BASE/kubectl.sha256" "$CACHE_KEY/kubectl.sha256" "$TMP_FOLDER/kubectl.sha256"
EXPECTED=$(tr -d '[:space:]' < "$TMP_FOLDER/kubectl.sha256")
[ -n "$EXPECTED" ] || { echo "ERROR: empty checksum file for kubectl" >&2; exit 1; }

fetch_cached "$BASE/kubectl" "$CACHE_KEY/kubectl" "$TMP_FOLDER/kubectl" "$EXPECTED"
install_bin "$TMP_FOLDER/kubectl" kubectl

echo "==> kubectl $KUBECTL_VERSION installed."
