#!/bin/bash

source "$(dirname "$0")/../utils.sh"

NEOVIM_VERSION="0.12.4"

if check_command_version nvim "$NEOVIM_VERSION"; then
    echo "==> nvim $NEOVIM_VERSION already installed, skipping"
    exit 0
fi

TMP_FOLDER=$(mktemp -d)

cd "$TMP_FOLDER"

curl -LO "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz"

tar -xzf nvim-linux-x86_64.tar.gz -C /usr/local --strip-components=1
