#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

NEOVIM_VERSION="0.12.4"

# Detect architecture
ARCH="$(map_arch x86_64 arm64)"

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

verify_sha256 "$TARBALL" "$EXPECTED"

# Download and verify succeeded — safe to remove old install
rm -rf "$HOME/.local/bin/nvim" "$HOME/.local/share/nvim" "$HOME/.local/lib/nvim"

mkdir -p "$HOME/.local"
tar -xzf "$TARBALL" -C "$HOME/.local" --strip-components=1

echo "==> Neovim $NEOVIM_VERSION installed."
