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
# Pull the expected hash for our exact tarball out of checksums.txt. This fails
# hard if the tarball isn't listed (unlike `sha256sum --ignore-missing`, which
# would silently pass if the name ever stopped matching).
EXPECTED=$(awk -v f="$TARBALL" '$2 == f {print $1}' checksums.txt)
ACTUAL=$(sha256sum "$TARBALL" | cut -d' ' -f1)
if [ -z "$EXPECTED" ] || [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "ERROR: Checksum mismatch for $TARBALL" >&2
    echo "  Expected: ${EXPECTED:-<not listed in checksums.txt>}" >&2
    echo "  Actual:   $ACTUAL" >&2
    exit 1
fi

tar -xzf "$TARBALL"

cp bao /usr/local/bin/

echo "==> OpenBao $OPENBAO_VERSION installed."
