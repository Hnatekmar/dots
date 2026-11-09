# Shared helper functions for dots-doctor tests.

# Check that a command exists and is on PATH.
assert_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Assert that version $1 is at least $2. Version-sorts, so 0.9 < 0.87 and
# 2.1.4 < 2.1.311, which a plain string compare gets wrong.
assert_version_ge() {
    local actual="$1" minimum="$2"
    [ -n "$actual" ] || return 1
    printf '%s\n%s\n' "$minimum" "$actual" | sort -V -C
}
