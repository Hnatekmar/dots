#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

LAZYGIT_VERSION=0.63.1

# lazygit built via `go install` reports an unreliable --version (no ldflags),
# so gate on presence + DOTS_FORCE rather than check_command_version.
if [ "${DOTS_FORCE:-0}" != "1" ] && command -v lazygit &>/dev/null; then
    echo "==> lazygit already installed, skipping"
    exit 0
fi

echo "==> Building lazygit $LAZYGIT_VERSION from source..."
go install "github.com/jesseduffield/lazygit@v${LAZYGIT_VERSION}"

echo "==> lazygit $LAZYGIT_VERSION installed."
