#!/bin/bash
set -euo pipefail

DOTS_ROOT="$(cd "$(dirname "$0")" && pwd)"

# If invoked via sudo, operate on the invoking user's home, not /root.
# Otherwise cargo, go-installed binaries, stowed dotfiles and the launcher
# would all land in /root and never appear in the user's shell.
if [ "$(id -u)" = "0" ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    export HOME
fi

# shellcheck source=features/utils.sh
source "$DOTS_ROOT/features/utils.sh"

# Install build prerequisites + stow. Names differ slightly per distro
# (python vs python3), so handle them explicitly in one place. Everything
# else in the repo is built from source (go install / cargo install) and is
# fully distro-agnostic.
echo "==> Installing prerequisites..."
if command -v dnf >/dev/null 2>&1; then
    dnf install -y git curl tar findutils python3 gcc make stow zsh
elif command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y git curl tar findutils python3 gcc make stow zsh
elif command -v pacman >/dev/null 2>&1; then
    pacman -S --noconfirm --needed git curl tar findutils python gcc make stow zsh
else
    echo "ERROR: no supported package manager (dnf/apt-get/pacman)" >&2
    exit 1
fi

# Ensure go + cargo + go-installed binaries are in PATH for all feature installers
export PATH="/usr/local/go/bin:$HOME/go/bin:$HOME/.cargo/bin:$PATH"

# Run feature installers in lexical order
for feature_dir in "$DOTS_ROOT"/features/*/; do
    [ -d "$feature_dir" ] && [ -f "$feature_dir/install.sh" ] && {
        echo "==> Installing feature: $(basename "$feature_dir")"
        (cd "$feature_dir" && bash install.sh)
    }
done
