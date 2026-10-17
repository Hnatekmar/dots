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

TARBALL="nvim-linux-${ARCH}.tar.gz"
CACHE_KEY="neovim/${NEOVIM_VERSION}"

echo "==> Installing Neovim $NEOVIM_VERSION..."
# Neovim doesn't publish checksum files — the SHA256 comes from the GitHub
# release metadata, which is cached alongside the tarball.
fetch_cached "https://api.github.com/repos/neovim/neovim/releases/tags/v${NEOVIM_VERSION}" \
    "$CACHE_KEY/release.json" "$TMP_FOLDER/release.json"

EXPECTED=$(python3 -c '
import json, sys
with open(sys.argv[1]) as fh:
    data = json.load(fh)
for asset in data.get("assets", []):
    if asset["name"] == sys.argv[2]:
        digest = asset.get("digest") or ""
        if digest.startswith("sha256:"):
            print(digest[7:])
        break
' "$TMP_FOLDER/release.json" "$TARBALL")
[ -n "$EXPECTED" ] || { echo "ERROR: no sha256 digest for $TARBALL in neovim release metadata" >&2; exit 1; }

fetch_cached "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/${TARBALL}" \
    "$CACHE_KEY/${TARBALL}" "$TMP_FOLDER/${TARBALL}" "$EXPECTED"

# Download and verify succeeded — safe to remove old install
rm -rf "$HOME/.local/bin/nvim" "$HOME/.local/share/nvim" "$HOME/.local/lib/nvim"

mkdir -p "$HOME/.local"
tar -xzf "$TMP_FOLDER/$TARBALL" -C "$HOME/.local" --strip-components=1

echo "==> Neovim $NEOVIM_VERSION installed."
