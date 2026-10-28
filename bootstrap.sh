#!/bin/bash
set -euo pipefail

DOTS_ROOT="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# If invoked via sudo, operate on the invoking user's home, not /root.
if [ "$(id -u)" = "0" ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    export HOME
fi

DOTS_FORCE="${DOTS_FORCE:-0}"
ONLY=""

usage() {
    cat <<EOF
Usage: dots-bootstrap.sh [--force] [--only <feature>] [--list]

  --force          Reinstall all tools even if version checks pass.
  --only <feature> Run a single feature (e.g. 00_go, 02_ripgrep).
  --list           Print available features and exit.

Environment:
  DOTS_FORCE=1             Equivalent to --force.
  DOTS_CACHE_DIR=<path>    Where downloads are cached (default
                           \${XDG_CACHE_HOME:-\$HOME/.cache}/dots). Point it at
                           a shared directory to reuse downloads across
                           machines; set it to an empty string to disable.
  #  DOTS_BUILD_FROM_SOURCE=1 Build gum/ripgrep/fd/fzf/hyperfine/superfile/zoxide/lsd/
                             #  yq/k9s/kubecolor/herdr from source instead of install-
                             #  ing the pinned release binaries.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --force) DOTS_FORCE=1; shift ;;
        --only)  ONLY="${2:-}"; shift 2 ;;
        --list)
            for d in "$DOTS_ROOT"/features/*/; do
                [ -f "$d/install.sh" ] && basename "$d"
            done
            exit 0
            ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

export DOTS_FORCE

# Install build prerequisites. Names differ slightly per distro
# (python vs python3), so handle them explicitly in one place. Tool installs
# are distro-agnostic: pinned release binaries where upstream publishes them,
# plus the Go toolchain (gopls build) and rustup. Requires root for system
# package installation; when running as a non-root user, we check for prereqs.
# Note: zsh, git, and curl are system packages; stow is replaced by a
# built-in symlink function (stow_pkg in features/utils.sh).

echo "==> Checking prerequisites..."
if [ "$(id -u)" = "0" ]; then
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y git curl tar findutils python3 gcc make zsh socat
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq && apt-get install -y git curl tar findutils python3 gcc make zsh socat
    elif command -v pacman >/dev/null 2>&1; then
        pacman -S --noconfirm --needed git curl tar findutils python gcc make zsh socat
    else
        echo "ERROR: no supported package manager (dnf/apt-get/pacman)" >&2
        exit 1
    fi
else
    MISSING=""
    for cmd in git curl tar find python3 gcc make zsh socat; do
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

# Ensure node + go + cargo + go-installed binaries are in PATH for all feature installers
export PATH="$HOME/.local/node/bin:$HOME/.local/go/bin:$HOME/go/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Make zsh the login shell. This is a system-level setting, so it belongs here
# next to the prerequisite installation rather than in a feature. chsh is
# setuid: root can change it unattended, while a non-root run prints the
# command for the user to run instead of hanging on a password prompt.
ZSH_PATH="$(command -v zsh || true)"
if [ -n "$ZSH_PATH" ]; then
    SHELL_USER="${SUDO_USER:-$(id -un)}"
    CURRENT_SHELL="$(getent passwd "$SHELL_USER" | cut -d: -f7)"
    if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
        echo "==> $SHELL_USER already uses zsh as the default shell"
    elif [ "$(id -u)" = "0" ] && command -v chsh >/dev/null 2>&1; then
        if chsh -s "$ZSH_PATH" "$SHELL_USER"; then
            echo "==> Default shell for $SHELL_USER set to $ZSH_PATH (log in again to use it)"
        else
            echo "WARN: could not change the default shell for $SHELL_USER" >&2
        fi
    else
        echo "==> To make zsh the default shell: chsh -s \"$ZSH_PATH\""
    fi
fi

# Where downloads land. Reported up front because a shared cache (NAS) is the
# difference between a fast re-run and re-downloading every toolchain.
if [ "${DOTS_CACHE_DIR+x}" = "x" ]; then
    if [ -n "$DOTS_CACHE_DIR" ]; then
        echo "==> Download cache: $DOTS_CACHE_DIR"
    else
        echo "==> Download cache: disabled (DOTS_CACHE_DIR is empty)"
    fi
else
    echo "==> Download cache: ${XDG_CACHE_HOME:-$HOME/.cache}/dots"
fi

# Run feature installers in lexical order
run_feature() {
    local feature_dir="$1"
    echo "==> Installing feature: $(basename "$feature_dir")"
    (cd "$feature_dir" && bash install.sh)
}

if [ -n "$ONLY" ]; then
    feature_dir="$DOTS_ROOT/features/$ONLY"
    if [ ! -d "$feature_dir" ] || [ ! -f "$feature_dir/install.sh" ]; then
        echo "ERROR: feature '$ONLY' not found. Use --list to see options." >&2
        exit 1
    fi
    run_feature "$feature_dir"
else
    for feature_dir in "$DOTS_ROOT"/features/*/; do
        [ -d "$feature_dir" ] && [ -f "$feature_dir/install.sh" ] && run_feature "$feature_dir"
    done
fi
