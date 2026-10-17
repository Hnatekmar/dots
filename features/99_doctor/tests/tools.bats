#!/usr/bin/env bats

# Verify all bootstrapped tools are installed with correct versions.

load helpers/utils

# ── Go ──

@test "go is installed" {
    assert_cmd go
}

@test "go version is 1.26.5+" {
    run go version
    [ "$status" -eq 0 ]
    echo "$output" | grep -q 'go1\.\(2[6-9]\|[3-9][0-9]\)'
}

@test "go is installed in ~/.local/go (rootless)" {
    [ -x "$HOME/.local/go/bin/go" ]
    [ ! -e "/usr/local/go" ]
}

# ── Neovim ──

@test "nvim is installed" {
    assert_cmd nvim
}

@test "nvim version is 0.12.4+" {
    run nvim --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q 'NVIM v0\.\(1[2-9]\|[2-9][0-9]\)'
}

@test "nvim is installed in ~/.local (rootless)" {
    [ -x "$HOME/.local/bin/nvim" ]
    [ ! -e "/usr/local/bin/nvim" ]
}

# ── Rust / Cargo ──

@test "cargo is installed" {
    assert_cmd cargo
}

@test "cargo --version works" {
    run cargo --version
    [ "$status" -eq 0 ]
}

@test "cargo is in ~/.cargo/bin (rootless)" {
    [ -x "$HOME/.cargo/bin/cargo" ]
}

# ── ripgrep ──

@test "rg is installed" {
    assert_cmd rg
}

@test "rg version is 15.2.0+" {
    run rg --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q 'ripgrep \(1[5-9]\|[2-9][0-9]\)\.'
}

# ── fd ──

@test "fd is installed" {
    assert_cmd fd
}

@test "fd version is 10.4.2+" {
    run fd --version
    [ "$status" -eq 0 ]
    echo "$output" | grep -q 'fd \(1[0-9]\|[2-9][0-9]\)\.'
}

# ── lazygit ──

@test "lazygit is installed" {
    assert_cmd lazygit
}

# ── prebuilt binaries ──

@test "gum, rg, fd and lazygit install as prebuilt binaries in ~/.local/bin" {
    [ -x "$HOME/.local/bin/gum" ]
    [ -x "$HOME/.local/bin/rg" ]
    [ -x "$HOME/.local/bin/fd" ]
    [ -x "$HOME/.local/bin/lazygit" ]
}

# ── gum ──

@test "gum is installed" {
    assert_cmd gum
}

@test "gum version is 0.16.2+" {
    run gum --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q 'v0\.\(1[6-9]\|[2-9][0-9]\)'
}

# ── opencode ──

@test "opencode is installed" {
    assert_cmd opencode
}

@test "opencode version is 2.0.26+" {
    run opencode --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q 'v2\.'
}

# ── OpenBao ──

@test "bao is installed" {
    assert_cmd bao
}

@test "bao version is 2.6.1+" {
    run bao version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q 'OpenBao v2\.\([6-9]\|[1-9][0-9]\)'
}

@test "bao is installed in ~/.local/bin (rootless)" {
    [ -x "$HOME/.local/bin/bao" ]
    [ ! -e "/usr/local/bin/bao" ]
}

# ── gopls ──

@test "gopls is installed" {
    assert_cmd gopls
}
