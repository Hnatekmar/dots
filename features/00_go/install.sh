#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

GO_VERSION=1.26.5

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH=amd64 ;;
    aarch64) ARCH=arm64 ;;
    *) echo "ERROR: Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

if check_command_version go "$GO_VERSION"; then
    echo "==> go $GO_VERSION already installed, skipping"
    exit 0
fi

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

cd "$TMP_FOLDER"

TARBALL="go${GO_VERSION}.linux-${ARCH}.tar.gz"

echo "==> Downloading Go $GO_VERSION..."
curl -LO "https://go.dev/dl/${TARBALL}"
curl -LO "https://go.dev/dl/${TARBALL}.sha256"

echo "==> Verifying checksum..."
sha256sum --ignore-missing --check "${TARBALL}.sha256"

# Download and verify succeeded — safe to remove old install
rm -rf /usr/local/go

tar -xzf "$TARBALL" -C /usr/local

echo "==> Go $GO_VERSION installed."
