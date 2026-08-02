#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

FD_VERSION=10.4.2

if check_command_version fd "$FD_VERSION"; then
    echo "==> fd $FD_VERSION already installed, skipping"
    exit 0
fi

echo "==> Building fd $FD_VERSION from source..."
cargo install --locked "fd-find@${FD_VERSION}"

echo "==> fd $FD_VERSION installed."
