#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

ROCKETCHAT_MCP_VERSION=0.1.0

FEATURE_DIR="$(cd "$(dirname "$0")" && pwd)"

# The config script is a symlink, so it tracks the checkout without a copy step.
mkdir -p "$HOME/.local/bin"
ln -sfn "$FEATURE_DIR/dotfiles/.local/bin/dots-rocketchat-mcp" "$HOME/.local/bin/dots-rocketchat-mcp"
chmod +x "$FEATURE_DIR/dotfiles/.local/bin/dots-rocketchat-mcp"

if check_command_version rocketchat-mcp "$ROCKETCHAT_MCP_VERSION"; then
    echo "==> rocketchat-mcp $ROCKETCHAT_MCP_VERSION already installed, skipping"
else
    # Release assets are named with Go's GOARCH, not uname's.
    ARCH="$(map_arch amd64 arm64)"
    CACHE_KEY="rocketchat-mcp/${ROCKETCHAT_MCP_VERSION}"
    BASE="https://github.com/zelvinator/rocketchat-mcp/releases/download/v${ROCKETCHAT_MCP_VERSION}"
    ASSET="rocketchat-mcp_${ROCKETCHAT_MCP_VERSION}_linux_${ARCH}.tar.gz"
    # The tarball carries one directory holding the binary and the README.
    DIR="${ASSET%.tar.gz}"

    TMP_FOLDER=$(mktemp -d)
    trap 'rm -rf "$TMP_FOLDER"' EXIT

    echo "==> Installing rocketchat-mcp $ROCKETCHAT_MCP_VERSION..."
    fetch_cached "$BASE/checksums.txt" "$CACHE_KEY/checksums.txt" "$TMP_FOLDER/checksums.txt"
    # GoReleaser lists assets as "./<name>", so match on the basename.
    EXPECTED=$(awk -v f="$ASSET" '{n = $2; sub(/^\.\//, "", n); if (n == f) print $1}' "$TMP_FOLDER/checksums.txt")
    [ -n "$EXPECTED" ] || { echo "ERROR: $ASSET missing from rocketchat-mcp checksums.txt" >&2; exit 1; }

    fetch_cached "$BASE/$ASSET" "$CACHE_KEY/$ASSET" "$TMP_FOLDER/$ASSET" "$EXPECTED"
    tar -xzf "$TMP_FOLDER/$ASSET" -C "$TMP_FOLDER" "$DIR/rocketchat-mcp"
    install_bin "$TMP_FOLDER/$DIR/rocketchat-mcp" rocketchat-mcp

    echo "==> rocketchat-mcp $ROCKETCHAT_MCP_VERSION installed."
fi

# Register the server with Claude Code when credentials are already on the
# machine. Opt-in by file presence: a fresh box has no token, and this must not
# be the reason a bootstrap fails.
ENV_FILE="${ROCKETCHAT_MCP_ENV:-${XDG_CONFIG_HOME:-$HOME/.config}/rocketchat-mcp/env}"
if [ -f "$ENV_FILE" ] && command -v claude >/dev/null 2>&1; then
    if "$HOME/.local/bin/dots-rocketchat-mcp" >/dev/null; then
        echo "==> Rocket.Chat MCP registered with Claude Code"
    else
        echo "WARN: could not register the Rocket.Chat MCP; run dots-rocketchat-mcp to see why" >&2
    fi
fi
