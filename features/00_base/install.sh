#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

# stow_pkg backs up any existing real file before symlinking, so conflicts
# are handled without overwriting the repo's curated dotfiles.
stow_pkg "$(dirname "$0")/dotfiles" base
