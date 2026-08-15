# dots

Dotfiles and tool bootstrap for Linux. Installs and configures development tools via a feature system where each directory under `features/` is a self-contained installer. Uses a built-in symlink function (no GNU stow dependency).

Works on **Fedora**, **Debian/Ubuntu**, and **Arch**. The only distro-specific code is the prerequisite install in `bootstrap.sh`; every tool is built from source (`go install` / `cargo install`) or downloaded as an upstream binary with checksum verification.

## Quick start

```bash
git clone https://github.com/Hnatekmar/dots.git
cd dots
bash bootstrap.sh
```

## Prerequisites

- A supported distro (dnf / apt-get / pacman)
- Root access only for installing system packages (git, curl, zsh, etc.); all tools install into `$HOME` (e.g. `~/.local/`, `~/.cargo/`, `~/go/bin/`)

`bootstrap.sh` installs `git curl tar findutils python3 gcc make zsh` via your distro's package manager (when run as root), then builds everything else from source.

## Updating

After `git pull`, re-run bootstrap, or use the ergonomic launcher (symlinked into `~/.local/bin`):

```bash
dots-bootstrap.sh               # re-run all features (skips up-to-date tools)
dots-bootstrap.sh --force       # reinstall everything, bypass version checks
dots-bootstrap.sh --only 00_go  # run a single feature
dots-bootstrap.sh --list        # list available features
```

## Features

| Dir | Feature | Installs |
|-----|---------|----------|
| `00_base` | Shell config | `.bash_profile`, `.profile` via stow_pkg |
| `00_go` | Go | Go 1.26.5 to `~/.local/go` |
| `00_rust` | Rust | rustup + stable toolchain to `~/.cargo` |
| `00_neovim` | Neovim | Neovim 0.12.4 to `~/.local` |
| `00_launcher` | Launcher | `~/.local/bin/dots-bootstrap.sh` |
| `01_gum` | Gum | charmbracelet/gum v0.16.2 via `go install` |
| `02_crush` | Crush | Crush v0.87.0 + config (providers, MCP, LSP) |
| `02_ripgrep` | ripgrep | v15.2.0 via `cargo install` |
| `02_fd` | fd | v10.4.2 via `cargo install` |
| `03_lazygit` | lazygit | v0.63.1 via `go install` |
| `03_lazyvim` | LazyVim | submodule + nvim symlink (delegates to neovim, ripgrep, fd, lazygit) |
| `04_openbao` | OpenBao | OpenBao 2.6.1 binary |
| `99_doctor` | Doctor | BATS test suites + `dots-doctor` executable |

Features run in lexical order. Each feature is idempotent — re-running skips already-installed tools (use `--force` to override). After installation, run `dots-doctor` to validate everything is working.

## Security

### Download verification

Go, Neovim, OpenBao, and rustup downloads all verify SHA256 checksums before extracting. ripgrep, fd, gum, crush, and lazygit are built from source via `cargo`/`go` against pinned versions.

## Testing

Build and run the full bootstrap in a container, per distro:

```bash
make test-fedora    # Fedora (default)
make test-debian    # Debian bookworm
make test-arch      # Arch
make test-all       # all three
make test-doctor    # run dots-doctor in the Fedora image
```

Each image runs `bootstrap.sh` followed by `dots-doctor` (BATS test suites) at build time, so the build fails if any tool or test fails.

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
│   ├── utils.sh               # Shared: version checks (DOTS_FORCE-aware) + stow_pkg (built-in symlink fn)
│   ├── 00_base/               # Symlinks shell configs into $HOME
│   ├── 00_go/                 # Downloads + verifies + installs Go
│   ├── 00_rust/               # rustup + stable toolchain
│   ├── 00_neovim/             # Downloads + verifies + installs Neovim
│   ├── 00_launcher/           # Symlinks dots-bootstrap.sh launcher
│   ├── 01_gum/                # go install gum
│   ├── 02_crush/              # Symlinks config + go install crush
│   ├── 02_ripgrep/            # cargo install ripgrep
│   ├── 02_fd/                 # cargo install fd-find
│   ├── 03_lazygit/            # go install lazygit
│   ├── 03_lazyvim/            # submodule + nvim symlink (delegates to deps)
│   ├── 04_openbao/            # Binary install with checksum verification
│   └── 99_doctor/             # BATS test suites + dots-doctor executable
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
3. Add `dotfiles/` subdirectory for any config files to symlink into $HOME
4. Test with `make build && make test-fedora`
