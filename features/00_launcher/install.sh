#!/bin/bash
set -euo pipefail

# Symlink the repo's bootstrap.sh into ~/.local/bin as the launcher.
# bootstrap.sh resolves its own repo path via readlink -f, so the symlink works.
DOTS_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET_DIR="$HOME/.local/bin"

mkdir -p "$TARGET_DIR"
ln -sfn "$DOTS_ROOT/bootstrap.sh" "$TARGET_DIR/dots-bootstrap.sh"
chmod +x "$DOTS_ROOT/bootstrap.sh"

echo "==> Launcher installed: ~/.local/bin/dots-bootstrap.sh"
echo "==> Run 'dots-bootstrap.sh --list' to see features, or '--force' to reinstall."
