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

    for ((i = 0; i < max; i++)); do
        local inst=${inst_parts[$i]:-0}
        local req=${req_parts[$i]:-0}
        if ((inst > req)); then return 0; fi
        if ((inst < req)); then return 1; fi
    done
    return 0
}

check_command_version() {
    local cmd="$1"
    local expected="$2"

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
        *)
            actual=$("$cmd" --version 2>/dev/null | head -1 | sed -n 's/.*\([0-9][0-9.]*\).*/\1/p')
            ;;
    esac

    [[ -z "$actual" ]] && return 1

    version_gte "$actual" "$expected"
}
