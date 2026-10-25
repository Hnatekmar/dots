#!/bin/sh
# Managed by dots: features/02_opencode/install.sh installs this file to
# ~/.local/bin/opencode, which bootstrap.sh puts ahead of the vendor binary.
#
# Why a wrapper: opencode has no config key for the model-catalog fetch, so the
# network switches have to live in the environment. A wrapper is the only place
# that covers every launch path — the TUI, `run`, cron, systemd, and the managed
# service, which the CLI spawns with its own environment inherited from here.
# Exporting in ~/.zshrc would miss the non-shell paths.
#
#   OPENCODE_DISABLE_MODELS_FETCH  stop the models.dev catalog fetch
#   OPENCODE_DISABLE_AUTOUPDATE    stop the update check ("autoupdate": false in
#                                  opencode.json also disables it; this covers a
#                                  config that fails to load)
#   OPENCODE_DISABLE_FREE_MODELS   drop the hosted free-tier models from the
#                                  catalog, so a request cannot fall through to
#                                  opencode's own API
#   DO_NOT_TRACK                   cross-tool opt-out; opencode is not verified
#                                  to read it, the three above are
set -eu

# Defaults, not overrides: an explicit value in the environment wins, so a
# single run can opt back in (OPENCODE_DISABLE_MODELS_FETCH=0 opencode).
OPENCODE_DISABLE_MODELS_FETCH=${OPENCODE_DISABLE_MODELS_FETCH:-1}
OPENCODE_DISABLE_AUTOUPDATE=${OPENCODE_DISABLE_AUTOUPDATE:-1}
OPENCODE_DISABLE_FREE_MODELS=${OPENCODE_DISABLE_FREE_MODELS:-1}
DO_NOT_TRACK=${DO_NOT_TRACK:-1}

export OPENCODE_DISABLE_MODELS_FETCH OPENCODE_DISABLE_AUTOUPDATE \
       OPENCODE_DISABLE_FREE_MODELS DO_NOT_TRACK

exec "${OPENCODE_BIN:-$HOME/.opencode/bin/opencode}" "$@"
