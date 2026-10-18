# dots

Linux dotfiles and tool bootstrap system. Each directory in `features/` is a self-contained installer. Uses built-in symlinks. No GNU stow required.

Works on Fedora, Debian/Ubuntu, and Arch. Only `bootstrap.sh` has distro-specific code. Tools install from pinned upstream release binaries with checksum verification; `DOTS_BUILD_FROM_SOURCE=1` rebuilds the Go/Rust tools from source instead.

## Quick start

```bash
git clone https://github.com/Hnatekmar/dots.git
cd dots
bash bootstrap.sh
```

## Prerequisites

- A supported distro (dnf, apt-get, or pacman)
- Root access only for system packages (git, curl, zsh, socat)
- All tools install to `$HOME` (~/.local/, ~/.local/node/, ~/.cargo/, ~/go/bin/)

`bootstrap.sh` installs system packages when run as root. Everything else installs into `$HOME` from a verified release binary, so a source toolchain is only exercised under `DOTS_BUILD_FROM_SOURCE=1`. It also makes `zsh` the default login shell when run as root; log in again after the first bootstrap for the change to take effect.

## Updating

After `git pull`, run bootstrap again. Use the launcher script in `~/.local/bin`:

```bash
dots-bootstrap.sh               # Run all features, skip up-to-date tools
dots-bootstrap.sh --force       # Reinstall everything
dots-bootstrap.sh --only 00_go  # Run one feature
dots-bootstrap.sh --list        # Show available features
```

## Download cache

Every download goes through one cache, so re-provisioning a machine (or a fleet
of throwaway containers) does not re-fetch toolchains and tarballs.

```bash
export DOTS_CACHE_DIR=/mnt/nas/cache/dots   # e.g. a NAS mount
bash bootstrap.sh
```

| Setting | Meaning |
|---------|---------|
| unset | Cache under `${XDG_CACHE_HOME:-$HOME/.cache}/dots` |
| `DOTS_CACHE_DIR=/path` | Use that directory, e.g. a shared NAS mount |
| `DOTS_CACHE_DIR=` (empty) | Disable caching for this run |
| `DOTS_BUILD_FROM_SOURCE=1` | Build Gum, ripgrep, fd, fzf, zoxide, lsd, yq, k9s, kubecolor and herdr from source |

Entries are stored as `<tool>/<version>/<filename>`, so the cache stays
browsable and can be shared by machines of both architectures (the arch is part
of every filename). Files are downloaded to a temporary name and renamed into
place, so concurrent bootstraps can share one cache safely. Checksums are
verified on every cache hit and a mismatch triggers a fresh download. A
read-only cache directory degrades gracefully: downloads still work, they just
are not stored.

Clearing the cache is always safe — `rm -rf "$DOTS_CACHE_DIR"`.

## Features

| Dir | Feature | Installs |
|-----|---------|----------|
| `00_base` | Shell config | `.bash_profile`, `.profile` via symlinks |
| `00_git` | Git | global `user.name` / `user.email` |
| `00_go` | Go | Go 1.26.5 to `~/.local/go` |
| `00_rust` | Rust | rustup + stable toolchain to `~/.cargo` |
| `00_neovim` | Neovim | Neovim 0.12.4 to `~/.local` |
| `00_launcher` | Launcher | `~/.local/bin/dots-bootstrap.sh` |
| `00_direnv` | direnv | direnv v2.38.2 release binary |
| `00_node` | Node.js | Node.js 24.22.0 (LTS) to `~/.local/node` |
| `00_uv` | uv | uv v0.13.1 + uvx |
| `01_gum` | Gum | gum v0.16.2 release binary → `~/.local/bin` |
| `02_opencode` | OpenCode | OpenCode v2.0.32 + config (providers, agents, permissions, plugins) |
| `02_ripgrep` | ripgrep | ripgrep v15.2.0 (musl) release binary |
| `02_fd` | fd | fd v10.4.2 (musl) release binary |
| `02_fzf` | fzf | fzf v0.74.5 release binary |
| `02_hunk` | Hunk | hunk v0.23.0 release binary + git diff pager |
| `02_lsd` | lsd | lsd v1.2.0 (musl) release binary |
| `02_zoxide` | zoxide | zoxide v0.10.0 (musl) release binary |
| `02_bat` | bat | bat v0.26.1 release binary |
| `03_herdr` | herdr | herdr v0.9.5 release binary |
| `03_lazygit` | lazygit | lazygit v0.63.1 release binary |
| `03_lazyvim` | LazyVim | submodule + nvim symlink |
| `03_fastfetch` | fastfetch | fastfetch v2.70.0 release binary + presets |
| `04_openbao` | OpenBao | OpenBao 2.6.1 binary |
| `05_gh` | GitHub CLI | gh v2.102.0 release binary |
| `05_helm` | Helm | helm v4.3.1 release binary |
| `05_jq` | jq | jq v1.8.2 release binary |
| `05_k9s` | k9s | k9s v0.51.0 release binary |
| `05_kubectl` | kubectl | kubectl v1.37.1 release binary |
| `05_kubelogin` | kubelogin | kubelogin v0.2.21 release binary (OIDC exec plugin) |
| `05_kubecolor` | kubecolor | kubecolor v0.8.0 release binary |
| `05_kubectx` | kubectx | kubectx + kubens v0.11.0 release binaries |
| `05_opentofu` | OpenTofu | OpenTofu v1.13.1 release binary |
| `05_yq` | yq | yq v4.54.1 release binary |
| `06_kubeconfig` | Cluster kubeconfigs | `dev-k8s` / `prod-k8s` contexts from devops-cluster + `dots-kubeconfig` |
| `07_dev_env` | dev-env | dev-env CLI v0.3.0 (Kubernetes dev environments) |
| `99_doctor` | Doctor | BATS test suites + `dots-doctor` executable |

