#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

OPENCODE_VERSION=2.0.26

stow_pkg "$(dirname "$0")/dotfiles" opencode

if check_command_version opencode "$OPENCODE_VERSION"; then
    echo "==> opencode $OPENCODE_VERSION already installed, skipping"
    exit 0
fi

# --no-modify-path: the installer would append a PATH export to ~/.bashrc,
# which is not ours to edit. The symlink below exposes the binary through
# ~/.local/bin instead, which bootstrap.sh already puts on PATH.
curl -fsSL https://opencode.ai/v2/install | bash -s -- --version "$OPENCODE_VERSION" --no-modify-path

mkdir -p "$HOME/.local/bin"
ln -sfn "$HOME/.opencode/bin/opencode" "$HOME/.local/bin/opencode"
