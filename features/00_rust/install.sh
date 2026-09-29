#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

# Installs the Rust stable toolchain via rustup into ~/.cargo.
# ripgrep and fd are then built from source with `cargo install`.

# If cargo is present, either skip or (under DOTS_FORCE) update the toolchain.
if command -v cargo >/dev/null 2>&1; then
    if [ "${DOTS_FORCE:-0}" = "1" ]; then
        echo "==> cargo present, updating stable toolchain (DOTS_FORCE=1)"
        rustup update stable
        exit 0
    fi
    echo "==> cargo already installed, skipping"
    exit 0
fi

RUSTUP_TARGET="$(map_arch x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu)"

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Downloading rustup-init..."
RUSTUP_BASE="https://static.rust-lang.org/rustup/dist/${RUSTUP_TARGET}"
curl --proto '=https' --tlsv1.2 -sSfL "$RUSTUP_BASE/rustup-init" -o "$TMP_FOLDER/rustup-init"
curl --proto '=https' --tlsv1.2 -sSfL "$RUSTUP_BASE/rustup-init.sha256" -o "$TMP_FOLDER/rustup-init.sha256"

echo "==> Verifying rustup-init checksum..."
EXPECTED=$(cut -d' ' -f1 "$TMP_FOLDER/rustup-init.sha256")
verify_sha256 "$TMP_FOLDER/rustup-init" "$EXPECTED"

chmod +x "$TMP_FOLDER/rustup-init"

# Minimal profile: rustc + cargo + rust-std (no docs/clippy) for faster install.
# --no-modify-path: bootstrap.sh and the symlinked .profile already add ~/.cargo/bin
# to PATH; this also prevents rustup from appending to the symlinked ~/.profile
# symlink (which would mutate the repo source file).
"$TMP_FOLDER/rustup-init" -y --profile minimal --default-toolchain stable --no-modify-path

# Ensure cargo is on PATH for this bootstrap session
export PATH="$HOME/.cargo/bin:$PATH"

echo "==> Rust stable toolchain installed."
