#!/usr/bin/env bats

# Verify install locations are rootless (no /usr/local pollution).

load helpers/utils

@test "~/.local/bin is in PATH (or will be via .profile)" {
  # In Docker, PATH is set by ENV. On a user system, .profile handles it.
  # We check that either PATH already includes it or .profile mentions it.
  case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *)
    # Not in current PATH — check .profile will add it
    [ -f "$HOME/.profile" ] && grep -q '.local/bin' "$HOME/.profile"
    ;;
  esac
}

@test "~/.local/go/bin is in PATH (or will be via .profile)" {
  case ":$PATH:" in
  *":$HOME/.local/go/bin:"*) ;;
  *)
    [ -f "$HOME/.profile" ] && grep -q '.local/go/bin' "$HOME/.profile"
    ;;
  esac
}

@test "~/.cargo/bin is in PATH (or will be via .profile)" {
  case ":$PATH:" in
  *":$HOME/.cargo/bin:"*) ;;
  *)
    [ -f "$HOME/.profile" ] && grep -q '.cargo/bin' "$HOME/.profile"
    ;;
  esac
}

@test "~/go/bin is in PATH (or will be via .profile)" {
  case ":$PATH:" in
  *":$HOME/go/bin:"*) ;;
  *)
    [ -f "$HOME/.profile" ] && grep -q 'go/bin' "$HOME/.profile"
    ;;
  esac
}

@test "bats is installed in ~/.local/opt/bats-core" {
  [ -x "$HOME/.local/opt/bats-core/bin/bats" ]
}
