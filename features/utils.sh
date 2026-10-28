#!/bin/bash

# Version comparison: returns 0 if installed >= required, 1 otherwise.
# `sort -V` handles multi-digit components correctly (0.9 < 0.87, 1.9 < 1.26).
# ponytail: version-sort semantics, so 2 < 2.0; all pinned versions are 3-component.
version_gte() {
    [[ -z "$2" ]] && return 0
    [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | tail -1)" = "$1" ]
}

# Symlink a package's dotfiles into $HOME, first backing up any existing real
# file it would replace. Replaces GNU stow with a minimal per-file symlink loop.
stow_pkg() {
    local dotfiles_dir="$1"
    local pkg="$2"
    local now
    now="$(date +%Y%m%d%H%M%S)"

    # Resolve to absolute path so symlinks remain valid from any cwd.
    dotfiles_dir="$(cd "$dotfiles_dir" && pwd)"

    # Process substitution keeps the loop in the current shell so `local` is legal.
    while IFS= read -r f; do
        local rel="${f#*/}"
        local target="$HOME/$rel"

        # Skip if the target or any parent dir is already a symlink to the repo
        # (managed by a previous stow_pkg run). This prevents walking into an
        # existing symlink and treating the repo's own files as "existing".
        local skip=0
        local check="$HOME"
        local rem="$rel"
        while [ -n "$rem" ]; do
            check="$check/${rem%%/*}"
            if [ -L "$check" ]; then skip=1; break; fi
            # ${rem#*/} only strips when a slash exists; without this guard the
            # last component (no trailing slash) would loop forever.
            if [[ "$rem" == */* ]]; then rem="${rem#*/}"; else rem=""; fi
        done
        [ "$skip" = 1 ] && continue

        if [ -e "$target" ]; then
            echo "==> Backing up existing $target to $target.bak.$now"
            mv "$target" "$target.bak.$now"
        fi

        # Create parent directories and symlink the file into $HOME.
        mkdir -p "$(dirname "$target")"
        ln -sfn "$dotfiles_dir/$f" "$target"
    done < <(cd "$dotfiles_dir" && find "$pkg" \( -type f -o -type l \) -print)
}

# Print the digest of a file. A "sha512:" prefix selects SHA512; a bare hex
# string (or "sha256:" prefix) selects SHA256.
digest_of() {
    case "$2" in
        sha512:*) sha512sum "$1" | cut -d' ' -f1 ;;
        *)        sha256sum "$1" | cut -d' ' -f1 ;;
    esac
}

# Compare a file against an expected digest: "<sha256-hex>" or "sha512:<hex>".
digest_is() {
    local expected="$2"
    case "$expected" in
        sha512:*) expected="${expected#sha512:}" ;;
        sha256:*) expected="${expected#sha256:}" ;;
    esac
    [ -n "$expected" ] && [ "$(digest_of "$1" "$2")" = "$expected" ]
}

# Verify a downloaded file against an expected SHA256 hex digest. Exits on mismatch.
verify_sha256() {
    local file="$1"
    local expected="$2"
    if [ -z "$expected" ] || ! digest_is "$file" "$expected"; then
        echo "ERROR: checksum mismatch for $file" >&2
        echo "  Expected: ${expected:-<none>}" >&2
        echo "  Actual:   $(digest_of "$file" "$expected" 2>/dev/null)" >&2
        exit 1
    fi
}

# ── Download cache ────────────────────────────────────────────────────────
# Every downloaded artifact goes through fetch_cached, which keeps a copy in
# DOTS_CACHE_DIR. Entries are laid out as <tool>/<version>/<filename> so a
# shared cache stays browsable and pinned versions never collide.
#
#   DOTS_CACHE_DIR=/mnt/nas/cache/dots   # shared cache (e.g. dev-envs NAS)
#   DOTS_CACHE_DIR=""                    # disable caching
#
# Unset falls back to ${XDG_CACHE_HOME:-$HOME/.cache}/dots.
dots_cache_dir() {
    if [ -n "${DOTS_CACHE_DIR+x}" ]; then
        printf '%s\n' "$DOTS_CACHE_DIR"
    else
        printf '%s\n' "${XDG_CACHE_HOME:-$HOME/.cache}/dots"
    fi
}

