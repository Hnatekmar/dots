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

  DOTS_FORCE=1 in the environment is equivalent to --force.
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
