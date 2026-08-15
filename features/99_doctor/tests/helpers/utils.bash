# Shared helper functions for dots-doctor tests.

# Check that a command exists and is on PATH.
assert_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}
