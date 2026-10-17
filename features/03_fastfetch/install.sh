#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

FASTFETCH_VERSION=2.70.0

if check_command_version fastfetch "$FASTFETCH_VERSION"; then
    echo "==> fastfetch $FASTFETCH_VERSION already installed, skipping"
    exit 0
fi

# Prebuilt tarball contains usr/bin/fastfetch plus presets. Install the binary
# and copy the presets under ~/.local/share/fastfetch for `--preset` support.
# Note the release's arm64 asset is named "aarch64", not "arm64".
ARCH="$(map_arch amd64 aarch64)"
CACHE_KEY="fastfetch/${FASTFETCH_VERSION}"
ASSET="fastfetch-linux-${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing fastfetch $FASTFETCH_VERSION..."
EXPECTED="$(require_asset_sha256 "$ASSET")"

fetch_cached "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER"
install_bin "$TMP_FOLDER/fastfetch-linux-${ARCH}/usr/bin/fastfetch" fastfetch

mkdir -p "$HOME/.local/share"
rm -rf "$HOME/.local/share/fastfetch"
cp -R "$TMP_FOLDER/fastfetch-linux-${ARCH}/usr/share/fastfetch" "$HOME/.local/share/fastfetch"

echo "==> fastfetch $FASTFETCH_VERSION installed."
