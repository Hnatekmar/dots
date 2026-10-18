#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../utils.sh"

OPENCODE_VERSION=2.0.32
# The skill installer is a tool too: pin it so a bootstrap months from now
# behaves like today's. Bump deliberately, then re-run this feature.
SKILLS_CLI_VERSION=1.7.2
CACHE_KEY="opencode/${OPENCODE_VERSION}"

# Drop skill trees that an older revision of this repo stowed. They are
# installed by `npx skills` now (see below), and a stale copy in
# ~/.config/opencode/skills would shadow the fresh one. Only trees made
# entirely of symlinks are removed: a directory holding real files belongs to
# the user and stays.
prune_stowed_skill_tree() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    if [ -n "$(find "$dir" -type f -print -quit)" ]; then
        echo "==> Keeping $dir (it holds real files, not stow symlinks)"
        return 0
    fi
    rm -rf "$dir"
}

for bucket in engineering in-progress misc productivity deprecated; do
    prune_stowed_skill_tree "$HOME/.config/opencode/skills/$bucket"
done

stow_pkg "$(dirname "$0")/dotfiles" opencode

# Shared skill set from mattpocock/skills. `npx skills` resolves the repo,
# picks the skill folders and copies them to opencode's global
# agent-compatible dir (~/.agents/skills), which opencode loads alongside
# ~/.config/opencode/skills. --copy keeps plain files (no symlinks into
# npx's cache); DO_NOT_TRACK=1 disables the CLI's install telemetry.
install_shared_skills() {
    if ! command -v npx >/dev/null 2>&1; then
        echo "WARN: npx not found (run 00_node first); skipping the shared skill set" >&2
        return 0
    fi
    echo "==> Installing mattpocock/skills via npx skills@${SKILLS_CLI_VERSION}"
    if DO_NOT_TRACK=1 npx -y "skills@${SKILLS_CLI_VERSION}" add mattpocock/skills \
        --skill '*' -a opencode -g --copy -y; then
        echo "==> Shared skill set installed in ~/.agents/skills"
    else
        echo "WARN: 'npx skills add' failed; re-run this feature to retry" >&2
    fi
}

install_shared_skills

if check_command_version opencode "$OPENCODE_VERSION"; then
    echo "==> opencode $OPENCODE_VERSION already installed, skipping"
    exit 0
fi

TMP_FOLDER=$(mktemp -d)
trap 'rm -rf "$TMP_FOLDER"' EXIT

# Cache the vendor installer too, so a re-run does not depend on opencode.ai.
fetch_cached "https://opencode.ai/v2/install" "$CACHE_KEY/install.sh" "$TMP_FOLDER/install.sh"

# Mirror the vendor installer's download step, but pull the ~80 MB npm tarball
# through the cache and verify npm's own sha512 integrity hash (the vendor
# installer verifies nothing). Returns non-zero when the package cannot be
# resolved, so the caller can fall back to the vendor installer.
install_from_cache() {
    local target url integrity digest_hex tgz parsed
    target="linux-$(map_arch x64 arm64)"

    # Same target selection as the vendor installer: "-baseline" on x86_64 CPUs
    # without AVX2, "-musl" on musl-based distros (e.g. Alpine).
    if [ "$(uname -m)" = "x86_64" ] && ! grep -qwi avx2 /proc/cpuinfo 2>/dev/null; then
        target="${target}-baseline"
    fi
    if [ -f /etc/alpine-release ] ||
        { command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl; }; then
        target="${target}-musl"
    fi

    fetch_cached "https://registry.npmjs.org/@opencode%2fcli-${target}/${OPENCODE_VERSION}" \
        "$CACHE_KEY/cli-${target}.json" "$TMP_FOLDER/cli-${target}.json" || return 1

    parsed=$(python3 -c '
import json, sys
with open(sys.argv[1]) as fh:
    dist = json.load(fh).get("dist", {})
url = dist.get("tarball", "")
integrity = dist.get("integrity", "")
if not url or not integrity.startswith("sha512-"):
    sys.exit(1)
print(url)
print(integrity)
' "$TMP_FOLDER/cli-${target}.json") || return 1

    { read -r url; read -r integrity; } <<< "$parsed"

    tgz="$TMP_FOLDER/$(basename "$url")"
    digest_hex=$(printf '%s' "${integrity#sha512-}" | base64 -d | od -An -v -tx1 | tr -d ' \n')
    fetch_cached "$url" "$CACHE_KEY/$(basename "$url")" "$tgz" "sha512:${digest_hex}" || return 1

    mkdir -p "$TMP_FOLDER/extract"
    tar -xzf "$tgz" -C "$TMP_FOLDER/extract" package/bin/opencode || return 1

    # --binary keeps the vendor installer's install layout and legacy shim
    # while skipping its own (uncached) download.
    bash "$TMP_FOLDER/install.sh" --no-modify-path \
        --binary "$TMP_FOLDER/extract/package/bin/opencode"
}

if ! install_from_cache; then
    echo "WARN: could not resolve the npm package, using the vendor installer" >&2
    # --no-modify-path: the installer would append a PATH export to ~/.bashrc,
    # which is not ours to edit. The symlink below exposes the binary through
    # ~/.local/bin instead, which bootstrap.sh already puts on PATH.
    bash "$TMP_FOLDER/install.sh" --version "$OPENCODE_VERSION" --no-modify-path
fi

mkdir -p "$HOME/.local/bin"
ln -sfn "$HOME/.opencode/bin/opencode" "$HOME/.local/bin/opencode"