Features run in lexical order. Each feature is idempotent. Use `--force` to reinstall. Run `dots-doctor` to validate installation.

## Cluster access

`06_kubeconfig` installs `kubelogin` and merges the credential-free OIDC
kubeconfigs committed in `hnatekmarorg/devops-cluster` into `~/.kube/config` as
contexts `dev-k8s` and `prod-k8s`:

```bash
dots-kubeconfig        # both clusters
dots-kubeconfig dev    # refresh one after a cluster rebuild
kubectl --context dev-k8s get nodes   # kubelogin opens the SSO login on first use
```

The kubeconfigs live in `~/.kube/devops-cluster/`; the previous merge is kept as
`~/.kube/config.dots-kubeconfig.bak`. A rebuilt cluster has a new CA, which is
why refreshing is a command and not a one-time install step.

## Dev environments

`07_dev_env` installs the `dev-env` CLI from `hnatekmarorg/dev-envs`, and `socat`
is installed as a system prerequisite because its SSH proxy needs it:

```bash
dev-env create my-env --cpu 2 --memory 4Gi
dev-env create web --address web.dev-k8s.srv.hnatekmar.dev --port 3000
dev-env create api --container redis=redis:7-alpine,port=6379 --docker
dev-env list --json
```

`--json` keeps stdout machine-readable, so an agent can create and inspect
environments without a TTY. See the dev-envs README for sidecars, dind, and
Ingress details.

## Security

### Download verification

Every artifact is checksum-verified before it is unpacked or installed:

| Source | Checksum |
|--------|----------|
| Go | SHA256 from the official `go.dev/dl` JSON index |
| Node.js | SHA256 from the official `nodejs.org` `SHASUMS256.txt` |
| Neovim, fd, zoxide, lsd, hunk, herdr, direnv, bat, fastfetch, yq | SHA256 pinned in `features/checksums.txt`, per architecture |
| gum, lazygit, OpenBao, ripgrep, fzf, jq, k9s, gh, kubectx, kubecolor, opentofu | checksum files published in the release |
| uv, helm, kubectl | `.sha256`/`.sha256sum` sidecar next to the binary/tarball |
| rustup-init | `.sha256` sidecar |
| OpenCode | the npm registry's SHA512 integrity hash |

No feature calls the GitHub API: anonymous requests are capped at 60/hour per
IP, which shared CI and container hosts exhaust. Where upstream publishes no
usable checksum file, the digest is pinned in `features/checksums.txt` keyed by
asset name — refresh it with `scripts/add-checksum.sh <asset-url>` when bumping
a version.

Verification also runs on cache hits, so a corrupted or tampered shared cache is
detected rather than installed. `DOTS_BUILD_FROM_SOURCE=1` falls back to
`cargo install` / `go install` at the same pinned versions.

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
│   ├── utils.sh               # Shared: version checks, download cache, symlinks
│   ├── 00_base/               # Shell config symlinks
│   ├── 00_git/                # global git identity
│   ├── 00_go/                 # Go install
│   ├── 00_rust/               # rustup install
│   ├── 00_neovim/             # Neovim install
│   ├── 00_launcher/           # Launcher script
│   ├── 00_direnv/             # direnv release binary
│   ├── 00_node/               # Node.js LTS install
│   ├── 00_uv/                 # uv + uvx release binaries
│   ├── 01_gum/                # gum release binary
│   ├── 02_opencode/           # opencode + config
│   ├── 02_ripgrep/            # ripgrep release binary
│   ├── 02_fd/                 # fd release binary
│   ├── 02_fzf/                # fzf release binary
│   ├── 02_hunk/               # hunk release binary + git pager integration
│   ├── 02_lsd/                # lsd release binary
│   ├── 02_zoxide/             # zoxide release binary
│   ├── 02_bat/                # bat release binary
│   ├── 03_herdr/              # herdr release binary
│   ├── 03_lazygit/            # lazygit release binary
│   ├── 03_lazyvim/            # LazyVim submodule + nvim symlink
│   ├── 03_fastfetch/          # fastfetch release binary + presets
│   ├── 04_openbao/            # OpenBao binary install
│   ├── 05_gh/                 # GitHub CLI release binary
│   ├── 05_helm/               # helm release binary
│   ├── 05_jq/                 # jq release binary
│   ├── 05_k9s/                # k9s release binary
│   ├── 05_kubectl/            # kubectl release binary
│   ├── 05_kubelogin/          # kubelogin release binary
│   ├── 05_kubecolor/          # kubecolor release binary
│   ├── 05_kubectx/            # kubectx + kubens release binaries
│   ├── 05_opentofu/           # OpenTofu release binary
│   ├── 05_yq/                 # yq release binary
│   ├── 06_kubeconfig/         # devops-cluster contexts + dots-kubeconfig
│   ├── 07_dev_env/            # dev-env CLI release tarball
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
