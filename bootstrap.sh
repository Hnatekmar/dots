#!/bin/bash
set -euo pipefail

DOTS_ROOT="$(cd "$(dirname "$0")" && pwd)"

DNF_PACKAGES=(git stow)

dnf install -y "${DNF_PACKAGES[@]}"

# Ensure go is in PATH for all feature installers
export PATH=/usr/local/go/bin:$PATH

# Run feature installers in lexical order
for feature_dir in "$DOTS_ROOT"/features/*/; do
    [ -d "$feature_dir" ] && [ -f "$feature_dir/install.sh" ] && {
        echo "==> Installing feature: $(basename "$feature_dir")"
        (cd "$feature_dir" && bash install.sh)
    }
done
