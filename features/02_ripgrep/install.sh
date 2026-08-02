#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

RIPGREP_VERSION=15.2.0

if check_command_version rg "$RIPGREP_VERSION"; then
    echo "==> ripgrep $RIPGREP_VERSION already installed, skipping"
    exit 0
fi

echo "==> Building ripgrep $RIPGREP_VERSION from source..."
cargo install --locked "ripgrep@${RIPGREP_VERSION}"

echo "==> ripgrep $RIPGREP_VERSION installed."
