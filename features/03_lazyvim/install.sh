#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

LAZYGIT_VERSION="0.63.1"

if check_command_version nvim "0.10"; then
    echo "==> nvim >= 0.10 already installed, skipping"
else
    echo "==> Installing neovim dependency..."
    bash "$(dirname "$0")/../00_neovim/install.sh"
fi

# Install lazygit from prebuilt binary
if command -v lazygit &>/dev/null; then
    echo "==> lazygit already installed, skipping"
else
    echo "==> Installing lazygit..."

    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  ARCH="x86_64" ;;
        aarch64) ARCH="arm64" ;;
        *) echo "ERROR: Unsupported architecture: $ARCH" >&2; exit 1 ;;
    esac

    TMP_FOLDER=$(mktemp -d)
    trap 'rm -rf "$TMP_FOLDER"' EXIT

    cd "$TMP_FOLDER"
    curl -LO "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_${ARCH}.tar.gz"
    tar -xzf "lazygit_${LAZYGIT_VERSION}_linux_${ARCH}.tar.gz" -C /usr/local/bin lazygit
fi

# Install ripgrep
if command -v rg &>/dev/null; then
    echo "==> ripgrep already installed, skipping"
else
    echo "==> Installing ripgrep..."
    dnf install -y ripgrep
fi

# Install fd-find
if command -v fd &>/dev/null; then
    echo "==> fd already installed, skipping"
else
    echo "==> Installing fd-find..."
    dnf install -y fd-find
    # Link fdfind to fd (Fedora packages it as fdfind)
    if command -v fdfind &>/dev/null; then
        ln -sf "$(which fdfind)" /usr/local/bin/fd
    fi
fi

# Install gopls for Go LSP
if ! command -v gopls &>/dev/null; then
    echo "==> Installing gopls..."
    go install golang.org/x/tools/gopls@latest
fi

# Initialize lazyvim submodule
LAZYVIM_DIR="$(cd "$(dirname "$0")" && pwd)/lazyvim"

if [ ! -d "$LAZYVIM_DIR/.git" ]; then
    echo "==> Cloning lazyvim submodule..."
    DOTS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
    (cd "$DOTS_ROOT" && git submodule update --init --recursive)
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
