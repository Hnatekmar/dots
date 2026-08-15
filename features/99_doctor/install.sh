#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

BATS_VERSION=1.11.1
BATS_DIR="$HOME/.local/opt/bats-core"

# Idempotency: skip if bats is installed and dots-doctor symlink exists
if [ -x "$BATS_DIR/bin/bats" ] && [ -L "$HOME/.local/bin/dots-doctor" ]; then
    if [ "${DOTS_FORCE:-0}" != "1" ]; then
        echo "==> dots-doctor already installed, skipping"
        exit 0
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing bats-core $BATS_VERSION..."

rm -rf "$BATS_DIR"
mkdir -p "$(dirname "$BATS_DIR")"

git clone --depth 1 --branch "v${BATS_VERSION}" \
    https://github.com/bats-core/bats-core.git "$BATS_DIR"

# Install bats into ~/.local so the bats binary is on PATH
cd "$BATS_DIR"
./install.sh "$HOME/.local"

# Symlink dots-doctor into ~/.local/bin
TARGET_DIR="$HOME/.local/bin"
mkdir -p "$TARGET_DIR"
ln -sfn "$SCRIPT_DIR/dotfiles/.local/bin/dots-doctor" "$TARGET_DIR/dots-doctor"
chmod +x "$SCRIPT_DIR/dotfiles/.local/bin/dots-doctor"

echo "==> dots-doctor installed. Run 'dots-doctor' to check your installation."
