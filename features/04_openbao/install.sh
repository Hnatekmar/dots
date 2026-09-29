#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

OPENBAO_VERSION=2.6.1

# Detect architecture
ARCH="$(map_arch amd64 arm64)"

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
verify_sha256 "$TARBALL" "$EXPECTED"

tar -xzf "$TARBALL"

mkdir -p "$HOME/.local/bin"
cp bao "$HOME/.local/bin/"

echo "==> OpenBao $OPENBAO_VERSION installed."
