#!/bin/bash
set -euo pipefail

# Source common functions (check_command_version, version_gte, stow_pkg)
source "$(dirname "$0")/../utils.sh"

# 1) Pin the version to install
TOOL_VERSION=0.0.0

# 2) Idempotency gate: skip when already installed (version >= pinned).
#    Returns 1 when DOTS_FORCE=1, which forces a reinstall.
#    If the tool's --version output is not a plain N.N.N number, add a
#    matching case branch in features/utils.sh or the check will misparse.
if check_command_version mytool "$TOOL_VERSION"; then
    echo "==> mytool $TOOL_VERSION already installed, skipping"
    exit 0
fi

# 3) Install. Must stay distro-agnostic (no dnf/apt/pacman in features):
#      Go:     go install "github.com/org/repo@v${TOOL_VERSION}"
#      Rust:   cargo install --locked "mytool@${TOOL_VERSION}"
#      Binary: download the pinned release and verify SHA256 before installing
#    If this feature needs another tool (e.g. go), run its installer first:
#      bash "$(dirname "$0")/../00_go/install.sh"
echo "==> Installing mytool $TOOL_VERSION..."
# ...

# 4) Optional: symlink dotfiles/ into $HOME via stow_pkg (delete the empty
#    dotfiles/ dir if not needed). stow_pkg backs up any existing real file
#    before symlinking, so the user's live config is never silently overwritten.
# stow_pkg "$(dirname "$0")/dotfiles" <package-name>

echo "==> mytool $TOOL_VERSION installed."
