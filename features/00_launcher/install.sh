#!/bin/bash
set -euo pipefail

# Install the dots-bootstrap.sh launcher into ~/.local/bin.
# Uses an explicit symlink rather than stow so the target path is exact
# and we don't collide with a pre-existing ~/.local tree.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.local/bin"
SOURCE="$SCRIPT_DIR/dotfiles/.local/bin/dots-bootstrap.sh"

mkdir -p "$TARGET_DIR"
ln -sfn "$SOURCE" "$TARGET_DIR/dots-bootstrap.sh"
chmod +x "$SOURCE"

echo "==> Launcher installed: ~/.local/bin/dots-bootstrap.sh"
echo "==> Run 'dots-bootstrap.sh --list' to see features, or '--force' to reinstall."
