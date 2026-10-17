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

TARBALL="openbao_${OPENBAO_VERSION}_linux_${ARCH}.tar.gz"
CACHE_KEY="openbao/${OPENBAO_VERSION}"
BASE="https://github.com/openbao/openbao/releases/download/v${OPENBAO_VERSION}"

echo "==> Installing OpenBao $OPENBAO_VERSION..."
fetch_cached "$BASE/checksums.txt" "$CACHE_KEY/checksums.txt" "$TMP_FOLDER/checksums.txt"

# Pull the expected hash for our exact tarball out of checksums.txt. This fails
# hard if the tarball isn't listed (unlike `sha256sum --ignore-missing`, which
# would silently pass if the name ever stopped matching).
EXPECTED=$(awk -v f="$TARBALL" '$2 == f {print $1}' "$TMP_FOLDER/checksums.txt")
[ -n "$EXPECTED" ] || { echo "ERROR: $TARBALL missing from OpenBao checksums.txt" >&2; exit 1; }

fetch_cached "$BASE/$TARBALL" "$CACHE_KEY/$TARBALL" "$TMP_FOLDER/$TARBALL" "$EXPECTED"

tar -xzf "$TMP_FOLDER/$TARBALL" -C "$TMP_FOLDER"
install_bin "$TMP_FOLDER/bao" bao

echo "==> OpenBao $OPENBAO_VERSION installed."
