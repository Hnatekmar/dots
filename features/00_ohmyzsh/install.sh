#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../utils.sh"

OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"

# Installed with --keep-zshrc so the oh-my-zsh template never overwrites the
# stowed ~/.zshrc from 00_base. --unattended skips the interactive chsh prompt.
if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    echo "==> Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
else
    echo "==> oh-my-zsh already installed, skipping"
fi

# External plugins referenced in the stowed ~/.zshrc (not bundled with oh-my-zsh)
PLUGIN_DIR="$OH_MY_ZSH_DIR/custom/plugins"
mkdir -p "$PLUGIN_DIR"

if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
    echo "==> Installing zsh-autosuggestions..."
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
else
    echo "==> zsh-autosuggestions already installed, skipping"
fi

if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    echo "==> Installing zsh-syntax-highlighting..."
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGIN_DIR/zsh-syntax-highlighting"
else
    echo "==> zsh-syntax-highlighting already installed, skipping"
fi
