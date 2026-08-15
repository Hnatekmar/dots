#!/usr/bin/env bats

# Verify dotfiles are properly symlinked into $HOME.

load helpers/utils

# ── Shell configs ──

@test "~/.bash_profile is a symlink" {
    [ -L "$HOME/.bash_profile" ]
}

@test "~/.bash_profile sources .profile" {
    run cat "$HOME/.bash_profile"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '\.profile'
}

@test "~/.profile is a symlink" {
    [ -L "$HOME/.profile" ]
}

@test "~/.profile contains ~/.local/go/bin in PATH" {
    run cat "$HOME/.profile"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '.local/go/bin'
}

@test "~/.zshrc is a symlink" {
    [ -L "$HOME/.zshrc" ]
}

@test "~/.zshrc has no hardcoded /home/martin paths" {
    if [ ! -f "$HOME/.zshrc" ]; then skip "no .zshrc"; fi
    run grep '/home/martin' "$HOME/.zshrc"
    [ "$status" -ne 0 ]
}

# ── Crush config ──

@test "~/.config/crush/crush.json exists (symlinked or real)" {
    [ -e "$HOME/.config/crush/crush.json" ]
}

# ── Launcher ──

@test "~/.local/bin/dots-bootstrap.sh is a symlink" {
    [ -L "$HOME/.local/bin/dots-bootstrap.sh" ]
}

@test "dots-bootstrap.sh is executable" {
    [ -x "$HOME/.local/bin/dots-bootstrap.sh" ]
}

# ── Doctor itself ──

@test "~/.local/bin/dots-doctor is a symlink" {
    [ -L "$HOME/.local/bin/dots-doctor" ]
}

# ── oh-my-zsh ──

@test "~/.oh-my-zsh directory exists" {
    [ -d "$HOME/.oh-my-zsh" ]
}

@test "zsh-autosuggestions plugin is installed" {
    [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]
}

@test "zsh-syntax-highlighting plugin is installed" {
    [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]
}

# ── LazyVim ──

@test "~/.config/nvim exists (symlinked to lazyvim)" {
    [ -e "$HOME/.config/nvim" ]
}
