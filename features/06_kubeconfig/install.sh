#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.local/bin"

mkdir -p "$TARGET_DIR"
ln -sfn "$SCRIPT_DIR/dotfiles/.local/bin/dots-kubeconfig" "$TARGET_DIR/dots-kubeconfig"
chmod +x "$SCRIPT_DIR/dotfiles/.local/bin/dots-kubeconfig"

# Always refresh: the committed kubeconfig carries the cluster CA, and a
# rebuilt cluster has a new one. Version gating would freeze a stale CA.
echo "==> Refreshing devops-cluster kubeconfigs (dev, prod)..."
"$TARGET_DIR/dots-kubeconfig" all

echo "==> kubeconfig installed. Contexts: dev-k8s, prod-k8s (kubelogin authenticates on first use)."