# fetch_cached <url> <cache-key> <dest> [digest]
#
# Download <url> to <dest>, reusing the cached copy when one exists. Passing a
# digest (bare SHA256 hex or "sha512:<hex>") verifies the artifact — on cache
# hits too, so a corrupted shared cache fails loudly instead of installing a
# broken binary. Cache writes land under a temporary name and are renamed into
# place, so parallel bootstraps sharing one cache never observe a partial file.
fetch_cached() {
    local url="$1" key="$2" dest="$3" expected="${4:-}"
    local root
    root="$(dots_cache_dir)"

    if [ -n "$root" ] && [ -s "$root/$key" ]; then
        if cp -f "$root/$key" "$dest" 2>/dev/null &&
            { [ -z "$expected" ] || digest_is "$dest" "$expected"; }; then
            echo "==> cache hit: $key"
            return 0
        fi
        echo "WARN: cache entry unusable ($key), downloading again" >&2
        rm -f "$dest"
    fi

    echo "==> Downloading $url"

    # Cache-write path: download beside the final entry, verify, then rename.
    # Falls through to a plain download when the cache is not writable (e.g. a
    # read-only NAS mount), so a shared cache never becomes a hard dependency.
    if [ -n "$root" ] && mkdir -p "$root/$(dirname "$key")" 2>/dev/null &&
        [ -w "$root/$(dirname "$key")" ]; then
        local tmp
        tmp="$(mktemp "$root/$key.XXXXXX")"
        if curl -fsSL --connect-timeout 15 --speed-limit 1024 --speed-time 60 --retry 3 --retry-delay 2 --retry-all-errors -o "$tmp" "$url"; then
            if [ -n "$expected" ] && ! digest_is "$tmp" "$expected"; then
                echo "ERROR: checksum mismatch for $url" >&2
                echo "  Expected: $expected" >&2
                echo "  Actual:   $(digest_of "$tmp" "$expected")" >&2
                rm -f "$tmp"
                exit 1
            fi
            chmod 0644 "$tmp" 2>/dev/null || true
            mv -f "$tmp" "$root/$key"
            cp -f "$root/$key" "$dest"
            return 0
        fi
        rm -f "$tmp"
        return 1
    fi

    curl -fsSL --connect-timeout 15 --speed-limit 1024 --speed-time 60 --retry 3 --retry-delay 2 --retry-all-errors -o "$dest" "$url"
    [ -z "$expected" ] || verify_sha256 "$dest" "$expected"
}

# Install a prebuilt binary into ~/.local/bin. Copies left behind by older
# source builds in ~/go/bin or ~/.cargo/bin are removed: both directories
# precede ~/.local/bin on PATH, so a stale copy would shadow the new binary.
install_bin() {
    local src="$1"
    local name="$2"
    mkdir -p "$HOME/.local/bin"
    cp -f "$src" "$HOME/.local/bin/$name"
    chmod 0755 "$HOME/.local/bin/$name"
    rm -f "$HOME/go/bin/$name" "$HOME/.cargo/bin/$name"
}

# ── Pinned digests ────────────────────────────────────────────────────────
# features/checksums.txt holds digests for release assets whose upstream
# publishes no usable checksum file. Lookup is by filename, since the asset name
# carries tool, version and architecture. Nothing is fetched at install time:
# the GitHub API allows 60 anonymous requests/hour/IP — a fleet of dev
# containers exhausts that — and a committed digest is a stronger guarantee
# than one fetched at install time.
checksums_file() {
    printf '%s/checksums.txt\n' "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# Print the pinned digest for an asset, or return 1 when it is not listed.
asset_sha256() {
    local asset="$1"
    local file
    file="$(checksums_file)"
    [ -f "$file" ] || return 1
    awk -v a="$asset" '$2 == a {print $1; found=1} END {exit !found}' "$file"
}

# Print the pinned digest for an asset, or exit naming the command that adds it.
require_asset_sha256() {
    local asset="$1"
    local digest
    if ! digest="$(asset_sha256 "$asset")" || [ -z "$digest" ]; then
        echo "ERROR: no pinned sha256 for $asset in features/checksums.txt" >&2
        echo "       add it with: scripts/add-checksum.sh <release-asset-url>" >&2
        exit 1
    fi
    printf '%s\n' "$digest"
}

# Map `uname -m` to tool-specific target names: map_arch <x86_64-name> <aarch64-name>
map_arch() {
    case "$(uname -m)" in
        x86_64)  echo "$1" ;;
        aarch64) echo "$2" ;;
        *) echo "ERROR: Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
    esac
}

