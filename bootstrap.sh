#!/bin/bash
set -euo pipefail

DOTS_ROOT="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=features/utils.sh
source "$DOTS_ROOT/features/utils.sh"

# Install build prerequisites. Names differ slightly per distro
# (python vs python3), so handle them explicitly in one place. Everything
# else in the repo is built from source (go install / cargo install) and is
# fully distro-agnostic. Requires root for system package installation;
# when running as a non-root user, we check for prereqs instead.
# Note: zsh, git, and curl are system packages; stow is replaced by a
# built-in symlink function (stow_pkg in features/utils.sh).

echo "==> Checking prerequisites..."
if [ "$(id -u)" = "0" ]; then
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y git curl tar findutils python3 gcc make zsh
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq && apt-get install -y git curl tar findutils python3 gcc make zsh
    elif command -v pacman >/dev/null 2>&1; then
        pacman -S --noconfirm --needed git curl tar findutils python gcc make zsh
    else
        echo "ERROR: no supported package manager (dnf/apt-get/pacman)" >&2
        exit 1
    fi
else
    MISSING=""
    for cmd in git curl tar find python3 gcc make zsh; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            MISSING="$MISSING $cmd"
        fi
    done
    if [ -n "$MISSING" ]; then
        echo "ERROR: missing required commands:$MISSING" >&2
        echo "       Install them via your package manager (requires root), then re-run." >&2
        exit 1
    fi
fi

# Ensure go + cargo + go-installed binaries are in PATH for all feature installers
export PATH="$HOME/.local/go/bin:$HOME/go/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Run feature installers in lexical order
for feature_dir in "$DOTS_ROOT"/features/*/; do
    [ -d "$feature_dir" ] && [ -f "$feature_dir/install.sh" ] && {
        echo "==> Installing feature: $(basename "$feature_dir")"
        (cd "$feature_dir" && bash install.sh)
    }
done
