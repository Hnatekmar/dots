# dots

Linux dotfiles and tool bootstrap system. Each directory in `features/` is a self-contained installer. Uses built-in symlinks. No GNU stow required.

Works on Fedora, Debian/Ubuntu, and Arch. Only `bootstrap.sh` has distro-specific code. All tools build from source or download as verified binaries.

## Quick start

```bash
git clone https://github.com/Hnatekmar/dots.git
cd dots
bash bootstrap.sh
```

## Prerequisites

- A supported distro (dnf, apt-get, or pacman)
- Root access only for system packages (git, curl, zsh)
- All tools install to `$HOME` (~/.local/, ~/.cargo/, ~/go/bin/)

`bootstrap.sh` installs system packages when run as root. Then it builds everything else from source.

## Updating

After `git pull`, run bootstrap again. Use the launcher script in `~/.local/bin`:

```bash
dots-bootstrap.sh               # Run all features, skip up-to-date tools
dots-bootstrap.sh --force       # Reinstall everything
dots-bootstrap.sh --only 00_go  # Run one feature
dots-bootstrap.sh --list        # Show available features
```

## Features

| Dir | Feature | Installs |
|-----|---------|----------|
| `00_base` | Shell config | `.bash_profile`, `.profile` via symlinks |
| `00_go` | Go | Go 1.26.5 to `~/.local/go` |
| `00_rust` | Rust | rustup + stable toolchain to `~/.cargo` |
| `00_neovim` | Neovim | Neovim 0.12.4 to `~/.local` |
| `00_launcher` | Launcher | `~/.local/bin/dots-bootstrap.sh` |
| `01_gum` | Gum | charmbracelet/gum v0.16.2 via `go install` |
| `02_opencode` | OpenCode | OpenCode v2.0.26 + config (providers, MCP, permissions) |
| `02_ripgrep` | ripgrep | v15.2.0 via `cargo install` |
| `02_fd` | fd | v10.4.2 via `cargo install` |
| `03_lazygit` | lazygit | v0.63.1 via `go install` |
| `03_lazyvim` | LazyVim | submodule + nvim symlink |
| `04_openbao` | OpenBao | OpenBao 2.6.1 binary |
| `99_doctor` | Doctor | BATS test suites + `dots-doctor` executable |

Features run in lexical order. Each feature is idempotent. Use `--force` to reinstall. Run `dots-doctor` to validate installation.

## Security

### Download verification

Go, Neovim, OpenBao, and rustup downloads verify SHA256 checksums. Other tools build from source via `cargo` or `go` with pinned versions. OpenCode installs a pinned release through its official installer.

## Testing

Build and test in containers:

```bash
make test-fedora    # Fedora (default)
make test-debian    # Debian bookworm
make test-arch      # Arch
make test-all       # All three distros
make shell          # Interactive shell in Fedora container
```

Each image builds with `bootstrap.sh` and `dots-doctor`. The build fails if any tool or test fails.

Lint scripts:

```bash
make lint
```

## Architecture

```
dots/
├── bootstrap.sh              # Entry point: installs prereqs, runs features
├── Makefile                  # Docker testing (fedora/debian/arch)
├── Dockerfile                # Test image (BASE build-arg: fedora default)
├── features/
│   ├── utils.sh               # Shared: version checks + symlink function
│   ├── 00_base/               # Shell config symlinks
│   ├── 00_go/                 # Go install
│   ├── 00_rust/               # rustup install
│   ├── 00_neovim/             # Neovim install
│   ├── 00_launcher/           # Launcher script
│   ├── 01_gum/                # gum via go install
│   ├── 02_opencode/           # opencode + config
│   ├── 02_ripgrep/            # ripgrep via cargo install
│   ├── 02_fd/                 # fd via cargo install
│   ├── 03_lazygit/            # lazygit via go install
│   ├── 03_lazyvim/            # LazyVim submodule + nvim symlink
│   ├── 04_openbao/            # OpenBao binary install
│   └── 99_doctor/             # Test suites + doctor executable
└── .gitmodules                # LazyVim submodule
```

## Adding a new feature

1. Create `features/NN_name/` (NN = ordering number). Copy an existing feature: `cp -r features/02_fd features/06_mytool`
2. Add `install.sh`:
   ```bash
   #!/bin/bash
   set -euo pipefail
   source "$(dirname "$0")/../utils.sh"

   # Check if already installed (honors DOTS_FORCE=1)
   if check_command_version mytool "1.0.0"; then
       echo "==> mytool already installed, skipping"
       exit 0
   fi

   # Build from source or download + verify...
   ```
3. Add `dotfiles/` directory for config files to symlink
4. Test with `make build && make test-fedora`
