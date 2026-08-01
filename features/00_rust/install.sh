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

# Map machine arch to a rustup target triple
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  RUSTUP_TARGET="x86_64-unknown-linux-gnu" ;;
    aarch64)  RUSTUP_TARGET="aarch64-unknown-linux-gnu" ;;
    *) echo "ERROR: Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

echo "==> Downloading rustup-init..."
RUSTUP_BASE="https://static.rust-lang.org/rustup/dist/${RUSTUP_TARGET}"
curl --proto '=https' --tlsv1.2 -sSfL "$RUSTUP_BASE/rustup-init" -o "$TMP_FOLDER/rustup-init"
curl --proto '=https' --tlsv1.2 -sSfL "$RUSTUP_BASE/rustup-init.sha256" -o "$TMP_FOLDER/rustup-init.sha256"

echo "==> Verifying rustup-init checksum..."
EXPECTED=$(cut -d' ' -f1 "$TMP_FOLDER/rustup-init.sha256")
ACTUAL=$(sha256sum "$TMP_FOLDER/rustup-init" | cut -d' ' -f1)
if [ -z "$EXPECTED" ] || [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "ERROR: rustup-init checksum mismatch" >&2
    echo "  Expected: $EXPECTED" >&2
    echo "  Actual:   $ACTUAL" >&2
    exit 1
fi

chmod +x "$TMP_FOLDER/rustup-init"

# Minimal profile: rustc + cargo + rust-std (no docs/clippy) for faster install.
# --no-modify-path: bootstrap.sh and the stowed .profile already add ~/.cargo/bin
# to PATH; this also prevents rustup from appending to the stowed ~/.profile
# symlink (which would mutate the repo source file).
"$TMP_FOLDER/rustup-init" -y --profile minimal --default-toolchain stable --no-modify-path

# Ensure cargo is on PATH for this bootstrap session
export PATH="$HOME/.cargo/bin:$PATH"

echo "==> Rust stable toolchain installed."
