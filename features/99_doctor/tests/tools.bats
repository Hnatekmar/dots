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

# ── fzf ──

@test "fzf is installed" {
    assert_cmd fzf
}

@test "fzf version is 0.74.5+" {
    run fzf --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -Eq '^(0\.(7[4-9]|[89][0-9])|[1-9][0-9]*\.)'
}

# ── zoxide ──

@test "zoxide is installed" {
    assert_cmd zoxide
}

@test "zoxide version is 0.10.0+" {
    run zoxide --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q 'zoxide 0\.\(1[0-9]\|[2-9][0-9]\)\.'
}

# ── lsd ──

@test "lsd is installed" {
    assert_cmd lsd
}

@test "lsd version is 1.2.0+" {
    run lsd --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q 'lsd 1\.\([2-9]\|[1-9][0-9]\)\.'
}

# ── hunk ──

@test "hunk is installed" {
    assert_cmd hunk
}

@test "hunk version is 0.23.0+" {
    run hunk --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -Eq '^(0\.(2[3-9]|[3-9][0-9])|[1-9][0-9]*\.)'
}

# ── herdr ──

@test "herdr is installed" {
    assert_cmd herdr
}

@test "herdr version is 0.9.5+" {
    run herdr --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q 'herdr 0\.\(9\|[1-9][0-9]\)\.'
}

# ── Shell / language tooling ──

@test "direnv is installed" {
    assert_cmd direnv
}

@test "direnv version is 2.38.2+" {
    run direnv version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q '^2\.\(3[8-9]\|[4-9][0-9]\)\.'
}

@test "node is installed" {
    assert_cmd node
}

@test "node version is 24.22.0+" {
    run node --version
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '^v\(2[4-9]\|[3-9][0-9]\)\.'
}

@test "node is installed in ~/.local/node (rootless)" {
    [ -x "$HOME/.local/node/bin/node" ]
    [ ! -e "/usr/local/bin/node" ]
}

@test "npm is installed" {
    assert_cmd npm
}

@test "uv is installed" {
    assert_cmd uv
}

@test "uv version is 0.13.1+" {
    run uv --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q '^uv 0\.\(1[3-9]\|[2-9][0-9]\)\.'
}

@test "uvx is installed" {
    assert_cmd uvx
}

@test "uvx version is 0.13.1+" {
    run uvx --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q '^uvx 0\.\(1[3-9]\|[2-9][0-9]\)\.'
}

# ── Infrastructure / Kubernetes companions ──

@test "tofu is installed" {
    assert_cmd tofu
}

@test "tofu version is 1.13.1+" {
    run tofu version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q '^OpenTofu v1\.\(1[3-9]\|[2-9][0-9]\)\.'
}

@test "gh is installed" {
    assert_cmd gh
}

@test "gh version is 2.102.0+" {
    run gh version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q '^gh version 2\.\(10[2-9]\|1[1-9][0-9]\|[2-9][0-9][0-9]\)\.'
}

@test "kubectx is installed" {
    assert_cmd kubectx
}

@test "kubectx version is 0.11.0+" {
    run kubectx --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q '^0\.\(1[1-9]\|[2-9][0-9]\)\.'
}

@test "kubens is installed" {
    assert_cmd kubens
}

@test "kubens version is 0.11.0+" {
    run kubens --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q '^0\.\(1[1-9]\|[2-9][0-9]\)\.'
}

# ── Utilities ──

@test "bat is installed" {
    assert_cmd bat
}

@test "bat version is 0.26.1+" {
    run bat --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q '^bat 0\.\(2[6-9]\|[3-9][0-9]\)\.'
}

@test "fastfetch is installed" {
    assert_cmd fastfetch
}

@test "fastfetch version is 2.70.0+" {
    run fastfetch --version
    [ "$status" -eq 0 ]
    echo "$output" | head -1 | grep -q '^fastfetch 2\.\(7[0-9]\|[89][0-9]\|[1-9][0-9][0-9]\)\.'
}

# ── Kubernetes tooling ──

@test "helm is installed" {
    assert_cmd helm
}

@test "helm version is 4.3.1+" {
    run helm version --template '{{.Version}}'
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '^v4\.\([3-9]\|[1-9][0-9]\)\.'
}

@test "kubectl is installed" {
    assert_cmd kubectl
}

@test "kubectl version is 1.37.1+" {
    run kubectl version --client=true --output json
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '"gitVersion": "v1\.\(3[7-9]\|[4-9][0-9]\)\.'
}

@test "k9s is installed" {
    assert_cmd k9s
}

@test "k9s version is 0.51.0+" {
    run k9s version --short
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '^Version[[:space:]]*v0\.\(5[1-9]\|[6-9][0-9]\)'
}

@test "kubecolor is installed" {
    assert_cmd kubecolor
}

@test "kubecolor version is 0.8.0+" {
    run kubecolor --kubecolor-version
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '^v\?0\.\([89]\|[1-9][0-9]\)\.'
}

@test "jq is installed" {
    assert_cmd jq
}

@test "jq version is 1.8.2+" {
    run jq --version
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '^jq-1\.\([89]\|[1-9][0-9]\)\.'
}

@test "yq is installed" {
    assert_cmd yq
}

@test "yq version is 4.54.1+" {
    run yq --version
    [ "$status" -eq 0 ]
    echo "$output" | grep -q 'version v4\.\(5[4-9]\|[6-9][0-9]\)\.'
}

# ── lazygit ──

@test "lazygit is installed" {
    assert_cmd lazygit
}

# ── prebuilt binaries ──

@test "gum, rg, fd, fzf, zoxide, lsd, hunk, herdr, direnv, uv, uvx, tofu, gh, kubectx, kubens, bat, fastfetch, helm, kubectl, k9s, kubecolor, jq, yq and lazygit install as prebuilt binaries in ~/.local/bin" {
    [ -x "$HOME/.local/bin/gum" ]
    [ -x "$HOME/.local/bin/rg" ]
    [ -x "$HOME/.local/bin/fd" ]
    [ -x "$HOME/.local/bin/fzf" ]
    [ -x "$HOME/.local/bin/zoxide" ]
    [ -x "$HOME/.local/bin/lsd" ]
    [ -x "$HOME/.local/bin/hunk" ]
    [ -x "$HOME/.local/bin/herdr" ]
    [ -x "$HOME/.local/bin/direnv" ]
    [ -x "$HOME/.local/bin/uv" ]
    [ -x "$HOME/.local/bin/uvx" ]
    [ -x "$HOME/.local/bin/tofu" ]
    [ -x "$HOME/.local/bin/gh" ]
    [ -x "$HOME/.local/bin/kubectx" ]
    [ -x "$HOME/.local/bin/kubens" ]
    [ -x "$HOME/.local/bin/bat" ]
    [ -x "$HOME/.local/bin/fastfetch" ]
    [ -x "$HOME/.local/bin/helm" ]
    [ -x "$HOME/.local/bin/kubectl" ]
    [ -x "$HOME/.local/bin/k9s" ]
    [ -x "$HOME/.local/bin/kubecolor" ]
    [ -x "$HOME/.local/bin/jq" ]
    [ -x "$HOME/.local/bin/yq" ]
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
