#!/bin/bash

# Version comparison: returns 0 if installed >= required, 1 otherwise
version_gte() {
    local installed="$1"
    local required="$2"

    [[ -z "$required" ]] && return 0

    local IFS='.'
    read -r -a inst_parts <<< "$installed"
    read -r -a req_parts <<< "$required"

    local max=${#req_parts[@]}
    (( ${#inst_parts[@]} > max )) && max=${#inst_parts[@]}

    # 10# forces decimal: avoids octal errors on leading-zero parts like "08"
    for ((i = 0; i < max; i++)); do
        local inst=${inst_parts[$i]:-0}
        local req=${req_parts[$i]:-0}
        if ((10#$inst > 10#$req)); then return 0; fi
        if ((10#$inst < 10#$req)); then return 1; fi
    done
    return 0
}

# Stow a package, first backing up any existing real file it would replace.
# GNU stow >= 2.4 "adopts" an existing unmanaged target into the package
# directory, which would silently overwrite the repo's curated dotfiles.
stow_pkg() {
    local dotfiles_dir="$1"
    local pkg="$2"
    local now
    now="$(date +%Y%m%d%H%M%S)"

    # Process substitution keeps the loop in the current shell so `local` is legal.
    while IFS= read -r f; do
        local rel="${f#*/}"
        local target="$HOME/$rel"

        # Skip if the target or any parent dir is already a stow symlink. stow links
        # a whole package subdir (e.g. ~/.config/crush) as one symlink into the
        # repo, so checking only the leaf would walk into it and treat the repo's own
        # files as "existing", then mv them to .bak (mutating curated dotfiles).
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
    done < <(cd "$dotfiles_dir" && find "$pkg" \( -type f -o -type l \) -print)

    (cd "$dotfiles_dir" && stow -t "$HOME" -R "$pkg")
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
        crush)
            actual=$(crush --version 2>/dev/null | sed -n 's/^crush version v\([0-9][0-9.]*\).*/\1/p')
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
        lazygit)
            actual=$(lazygit --version 2>/dev/null | sed -n 's/.*version=\([0-9][0-9.]*\).*/\1/p' | head -1)
            ;;
        cargo)
            actual=$(cargo --version 2>/dev/null | sed -n 's/cargo \([0-9][0-9.]*\).*/\1/p')
            ;;
        *)
            actual=$("$cmd" --version 2>/dev/null | head -1 | sed -n 's/.*\([0-9][0-9.]*\).*/\1/p')
            ;;
    esac

    [[ -z "$actual" ]] && return 1

    version_gte "$actual" "$expected"
}
