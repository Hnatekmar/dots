#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

# Standalone runs (`bash features/08_hermes/install.sh`) do not get bootstrap's
# PATH export, and the installer publishes its launcher into ~/.local/bin.
export PATH="$HOME/.local/bin:$PATH"

FEATURE_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$HOME/.hermes/config.yaml"
STOCK_CONFIG="$HOME/.hermes/hermes-agent/cli-config.yaml.example"

# Seed the config before the version gate: a machine that already has a current
# hermes still needs the provider, and the gate exits 0. Hermes rewrites its own
# config (`hermes model`, `config set`, update migrations), so this is a
# one-time copy, not a stowed symlink. Seed only when the file is absent or is
# still the installer's untouched example; anything else was configured by hand
# and is left alone. --force re-seeds with a backup.
if [ ! -f "$CONFIG" ] || [ "${DOTS_FORCE:-0}" = "1" ] ||
    { [ -f "$STOCK_CONFIG" ] && [ "$(digest_of "$CONFIG" sha256)" = "$(digest_of "$STOCK_CONFIG" sha256)" ]; }; then
    # `bak-dots-<ts>`: Hermes sweeps its own `config.yaml.bak.<digits>` siblings
    # into ~/.hermes/backups/config on startup, hand-named copies it leaves be.
    if [ -f "$CONFIG" ]; then
        cp -f "$CONFIG" "$CONFIG.bak-dots-$(date +%Y%m%d%H%M%S)"
    fi
    mkdir -p "$(dirname "$CONFIG")"
    cp -f "$FEATURE_DIR/config.yaml" "$CONFIG"
    chmod 600 "$CONFIG"
    echo "==> Seeded $CONFIG from features/08_hermes/config.yaml"
fi

# Hermes Agent — the long-running coding agent. Upstream publishes no wheel
# (setup.py refuses to build one), no standalone binary and no source tarball:
# the shell installer is the supported path. It clones the tree into
# ~/.hermes/hermes-agent, resolves dependencies through pm (hash-verified
# against uv.lock) and publishes the launcher as ~/.local/bin/hermes.
HERMES_VERSION=0.22.5
HERMES_COMMIT=bf0203a794a07aac3ff764972ab9087baa4e4f4e

if check_command_version hermes "$HERMES_VERSION"; then
    echo "==> Hermes Agent $HERMES_VERSION already installed, skipping"
    exit 0
fi

# The installer script itself is unversioned (it tracks main), so the release
# commit is what pins this feature. A pin must match the installer's current
# layout: pm/ landed after v0.21.5, and an older commit fails loudly when the
# served script looks for pm/lock.json. Bump the commit with the version.
INSTALLER=$(mktemp)
trap 'rm -f "$INSTALLER"' EXIT
fetch_cached "https://hermes-agent.nousresearch.com/install.sh" \
    "hermes/${HERMES_VERSION}/install.sh" "$INSTALLER"

echo "==> Installing Hermes Agent $HERMES_VERSION..."
# SHELL=zsh on purpose. The installer appends a PATH guard line to the rc file
# matching $SHELL; ~/.bash_profile here is a symlink into this repo and carries
# no PATH line, so the bash branch would write through it and dirty the
# checkout. ~/.zshrc already exports ~/.local/bin, so its guard matches and it
# is left untouched (~/.zprofile is created, which is harmless).
#
# --non-interactive skips the setup/gateway wizards; both are `hermes setup`
# and `hermes gateway install` afterwards. The browser (Chromium) and
# computer-use driver are ~1 GB of optional downloads: add them with
# `hermes pm install chromium` / `hermes pm install cua-driver`.
SHELL=/usr/bin/zsh bash "$INSTALLER" --non-interactive \
    --skip-browser --skip-computer-use --commit "$HERMES_COMMIT"

check_command_version hermes "$HERMES_VERSION" \
    || { echo "ERROR: hermes $HERMES_VERSION is not on PATH after install" >&2; exit 1; }

echo "==> Hermes Agent $HERMES_VERSION installed (config: ~/.hermes/config.yaml)."
