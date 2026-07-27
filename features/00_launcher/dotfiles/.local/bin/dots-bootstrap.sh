#!/bin/bash
set -euo pipefail

# dots-bootstrap.sh — ergonomic entry point for updating/reinstalling tools.
# Stowed into ~/.local/bin by the 00_launcher feature.
# Self-locates the repo via the stow symlink and runs feature installers.

# Resolve real path (follows the stow symlink back into the repo)
SCRIPT_REAL="$(readlink -f "$0")"
dir="$(dirname "$SCRIPT_REAL")"
DOTS_ROOT=""
while [ "$dir" != "/" ]; do
    if [ -f "$dir/bootstrap.sh" ]; then
        DOTS_ROOT="$dir"
        break
    fi
    dir="$(dirname "$dir")"
done

if [ -z "$DOTS_ROOT" ]; then
    echo "ERROR: could not locate dots repo (no bootstrap.sh found above $SCRIPT_REAL)" >&2
    exit 1
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
export PATH="/usr/local/go/bin:$HOME/go/bin:$HOME/.cargo/bin:$PATH"

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
