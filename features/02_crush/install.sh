#!/bin/bash

source "$(dirname "$0")/../utils.sh"

CRUSH_VERSION=v0.87.0

if check_command_version crush "$CRUSH_VERSION"; then
    echo "==> crush $CRUSH_VERSION already installed, skipping"
    exit 0
fi

cd dotfiles/

stow -t $HOME -R crush

go install github.com/charmbracelet/crush@latest
