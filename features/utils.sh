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

# Verify a downloaded file against an expected SHA256 hex digest. Exits on mismatch.
verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual
    actual="$(sha256sum "$file" | cut -d' ' -f1)"
    if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
        echo "ERROR: checksum mismatch for $file" >&2
        echo "  Expected: ${expected:-<none>}" >&2
        echo "  Actual:   $actual" >&2
        exit 1
    fi
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
        opencode)
            actual=$(opencode --version 2>/dev/null | sed -n 's/^opencode v\([0-9][0-9.]*\).*/\1/p')
            ;;
    esac

    [[ -z "$actual" ]] && return 1

    version_gte "$actual" "$expected"
}
