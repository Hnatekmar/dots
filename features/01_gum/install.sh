#!/bin/bash

source "$(dirname "$0")/../utils.sh"

if check_command_version gum ""; then
    echo "==> gum already installed, skipping"
    exit 0
fi

go install github.com/charmbracelet/gum@latest
