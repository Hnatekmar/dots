#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

GO_VERSION=1.26.5

# Detect architecture
ARCH="$(map_arch amd64 arm64)"

if check_command_version go "$GO_VERSION"; then
    echo "==> go $GO_VERSION already installed, skipping"
    exit 0
fi

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

TARBALL="go${GO_VERSION}.linux-${ARCH}.tar.gz"
CACHE_KEY="go/${GO_VERSION}"

echo "==> Installing Go $GO_VERSION..."
# Go publishes SHA256 via their JSON API, not as a downloadable file.
fetch_cached "https://go.dev/dl/?mode=json&include=all" \
    "$CACHE_KEY/index.json" "$TMP_FOLDER/index.json"

EXPECTED=$(python3 -c '
import json, sys
with open(sys.argv[1]) as fh:
    releases = json.load(fh)
want = "go" + sys.argv[2]
for release in releases:
    if release["version"] == want:
        for entry in release["files"]:
            if entry["os"] == "linux" and entry["arch"] == sys.argv[3]:
                print(entry["sha256"])
        break
' "$TMP_FOLDER/index.json" "$GO_VERSION" "$ARCH")
[ -n "$EXPECTED" ] || { echo "ERROR: no sha256 for $TARBALL in go.dev release index" >&2; exit 1; }

fetch_cached "https://go.dev/dl/${TARBALL}" "$CACHE_KEY/${TARBALL}" "$TMP_FOLDER/${TARBALL}" "$EXPECTED"

# Download and verify succeeded — safe to remove old install
rm -rf "$HOME/.local/go"

mkdir -p "$HOME/.local"
tar -xzf "$TMP_FOLDER/$TARBALL" -C "$HOME/.local"

echo "==> Go $GO_VERSION installed."
