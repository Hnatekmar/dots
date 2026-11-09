#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

# npm's "stable" channel. `latest` runs a few patches ahead of it; this repo
# pins releases, so track stable and bump deliberately.
CLAUDE_VERSION=2.1.311

# Install into node's own prefix rather than whatever npm considers global: a
# bootstrap that found a system node would otherwise need root to write
# /usr/local/lib/node_modules. ~/.local/node/bin is on PATH already.
NODE_PREFIX="$HOME/.local/node"

if check_command_version claude "$CLAUDE_VERSION"; then
    echo "==> claude $CLAUDE_VERSION already installed, skipping"
    exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "ERROR: npm not found (run 00_node first)" >&2
    exit 1
fi

# The npm package is a ~190 KB wrapper; its postinstall copies the native
# binary out of the matching optionalDependency (@anthropic-ai/claude-code-
# linux-x64 and friends), so `claude` needs no node at runtime.
#
# npm verifies the registry's SHA512 integrity hash for the wrapper and the
# native package. The tarballs do not go through fetch_cached: the postinstall
# resolves the platform package itself, and replaying that by hand would tie
# this installer to npm's internal layout. --cache still points npm at the dots
# cache, so a fleet re-provision shares the download.
NPM_ARGS=(install -g --prefix "$NODE_PREFIX" --no-fund --no-audit --loglevel=error)
CACHE_ROOT="$(dots_cache_dir)"
if [ -n "$CACHE_ROOT" ] && mkdir -p "$CACHE_ROOT/npm" 2>/dev/null && [ -w "$CACHE_ROOT/npm" ]; then
    NPM_ARGS+=(--cache "$CACHE_ROOT/npm")
fi

echo "==> Installing Claude Code $CLAUDE_VERSION..."
npm "${NPM_ARGS[@]}" "@anthropic-ai/claude-code@${CLAUDE_VERSION}"

# An npmrc with `ignore-scripts=true` (corporate image, hardened user config)
# skips the postinstall and leaves the placeholder stub behind. Fail here with
# the reason instead of at first use.
if ! "$NODE_PREFIX/bin/claude" --version >/dev/null 2>&1; then
    echo "ERROR: claude installed but does not run; check npm's ignore-scripts setting" >&2
    exit 1
fi

echo "==> claude $("$NODE_PREFIX/bin/claude" --version | head -1) installed to $NODE_PREFIX/bin."
