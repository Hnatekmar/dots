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

# Go publishes SHA256 via their JSON API, not as a downloadable file
echo "==> Verifying checksum..."
EXPECTED=$(curl -sL "https://go.dev/dl/?mode=json&include=all" \
    | python3 -c "
import json, sys
for r in json.load(sys.stdin):
    if r['version'] == 'go${GO_VERSION}':
        for f in r['files']:
            if f['os'] == 'linux' and f['arch'] == '${ARCH}':
                print(f['sha256'])
                break
        break
")

if [ -z "$EXPECTED" ]; then
    echo "ERROR: Could not fetch Go checksum" >&2
    exit 1
fi

ACTUAL=$(sha256sum "$TARBALL" | cut -d' ' -f1)
if [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "ERROR: Checksum mismatch for $TARBALL" >&2
    echo "  Expected: $EXPECTED" >&2
    echo "  Actual:   $ACTUAL" >&2
    exit 1
fi

# Download and verify succeeded — safe to remove old install
rm -rf /usr/local/go

tar -xzf "$TARBALL" -C /usr/local

echo "==> Go $GO_VERSION installed."
