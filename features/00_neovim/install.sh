#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

NEOVIM_VERSION="0.12.4"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH=x86_64 ;;
    aarch64) ARCH=arm64 ;;
    *) echo "ERROR: Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

if check_command_version nvim "$NEOVIM_VERSION"; then
    echo "==> nvim $NEOVIM_VERSION already installed, skipping"
    exit 0
fi

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

cd "$TMP_FOLDER"

TARBALL="nvim-linux-${ARCH}.tar.gz"

echo "==> Downloading Neovim $NEOVIM_VERSION..."
curl -LO "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/${TARBALL}"

echo "==> Verifying checksum..."
CHECKSUM_URL="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/${TARBALL}.sha256sum"
curl -sLO "$CHECKSUM_URL"
# The sha256sum file contains the tarball filename — verify in place
sha256sum --ignore-missing --check "${TARBALL}.sha256sum" || {
    # Neovim publishes SHA256 without the tarball name; fall back to manual check
    EXPECTED=$(cut -d' ' -f1 < "${TARBALL}.sha256sum")
    ACTUAL=$(sha256sum "$TARBALL" | cut -d' ' -f1)
    [ "$EXPECTED" = "$ACTUAL" ] || { echo "ERROR: Checksum mismatch" >&2; exit 1; }
}

tar -xzf "$TARBALL" -C /usr/local --strip-components=1

echo "==> Neovim $NEOVIM_VERSION installed."
