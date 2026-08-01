# dots

GNU Stow-based dotfiles and tool bootstrap for Linux. Installs and configures development tools via a feature system where each directory under `features/` is a self-contained installer.

Works on **Fedora**, **Debian/Ubuntu**, and **Arch**. The only distro-specific code is the prerequisite install in `bootstrap.sh`; every tool is built from source (`go install` / `cargo install`) or downloaded as an upstream binary with checksum verification.

## Quick start

```bash
git clone https://github.com/Hnatekmar/dots.git
cd dots
bash bootstrap.sh
```

## Prerequisites

- A supported distro (dnf / apt-get / pacman)
- Root access (installs to `/usr/local`, uses `stow` into `$HOME`)

`bootstrap.sh` installs `git curl tar findutils python3 gcc make stow` via your distro's package manager, then builds everything else from source.

## Updating

After `git pull`, re-run bootstrap, or use the ergonomic launcher (stowed into `~/.local/bin`):

```bash
dots-bootstrap.sh               # re-run all features (skips up-to-date tools)
dots-bootstrap.sh --force       # reinstall everything, bypass version checks
dots-bootstrap.sh --only 00_go  # run a single feature
dots-bootstrap.sh --list        # list available features
```

## Features

| Dir | Feature | Installs |
|-----|---------|----------|
| `00_base` | Shell config | `.bash_profile`, `.profile` via Stow |
| `00_go` | Go | Go 1.26.5 to `/usr/local/go` |
| `00_rust` | Rust | rustup + stable toolchain to `~/.cargo` |
| `00_neovim` | Neovim | Neovim 0.12.4 to `/usr/local` |
| `00_launcher` | Launcher | `~/.local/bin/dots-bootstrap.sh` |
| `01_gum` | Gum | charmbracelet/gum v0.16.2 via `go install` |
| `02_crush` | Crush | Crush v0.87.0 + config (providers, MCP, LSP) |
| `02_ripgrep` | ripgrep | v15.2.0 via `cargo install` |
| `02_fd` | fd | v10.4.2 via `cargo install` |
| `03_lazygit` | lazygit | v0.63.1 via `go install` |
| `03_lazyvim` | LazyVim | submodule + nvim symlink (delegates to neovim, ripgrep, fd, lazygit) |
| `04_openbao` | OpenBao | OpenBao 2.6.1 binary |
| `05_openbao-approle` | AppRole | AppRole bootstrap generator + `bao-auth` |

Features run in lexical order. Each feature is idempotent — re-running skips already-installed tools (use `--force` to override).

## Security

### Download verification

Go, Neovim, OpenBao, and rustup downloads all verify SHA256 checksums before extracting. ripgrep, fd, gum, crush, and lazygit are built from source via `cargo`/`go` against pinned versions.

### Secret management (OpenBao AppRole)

The `05_openbao-approle` feature provides machine identity enrollment for servers:

1. SSH into the server
2. Authenticate with your operator token:
   ```bash
   bao login -method=oidc role=operator
   ```
3. Run the bootstrap:
   ```bash
   bash features/05_openbao-approle/bootstrap-approle.sh
   ```

This creates an AppRole named after the hostname, stores `role_id` and `secret_id` in `/etc/bao/`, **generates `~/.local/bin/bao-auth`** (a host-specific init script) and `~/.config/direnv/lib/bao.sh`, and **revokes the operator token**. Re-running is safe: it reuses an existing `secret_id` if the role still resolves, avoiding dangling credentials.

Use the generated `bao-auth` to authenticate non-interactively:

```bash
source <(bao-auth)        # in shells / .envrc — exports VAULT_TOKEN
TOKEN=$(bao-auth --token) # in scripts
bao-auth --env            # print export lines
```

In any directory with an allowed `.envrc`, direnv auto-sources `lib/bao.sh` (no manual template copying needed).

## Testing

Build and run the full bootstrap in a container, per distro:

```bash
make test-fedora    # Fedora (default)
make test-debian    # Debian bookworm
make test-arch      # Arch
make test-all       # all three
```

Each smoke-tests that go, nvim, rg, fd, lazygit, cargo, and bao are present and runnable.

Individual features (Fedora image):

```bash
make test-base      # Shell config only
make test-go        # Go install only
make test-neovim    # Neovim install only
make shell          # Interactive shell in test container
```

Lint all scripts with shellcheck:

```bash
make lint
```

## Architecture

```
dots/
├── bootstrap.sh              # Entry point — installs prereqs, runs all features
├── Makefile                  # Docker-based testing (fedora/debian/arch)
├── Dockerfile                # Fedora test image
├── Dockerfile.debian         # Debian bookworm test image
├── Dockerfile.arch           # Arch test image
├── features/
│   ├── utils.sh               # Shared: version checks (DOTS_FORCE-aware) + stow_pkg
│   ├── 00_base/               # Stows shell configs
│   ├── 00_go/                 # Downloads + verifies + installs Go
│   ├── 00_rust/               # rustup + stable toolchain
│   ├── 00_neovim/             # Downloads + verifies + installs Neovim
│   ├── 00_launcher/           # Stows dots-bootstrap.sh launcher
│   ├── 01_gum/                # go install gum
│   ├── 02_crush/              # Stows config + go install crush
│   ├── 02_ripgrep/            # cargo install ripgrep
│   ├── 02_fd/                 # cargo install fd-find
│   ├── 03_lazygit/            # go install lazygit
│   ├── 03_lazyvim/            # submodule + nvim symlink (delegates to deps)
│   ├── 04_openbao/            # Binary install with checksum verification
│   └── 05_openbao-approle/
│       ├── install.sh         # Ensures bao binary
│       └── bootstrap-approle.sh  # Enrollment + bao-auth/direnv generator
└── .gitmodules                # LazyVim submodule
```

## Adding a new feature

1. Create `features/NN_name/` (NN = ordering number)
2. Add `install.sh`:
   ```bash
   #!/bin/bash
   set -euo pipefail

   source "$(dirname "$0")/../utils.sh"

   # Check if already installed (honors DOTS_FORCE=1 from --force)
   if check_command_version mytool "1.0.0"; then
       echo "==> mytool already installed, skipping"
       exit 0
   fi

   # Build from source (go install / cargo install) or download + verify...
   ```
3. Add `dotfiles/` subdirectory for any config files to stow
4. Test with `make build && make test-fedora`
