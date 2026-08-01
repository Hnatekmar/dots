#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

# Stow handles replacing existing symlinks and conflicts, but stow >= 2.4 adopts
# (overwrites repo files with) any existing unmanaged dotfile, so back those up first.
stow_pkg "$(dirname "$0")/dotfiles" base
