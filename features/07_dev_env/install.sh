#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

# The dev-env CLI lives in hnatekmarorg/dev-envs. The tarball is pinned to a
# commit rather than a tag: a commit is immutable, and creating a tag upstream
# needs write access that this bot does not have. The commit is the tree of
# release 0.3.0.
DEV_ENV_VERSION=0.3.0
DEV_ENVS_REPO=zelvinator/dev-envs
DEV_ENV_COMMIT=629a21b1c0020af32848c2c60db3bd33ef38986f
DEST="$HOME/.local/share/dev-env"
ASSET="dev-envs-v${DEV_ENV_VERSION}.tar.gz"
CACHE_KEY="dev-env/${DEV_ENV_VERSION}"
URL="https://codeload.github.com/${DEV_ENVS_REPO}/tar.gz/${DEV_ENV_COMMIT}"

if [ "${DOTS_FORCE:-0}" != "1" ] &&
    [ -x "$HOME/.local/bin/dev-env" ] &&
    [ -f "$DEST/.dots-version" ] &&
    [ "$(cat "$DEST/.dots-version")" = "$DEV_ENV_VERSION" ]; then
    echo "==> dev-env $DEV_ENV_VERSION already installed, skipping"
    exit 0
fi

# codeload publishes no checksum file, so the tarball digest is pinned in
# features/checksums.txt.
EXPECTED=$(require_asset_sha256 "$ASSET")

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing dev-env $DEV_ENV_VERSION..."
fetch_cached "$URL" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
mkdir -p "$TMP_FOLDER/src"
tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER/src" --strip-components=1

# Replace the tree instead of merging into it: a version bump must not leave
# files from the previous release behind.
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
mv "$TMP_FOLDER/src" "$DEST"
printf '%s\n' "$DEV_ENV_VERSION" >"$DEST/.dots-version"

# The release ships its own installer; using it keeps one definition of how the
# command lands on PATH (and it verifies the symlink runs).
bash "$DEST/scripts/install.sh" --bindir "$HOME/.local/bin"

echo "==> dev-env $DEV_ENV_VERSION installed. Run 'dev-env --help'."
