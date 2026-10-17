#!/bin/bash
set -euo pipefail

# Add or refresh pinned digests in features/checksums.txt.
#
#   scripts/add-checksum.sh <asset-url> [<asset-url> ...]
#
# Use this when bumping a version whose upstream publishes no checksum file:
# the installer refuses to run until the asset is listed, and prints this
# command. Works without the GitHub API — the asset URL is downloaded directly.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/features/checksums.txt"

if [ $# -eq 0 ]; then
    echo "usage: $0 <asset-url> [<asset-url> ...]" >&2
    exit 1
fi

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

touch "$MANIFEST"

for url in "$@"; do
    name="$(basename "$url")"
    echo "==> $name"
    curl -fsSL --retry 3 --retry-delay 2 -o "$TMP_FOLDER/$name" "$url"
    digest="$(sha256sum "$TMP_FOLDER/$name" | cut -d' ' -f1)"

    if grep -qE "^[0-9a-f]{64}  ${name//./\\.}\$" "$MANIFEST"; then
        sed -i "s|^[0-9a-f]\{64\}  ${name//./\\.}\$|$digest  $name|" "$MANIFEST"
        echo "    updated $digest"
    else
        printf '%s  %s\n' "$digest" "$name" >> "$MANIFEST"
        echo "    added $digest"
    fi
done

# Keep the file sorted by asset name, so diffs stay readable.
sort -k2 -o "$MANIFEST" "$MANIFEST"
echo "==> Updated $MANIFEST"
