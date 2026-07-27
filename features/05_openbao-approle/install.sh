#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

# Install the bao binary if not present (delegates to 04_openbao)
if ! command -v bao &>/dev/null; then
    echo "==> Installing OpenBao binary..."
    bash "$(dirname "$0")/../04_openbao/install.sh"
fi

echo "==> OpenBao AppRole feature installed."
echo "==> To enroll this machine: bao login -method=oidc role=operator && bash features/05_openbao-approle/bootstrap-approle.sh"
echo "==> bootstrap-approle.sh generates ~/.local/bin/bao-auth and ~/.config/direnv/lib/bao.sh."
