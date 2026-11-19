#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

KUBELOGIN_VERSION=1.36.4

if check_command_version kubelogin "$KUBELOGIN_VERSION"; then
    echo "==> kubelogin $KUBELOGIN_VERSION already installed, skipping"
    exit 0
fi

# The devops-cluster kubeconfigs exec `kubelogin get-token
# --oidc-issuer-url=...`, so this must be int128/kubelogin (OIDC). Do not
# install Azure/kubelogin: it shares the binary name but only handles AAD and
# rejects --oidc-issuer-url with "unknown flag".
# The release zip ships its own .sha256 sidecar.
ARCH="$(map_arch amd64 arm64)"
ASSET="kubelogin_linux_${ARCH}.zip"
CACHE_KEY="kubelogin/${KUBELOGIN_VERSION}"
BASE="https://github.com/int128/kubelogin/releases/download/v${KUBELOGIN_VERSION}"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing kubelogin $KUBELOGIN_VERSION..."
fetch_cached "$BASE/$ASSET.sha256" "$CACHE_KEY/$ASSET.sha256" "$TMP_FOLDER/$ASSET.sha256"
EXPECTED=$(awk '{print $1}' "$TMP_FOLDER/$ASSET.sha256")
[ -n "$EXPECTED" ] || { echo "ERROR: empty checksum file for kubelogin" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

# python3 is a bootstrap prerequisite; unzip is not.
python3 -m zipfile -e "$TMP_FOLDER/$ASSET" "$TMP_FOLDER/out"
install_bin "$TMP_FOLDER/out/kubelogin" kubelogin

echo "==> kubelogin $KUBELOGIN_VERSION installed."
