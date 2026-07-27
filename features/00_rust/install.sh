#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

# Installs the Rust stable toolchain via rustup into ~/.cargo.
# ripgrep and fd are then built from source with `cargo install`.

if check_command_version cargo ""; then
    echo "==> cargo already installed, skipping"
    [ "${DOTS_FORCE:-0}" = "1" ] && rustup update stable
    exit 0
fi

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Downloading rustup-init..."
curl --proto '=https' --tlsv1.2 -sSfL "https://sh.rustup.rs" -o "$TMP_FOLDER/rustup-init"
chmod +x "$TMP_FOLDER/rustup-init"

# Minimal profile: rustc + cargo + rust-std (no docs/clippy) for faster install.
# --no-modify-path: bootstrap.sh and the stowed .profile already add ~/.cargo/bin
# to PATH; this also prevents rustup from appending to the stowed ~/.profile
# symlink (which would mutate the repo source file).
"$TMP_FOLDER/rustup-init" -y --profile minimal --default-toolchain stable --no-modify-path

# Ensure cargo is on PATH for this bootstrap session
export PATH="$HOME/.cargo/bin:$PATH"

echo "==> Rust stable toolchain installed."
