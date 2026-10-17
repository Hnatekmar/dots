#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

# Global identity for commits. `git config --global` edits ~/.gitconfig in
# place, so unrelated settings (aliases, signing, etc.) are preserved. Each
# key is only written when it differs, which keeps the feature idempotent.
GIT_USER_NAME="Hnatekmar"
GIT_USER_EMAIL="m.hnatma@gmail.com"

set_git_config() {
    local key="$1"
    local value="$2"
    local current

    current="$(git config --global --get "$key" || true)"
    if [ "$current" = "$value" ]; then
        echo "==> git $key already set to $value, skipping"
        return 0
    fi

    git config --global "$key" "$value"
    echo "==> git $key set to $value"
}

echo "==> Configuring git..."
set_git_config user.name "$GIT_USER_NAME"
set_git_config user.email "$GIT_USER_EMAIL"
echo "==> git configured."
