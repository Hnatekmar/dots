#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

KUBECTX_VERSION=0.11.0

# Both binaries are versioned together, so gate on both: a missing kubens must
# trigger a reinstall rather than silently skipping the feature.
if check_command_version kubectx "$KUBECTX_VERSION" &&
    check_command_version kubens "$KUBECTX_VERSION"; then
    echo "==> kubectx/kubens $KUBECTX_VERSION already installed, skipping"
    exit 0
fi

ARCH="$(map_arch x86_64 arm64)"
CACHE_KEY="kubectx/${KUBECTX_VERSION}"
BASE="https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}"
SUMS="checksums.txt"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing kubectx and kubens $KUBECTX_VERSION..."
fetch_cached "$BASE/$SUMS" "$CACHE_KEY/$SUMS" "$TMP_FOLDER/$SUMS"

for tool in kubectx kubens; do
    ASSET="${tool}_v${KUBECTX_VERSION}_linux_${ARCH}.tar.gz"
    EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/$SUMS")
    [ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from $SUMS" >&2; exit 1; }

    fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
    mkdir -p "$TMP_FOLDER/$tool"
    tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER/$tool"
    install_bin "$TMP_FOLDER/$tool/$tool" "$tool"
done

echo "==> kubectx and kubens $KUBECTX_VERSION installed."
