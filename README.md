# dots

GNU Stow-based dotfiles and tool bootstrap for Fedora/Linux. Installs and configures development tools via a feature system where each directory under `features/` is a self-contained installer.

## Quick start

```bash
git clone https://github.com/Hnatekmar/dots.git
cd dots
bash bootstrap.sh
```

## Prerequisites

- Fedora (uses `dnf`)
- Root access (installs to `/usr/local`, uses `stow` into `$HOME`)

## Features

| Dir | Feature | Installs |
|-----|---------|----------|
| `00_base` | Shell config | `.bash_profile`, `.profile` via Stow |
| `00_go` | Go | Go 1.26.5 to `/usr/local/go` |
| `00_neovim` | Neovim | Neovim 0.12.4 to `/usr/local` |
| `01_gum` | Gum | charmbracelet/gum v0.16.2 via `go install` |
| `02_crush` | Crush | Crush v0.87.0 + config (providers, MCP, LSP) |
| `03_lazyvim` | LazyVim | lazygit, ripgrep, fd, gopls, LazyVim config (submodule) |
| `04_openbao` | OpenBao | OpenBao 2.6.1 binary |
| `05_openbao-approle` | AppRole | AppRole bootstrap script + `.envrc` template |

Features run in lexical order. Each feature is idempotent — re-running skips already-installed tools.

## Security

### Download verification

Go, Neovim, and OpenBao downloads all verify SHA256 checksums before extracting.

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

This creates an AppRole named after the hostname, stores `role_id` and `secret_id` in `/etc/bao/`, and **revokes the operator token**. The server can then authenticate non-interactively via AppRole — no browser, no TTY needed.

Use the `.envrc.example` template with direnv for automatic secret fetching in project directories.

## Testing

Build and run the full bootstrap in a Docker container:

```bash
make run
```

Individual features:

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
├── bootstrap.sh              # Entry point — runs all features in order
├── Makefile                   # Docker-based testing
├── Dockerfile                 # Fedora container for testing
├── features/
│   ├── utils.sh               # Shared: version comparison, command checks
│   ├── 00_base/
│   │   ├── install.sh         # Stows shell configs
│   │   └── dotfiles/base/     # .bash_profile, .profile
│   ├── 00_go/
│   │   └── install.sh         # Downloads + verifies + installs Go
│   ├── 00_neovim/
│   │   └── install.sh         # Downloads + verifies + installs Neovim
│   ├── 01_gum/
│   │   └── install.sh         # go install gum
│   ├── 02_crush/
│   │   ├── install.sh         # Stows config + go install crush
│   │   └── dotfiles/crush/    # crush.json, graphiti-instructions.md
│   ├── 03_lazyvim/
│   │   ├── install.sh         # lazygit, ripgrep, fd, gopls, submodule
│   │   └── lazyvim/           # Git submodule (config)
│   ├── 04_openbao/
│   │   └── install.sh         # Binary install with checksum verification
│   └── 05_openbao-approle/
│       ├── install.sh         # Delegates to 04_openbao + stows template
│       ├── bootstrap-approle.sh  # One-shot machine enrollment
│       └── dotfiles/approle/  # .envrc.example for direnv
└── .gitmodules                # LazyVim submodule
```

## Adding a new feature

1. Create `features/NN_name/` (NN = ordering number)
2. Add `install.sh`:
   ```bash
   #!/bin/bash
   set -euo pipefail

   source "$(dirname "$0")/../utils.sh"

   # Check if already installed
   if check_command_version mytool "1.0.0"; then
       echo "==> mytool already installed, skipping"
       exit 0
   fi

   # Download, verify, install...
   ```
3. Add `dotfiles/` subdirectory for any config files to stow
4. Test with `make build && make run`
