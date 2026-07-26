#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

GUM_VERSION=0.16.2

if check_command_version gum "$GUM_VERSION"; then
    echo "==> gum $GUM_VERSION already installed, skipping"
    exit 0
fi

go install "github.com/charmbracelet/gum@v${GUM_VERSION}"
