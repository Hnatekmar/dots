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

# Neovim doesn't publish checksum files — fetch the SHA256 from the GitHub API
echo "==> Verifying checksum..."
EXPECTED=$(curl -sL "https://api.github.com/repos/neovim/neovim/releases/tags/v${NEOVIM_VERSION}" \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
for a in data.get('assets', []):
    if a['name'] == '${TARBALL}':
        digest = a.get('digest', '')
        if digest.startswith('sha256:'):
            print(digest[7:])
        break
")

if [ -z "$EXPECTED" ]; then
    echo "ERROR: Could not fetch Neovim checksum from GitHub API" >&2
    exit 1
fi

ACTUAL=$(sha256sum "$TARBALL" | cut -d' ' -f1)
if [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "ERROR: Checksum mismatch for $TARBALL" >&2
    echo "  Expected: $EXPECTED" >&2
    echo "  Actual:   $ACTUAL" >&2
    exit 1
fi

tar -xzf "$TARBALL" -C /usr/local --strip-components=1

echo "==> Neovim $NEOVIM_VERSION installed."
