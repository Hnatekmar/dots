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
ARCH="$(map_arch amd64 arm64)"
CACHE_KEY="fastfetch/${FASTFETCH_VERSION}"
ASSET="fastfetch-linux-${ARCH}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing fastfetch $FASTFETCH_VERSION..."
fetch_cached "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/tags/${FASTFETCH_VERSION}" \
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
' "$TMP_FOLDER/release.json" "$ASSET")
[ -n "$EXPECTED" ] || { echo "ERROR: no sha256 digest for $ASSET in fastfetch release metadata" >&2; exit 1; }

fetch_cached "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/$ASSET" \
    "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER"
install_bin "$TMP_FOLDER/fastfetch-linux-${ARCH}/usr/bin/fastfetch" fastfetch

mkdir -p "$HOME/.local/share"
rm -rf "$HOME/.local/share/fastfetch"
cp -R "$TMP_FOLDER/fastfetch-linux-${ARCH}/usr/share/fastfetch" "$HOME/.local/share/fastfetch"

echo "==> fastfetch $FASTFETCH_VERSION installed."
