#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

# The kiseki CLI lives in hnatekmar/kiseki. Canonical remote is Forgejo
# (forgejo.srv.hnatekmar.dev/hnatekmar/kiseki); the tarball comes from the
# GitHub push mirror so a bootstrap works off the homelab network too. Pin a
# commit rather than a tag: the repo has no release tags yet, and a commit is
# immutable even when main moves.
KISEKI_VERSION=main-f2a8db0f
KISEKI_COMMIT=f2a8db0f5e5799e1201cf679494a2619f0f3ea94
DEST="$HOME/.local/share/kiseki"
ASSET="kiseki-${KISEKI_VERSION}.tar.gz"
CACHE_KEY="kiseki/${KISEKI_VERSION}"
URL="https://codeload.github.com/hnatekmar/kiseki/tar.gz/${KISEKI_COMMIT}"

# Migration from the old 07_dev_env feature: its symlink would dangle once the
# tree below is replaced, and both commands would sit on PATH. Only touch trees
# this bootstrap created — a hand-made ~/.local/share/dev-env is left alone.
OLD_DEST="$HOME/.local/share/dev-env"
if [ -f "$OLD_DEST/.dots-version" ]; then
    if [ -L "$HOME/.local/bin/dev-env" ] &&
        [ "$(readlink -f "$HOME/.local/bin/dev-env")" = "$OLD_DEST/scripts/dev-env.sh" ]; then
        rm -f "$HOME/.local/bin/dev-env"
    fi
    rm -rf "$OLD_DEST"
fi

if [ "${DOTS_FORCE:-0}" != "1" ] &&
    [ -x "$HOME/.local/bin/kiseki" ] &&
    [ -f "$DEST/.dots-version" ] &&
    [ "$(cat "$DEST/.dots-version")" = "$KISEKI_VERSION" ]; then
    echo "==> kiseki $KISEKI_VERSION already installed, skipping"
    exit 0
fi

# codeload publishes no checksum file, so the tarball digest is pinned in
# features/checksums.txt.
EXPECTED=$(require_asset_sha256 "$ASSET")

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Installing kiseki $KISEKI_VERSION..."
fetch_cached "$URL" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
mkdir -p "$TMP_FOLDER/src"
tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER/src" --strip-components=1

# Replace the tree instead of merging into it: a version bump must not leave
# files from the previous release behind.
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
mv "$TMP_FOLDER/src" "$DEST"
printf '%s\n' "$KISEKI_VERSION" >"$DEST/.dots-version"

# The repo ships its own installer; using it keeps one definition of how the
# command lands on PATH (and it verifies the symlink runs).
bash "$DEST/scripts/install.sh" --bindir "$HOME/.local/bin"

echo "==> kiseki $KISEKI_VERSION installed. Run 'kiseki help'."
