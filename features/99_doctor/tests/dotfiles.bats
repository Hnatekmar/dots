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

@test "opencode has the image-generation skill and its script" {
    [ -f "$HOME/.config/opencode/skills/image-generation/SKILL.md" ]
    [ -x "$HOME/.config/opencode/skills/image-generation/scripts/generate.sh" ]
}

@test "opencode has the asd-ste100 skill and its linter" {
    [ -f "$HOME/.config/opencode/skills/asd-ste100/SKILL.md" ]
    [ -x "$HOME/.config/opencode/skills/asd-ste100/scripts/ste-lint.py" ]
}

@test "shared skill set was installed by npx skills" {
    # 02_opencode installs mattpocock/skills into opencode's global
    # agent-compatible dir. A missing tree means the npx step was skipped
    # (no network) or failed; re-run the feature.
    [ -f "$HOME/.agents/skills/code-review/SKILL.md" ]
    [ -f "$HOME/.agents/skills/tdd/SKILL.md" ]
}

@test "stale vendored skill trees are gone" {
    for bucket in engineering in-progress misc productivity deprecated; do
        [ ! -e "$HOME/.config/opencode/skills/$bucket" ]
    done
}

@test "opencode config has no runtime-dropped model keys" {
    # opencode 2.x omits `reasoning` / `attachment` on a model entry and logs a
    # "configuration normalization diagnostic" at every start. Keep them out.
    local cfg="$HOME/.config/opencode/opencode.json"
    if [ ! -f "$cfg" ]; then skip "no opencode.json"; fi
    run grep -E '"(reasoning|attachment)"[[:space:]]*:[[:space:]]*(true|false)' "$cfg"
    [ "$status" -ne 0 ]
}

@test "opencode wrapper disables model fetch and update checks" {
    # opencode has no config key for the catalog fetch; the switches live in the
    # wrapper so every launch path (TUI, run, spawned service) inherits them.
    local w="$HOME/.local/bin/opencode"
    if [ ! -f "$w" ]; then skip "no wrapper (installed by 02_opencode)"; fi
    run grep -q 'OPENCODE_DISABLE_MODELS_FETCH:-1' "$w"
    [ "$status" -eq 0 ]
    run grep -q 'OPENCODE_DISABLE_AUTOUPDATE:-1' "$w"
    [ "$status" -eq 0 ]
}

@test "opencode resolves to the wrapper, not a stray binary" {
    if ! command -v opencode >/dev/null 2>&1; then skip "opencode not installed"; fi
    run command -v opencode
    [ "$output" = "$HOME/.local/bin/opencode" ]
}

@test "opencode defaults to the build agent bound to a model" {
    # Plan/build split: build (defined in opencode.json) is the default and works
    # itself; plan, explore and general are opencode built-ins. Custom markdown
    # agents were removed after A/B tests showed the lead/reviewer fan-out cost
    # 3-15x the time for no measurable gain.
    local cfg="$HOME/.config/opencode/opencode.json"
    run grep -q '"default_agent": "build"' "$cfg"
    [ "$status" -eq 0 ]
    run python3 -c 'import json,sys; c=json.load(open(sys.argv[1])); assert c["agent"]["build"]["model"].startswith("lmproxy/")' "$cfg"
    [ "$status" -eq 0 ]
    # Any markdown agent that is added back must still bind a model.
    local f
    for f in "$HOME"/.config/opencode/agents/*.md; do
        [ -e "$f" ] || continue
        grep -q '^model: lmproxy/' "$f" || { echo "$(basename "$f") has no lmproxy model"; false; }
    done
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
