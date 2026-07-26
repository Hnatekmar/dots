#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

CRUSH_VERSION=0.87.0

if check_command_version crush "$CRUSH_VERSION"; then
    echo "==> crush $CRUSH_VERSION already installed, skipping"
    exit 0
fi

cd "$(dirname "$0")/dotfiles/"
stow -t "$HOME" -R crush

go install "github.com/charmbracelet/crush@v${CRUSH_VERSION}"
