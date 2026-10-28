#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

JUST_VERSION=1.59.0

if check_command_version just "$JUST_VERSION"; then
    echo "==> just $JUST_VERSION already installed, skipping"
    exit 0
fi

# just's tarball also carries the Rust sources and docs; only the binary is
# unpacked. DOTS_BUILD_FROM_SOURCE=1 forces the `cargo install` path.
if [ "${DOTS_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    echo "==> Building just $JUST_VERSION from source..."
    cargo install --locked "just@${JUST_VERSION}"
    exit 0
fi

TARGET="$(map_arch x86_64-unknown-linux-musl aarch64-unknown-linux-musl)"
CACHE_KEY="just/${JUST_VERSION}"
BASE="https://github.com/casey/just/releases/download/${JUST_VERSION}"
ASSET="just-${JUST_VERSION}-${TARGET}.tar.gz"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing just $JUST_VERSION..."
fetch_cached "$BASE/SHA256SUMS" "$CACHE_KEY/SHA256SUMS" "$TMP_FOLDER/SHA256SUMS"
EXPECTED=$(awk -v f="$ASSET" '$2 == f {print $1}' "$TMP_FOLDER/SHA256SUMS")
[ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from just SHA256SUMS" >&2; exit 1; }

fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" just
install_bin "$TMP_FOLDER/just" just

echo "==> just $JUST_VERSION installed."
