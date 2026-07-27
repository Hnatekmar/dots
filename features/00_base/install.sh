#!/bin/bash
set -euo pipefail

# Stow handles replacing existing symlinks and conflicts.
# No need for destructive rm -rf.
cd "$(dirname "$0")/dotfiles"
stow -t "$HOME" -R base
