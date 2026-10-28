#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

TALOSCTL_VERSION=1.14.5

if check_command_version talosctl "$TALOSCTL_VERSION"; then
    echo "==> talosctl $TALOSCTL_VERSION already installed, skipping"
    exit 0
fi

# talosctl is a bare binary verified against the release's sha256sum.txt.
# It must track the cluster's Talos version closely: kubectl access goes
# through the credential-free kubeconfig, but node-level operations (dmesg,
# etcd, logs, upgrade) need a matching client.
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="talosctl/${TALOSCTL_VERSION}"
BASE="https://github.com/siderolabs/talos/releases/download/v${TALOSCTL_VERSION}"
ASSET="talosctl-linux-${ARCH}"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing talosctl $TALOSCTL_VERSION..."
fetch_cached "$BASE/sha256sum.txt" "$CACHE_KEY/sha256sum.txt" "$TMP_FOLDER/sha256sum.txt"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/sha256sum.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from talos sha256sum.txt" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
install_bin "$TMP_FOLDER/$ASSET" talosctl

echo "==> talosctl $TALOSCTL_VERSION installed."
