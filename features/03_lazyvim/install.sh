#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Delegate to the features lazyvim depends on (00_go first: lazygit and gopls are
# built with go, so --only 03_lazyvim must still work standalone)
for dep in 00_go 00_neovim 02_ripgrep 02_fd 03_lazygit; do
    echo "==> Ensuring dependency: $dep"
    bash "$SCRIPT_DIR/../$dep/install.sh"
done

# Install gopls for Go LSP (pinned for reproducible installs)
GOPSL_VERSION=0.23.0
if ! command -v gopls &>/dev/null; then
    echo "==> Installing gopls..."
    go install "golang.org/x/tools/gopls@v${GOPSL_VERSION}"
fi

# Initialize lazyvim submodule
LAZYVIM_DIR="$SCRIPT_DIR/lazyvim"

if [ ! -d "$LAZYVIM_DIR" ] || [ -z "$(ls -A "$LAZYVIM_DIR" 2>/dev/null | grep -v '^\.git$')" ]; then
    echo "==> Initializing lazyvim submodule..."
    DOTS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

    if (cd "$DOTS_ROOT" && git submodule update --init --recursive 2>/dev/null); then
        :
    else
        echo "==> git submodule update failed, cloning directly..."
        # Uses -A3 so the url line (3 lines after the [submodule] header) is kept
        SUBMODULE_URL=$(grep -A3 'lazyvim"' "$DOTS_ROOT/.gitmodules" | sed -n 's/.*url *= *//p')
        if [ -n "$SUBMODULE_URL" ]; then
            rm -rf "$LAZYVIM_DIR"
            git clone --depth 1 "$SUBMODULE_URL" "$LAZYVIM_DIR"
        else
            echo "ERROR: could not determine lazyvim submodule URL from .gitmodules" >&2
            exit 1
        fi
    fi
fi

# Symlink to ~/.config/nvim
NVIM_DIR="$HOME/.config/nvim"

if [ -d "$NVIM_DIR" ] && [ ! -L "$NVIM_DIR" ]; then
    echo "==> Backing up existing nvim config..."
    mv "$NVIM_DIR" "${NVIM_DIR}.bak.$(date +%Y%m%d%H%M%S)"
fi

echo "==> Symlinking lazyvim to $NVIM_DIR..."
ln -sfn "$LAZYVIM_DIR" "$NVIM_DIR"

echo "==> LazyVim installed. Run 'nvim' to initialize plugins."
