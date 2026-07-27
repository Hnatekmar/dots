#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

OPENBAO_VERSION=2.6.1

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH=amd64 ;;
    aarch64) ARCH=arm64 ;;
    *) echo "ERROR: Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

if check_command_version bao "$OPENBAO_VERSION"; then
    echo "==> openbao $OPENBAO_VERSION already installed, skipping"
    exit 0
fi

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

cd "$TMP_FOLDER"

TARBALL="openbao_${OPENBAO_VERSION}_linux_${ARCH}.tar.gz"

echo "==> Downloading OpenBao $OPENBAO_VERSION..."
curl -LO "https://github.com/openbao/openbao/releases/download/v${OPENBAO_VERSION}/${TARBALL}"
curl -LO "https://github.com/openbao/openbao/releases/download/v${OPENBAO_VERSION}/checksums.txt"

echo "==> Verifying checksum..."
sha256sum --ignore-missing --check checksums.txt

tar -xzf "$TARBALL"

cp bao /usr/local/bin/

echo "==> OpenBao $OPENBAO_VERSION installed."