check_command_version() {
    local cmd="$1"
    local expected="$2"

    # --force: always report "needs install" so installers re-run
    [ "${DOTS_FORCE:-0}" = "1" ] && return 1

    command -v "$cmd" &>/dev/null || return 1

    local actual=""

    case "$cmd" in
        go)
            actual=$(go version 2>/dev/null | sed -n 's/.*go\([0-9][0-9.]*\).*/\1/p')
            ;;
        nvim)
            actual=$(nvim --version 2>/dev/null | head -1 | sed -n 's/.*v\([0-9][0-9.]*\).*/\1/p')
            ;;
        gum)
            actual=$(gum --version 2>/dev/null | head -1 | sed -n 's/.*v\([0-9][0-9.]*\).*/\1/p')
            ;;
        bao)
            actual=$(bao version 2>/dev/null | head -1 | sed -n 's/OpenBao v\([0-9][0-9.]*\).*/\1/p')
            ;;
        rg)
            actual=$(rg --version 2>/dev/null | head -1 | sed -n 's/ripgrep \([0-9][0-9.]*\).*/\1/p')
            ;;
        fd)
            actual=$(fd --version 2>/dev/null | head -1 | sed -n 's/fd \([0-9][0-9.]*\).*/\1/p')
            ;;
        fzf)
            actual=$(fzf --version 2>/dev/null | head -1 | sed -n 's/^\([0-9][0-9.]*\).*/\1/p')
            ;;
        lsd)
            actual=$(lsd --version 2>/dev/null | head -1 | sed -n 's/^lsd \([0-9][0-9.]*\).*/\1/p')
            ;;
        hunk)
            actual=$(hunk --version 2>/dev/null | head -1 | sed -n 's/^\([0-9][0-9.]*\).*/\1/p')
            ;;
        zoxide)
            actual=$(zoxide --version 2>/dev/null | head -1 | sed -n 's/^zoxide \([0-9][0-9.]*\).*/\1/p')
            ;;
        herdr)
            actual=$(herdr --version 2>/dev/null | head -1 | sed -n 's/^herdr \([0-9][0-9.]*\).*/\1/p')
            ;;
        argocd)
            actual=$(argocd version --client --short 2>/dev/null | sed -n 's/^argocd: v\([0-9][0-9.]*\).*/\1/p')
            ;;
        argo)
            actual=$(argo version --short 2>/dev/null | sed -n 's/^argo: v\([0-9][0-9.]*\).*/\1/p')
            ;;
        talosctl)
            # Two lines: "Client:" then "Talos v1.14.5".
            actual=$(talosctl version --client --short 2>/dev/null | sed -n 's/^Talos v\([0-9][0-9.]*\).*/\1/p' | head -1)
            ;;
        stern)
            actual=$(stern --version 2>/dev/null | sed -n 's/^version: \([0-9][0-9.]*\).*/\1/p' | head -1)
            ;;
        kubeconform)
            actual=$(kubeconform -v 2>/dev/null | head -1 | sed -n 's/^v\([0-9][0-9.]*\).*/\1/p')
            ;;
        glow)
            actual=$(glow --version 2>/dev/null | head -1 | sed -n 's/^glow version \([0-9][0-9.]*\).*/\1/p')
            ;;
        just)
            actual=$(just --version 2>/dev/null | head -1 | sed -n 's/^just \([0-9][0-9.]*\).*/\1/p')
            ;;
        hyperfine)
            actual=$(hyperfine --version 2>/dev/null | head -1 | sed -n 's/^hyperfine \([0-9][0-9.]*\).*/\1/p')
            ;;
        spf)
            # superfile's binary is `spf`; it prints "superfile version v1.6.0".
            actual=$(spf --version 2>/dev/null | head -1 | sed -n 's/^superfile version v\([0-9][0-9.]*\).*/\1/p')
            ;;
        hermes)
            # "Hermes Agent v0.21.5 (2026.9.24) · upstream ..." — the release
            # date follows the version, so stop at the space.
            actual=$(hermes --version 2>/dev/null | head -1 | sed -n 's/^Hermes Agent v\([0-9][0-9.]*\).*/\1/p')
            ;;
        direnv)
            actual=$(direnv version 2>/dev/null | head -1 | sed -n 's/^\([0-9][0-9.]*\).*/\1/p')
            ;;
        node)
            actual=$(node --version 2>/dev/null | head -1 | sed -n 's/^v\([0-9][0-9.]*\).*/\1/p')
            ;;
        uv)
            actual=$(uv --version 2>/dev/null | head -1 | sed -n 's/^uv \([0-9][0-9.]*\).*/\1/p')
            ;;
        tofu)
            actual=$(tofu version 2>/dev/null | head -1 | sed -n 's/^OpenTofu v\([0-9][0-9.]*\).*/\1/p')
            ;;
        gh)
            actual=$(gh version 2>/dev/null | head -1 | sed -n 's/^gh version \([0-9][0-9.]*\).*/\1/p')
            ;;
        kubectx)
            actual=$(kubectx --version 2>/dev/null | head -1 | sed -n 's/^\([0-9][0-9.]*\).*/\1/p')
            ;;
        kubens)
            actual=$(kubens --version 2>/dev/null | head -1 | sed -n 's/^\([0-9][0-9.]*\).*/\1/p')
            ;;
        kubecolor)
            # --kubecolor-version reports kubecolor's own version without
            # invoking kubectl (which may not be installed yet).
            actual=$(kubecolor --kubecolor-version 2>/dev/null | head -1 | sed -n 's/^v\?\([0-9][0-9.]*\).*/\1/p')
            ;;
        bat)
            actual=$(bat --version 2>/dev/null | head -1 | sed -n 's/^bat \([0-9][0-9.]*\).*/\1/p')
            ;;
        fastfetch)
            actual=$(fastfetch --version 2>/dev/null | head -1 | sed -n 's/^fastfetch \([0-9][0-9.]*\).*/\1/p')
            ;;
        helm)
            actual=$(helm version --template '{{.Version}}' 2>/dev/null | sed -n 's/^v\([0-9][0-9.]*\).*/\1/p')
            ;;
        kubectl)
            actual=$(kubectl version --client=true --output json 2>/dev/null | sed -n 's/.*"gitVersion": "v\([0-9][0-9.]*\)".*/\1/p' | head -1)
            ;;
        jq)
            actual=$(jq --version 2>/dev/null | sed -n 's/^jq-\([0-9][0-9.]*\).*/\1/p')
            ;;
        yq)
            actual=$(yq --version 2>/dev/null | sed -n 's/.*version v\([0-9][0-9.]*\).*/\1/p')
            ;;
        k9s)
            actual=$(k9s version --short 2>/dev/null | sed -n 's/^Version[[:space:]]*v\([0-9][0-9.]*\).*/\1/p' | head -1)
            ;;
        opencode)
            actual=$(opencode --version 2>/dev/null | sed -n 's/^opencode v\([0-9][0-9.]*\).*/\1/p')
            ;;
        kubelogin)
            # `kubelogin --version` prints "kubelogin version " followed by an
            # empty value; the real version sits in the git hash line.
            actual=$(kubelogin --version 2>/dev/null | sed -n 's|^git hash: v\([0-9][0-9.]*\)/.*|\1|p' | head -1)
            ;;
        lazygit)
            # Release binaries print "..., version=0.63.1, os=linux, ...";
            # source builds have no ldflags and print version=unversioned.
            actual=$(lazygit --version 2>/dev/null | grep -o 'version=[0-9][0-9.]*' | head -1 | cut -d= -f2)
            ;;
    esac

    [[ -z "$actual" ]] && return 1

    version_gte "$actual" "$expected"
}
