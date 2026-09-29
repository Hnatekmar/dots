#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../utils.sh"

OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"

# Installed with --keep-zshrc so the oh-my-zsh template never overwrites the
# symlinked ~/.zshrc from 00_base. --unattended skips the interactive chsh prompt.
if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    echo "==> Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
else
    echo "==> oh-my-zsh already installed, skipping"
fi

# External plugins referenced in the symlinked ~/.zshrc (not bundled with oh-my-zsh)
PLUGIN_DIR="$OH_MY_ZSH_DIR/custom/plugins"
mkdir -p "$PLUGIN_DIR"

for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [ ! -d "$PLUGIN_DIR/$plugin" ]; then
        echo "==> Installing $plugin..."
        git clone --depth 1 "https://github.com/zsh-users/$plugin" "$PLUGIN_DIR/$plugin"
    else
        echo "==> $plugin already installed, skipping"
    fi
done
