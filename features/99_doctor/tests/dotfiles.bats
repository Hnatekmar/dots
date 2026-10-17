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

@test "~/.zshrc has no sesh integration" {
    if [ ! -f "$HOME/.zshrc" ]; then skip "no .zshrc"; fi
    run grep -n 'sesh' "$HOME/.zshrc"
    [ "$status" -ne 0 ]
}

# ── Git config ──

@test "git user.name is configured" {
    run git config --global user.name
    [ "$status" -eq 0 ]
    [ "$output" = "Hnatekmar" ]
}

@test "git user.email is configured" {
    run git config --global user.email
    [ "$status" -eq 0 ]
    [ "$output" = "m.hnatma@gmail.com" ]
}

@test "git diff opens in hunk via core.pager" {
    run git config --global core.pager
    [ "$status" -eq 0 ]
    [ "$output" = "hunk pager" ]
}

# ── OpenCode config ──

@test "~/.config/opencode/opencode.json exists (symlinked or real)" {
    [ -e "$HOME/.config/opencode/opencode.json" ]
}

@test "~/.config/opencode/opencode.json has no hardcoded /home/martin paths" {
    run grep '/home/martin' "$HOME/.config/opencode/opencode.json"
    [ "$status" -ne 0 ]
}

@test "opencode has the hunk skills available" {
    [ -f "$HOME/.config/opencode/skills/hunk-review/SKILL.md" ]
    [ -f "$HOME/.config/opencode/skills/hunk-extensions/SKILL.md" ]
}

@test "opencode has the herdr skill available" {
    [ -f "$HOME/.config/opencode/skills/herdr/SKILL.md" ]
    run grep '^name: herdr$' "$HOME/.config/opencode/skills/herdr/SKILL.md"
    [ "$status" -eq 0 ]
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
