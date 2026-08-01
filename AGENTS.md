# AGENTS.md

GNU Stow-based dotfiles and tool bootstrap for Linux. Installs and configures
development tools via a **feature system**: every directory under `features/` is
a self-contained installer. Not a typical dotfiles repo — this is an idempotent,
cross-distro provisioning system where each feature *builds* a tool from source
or downloads a pinned binary with checksum verification.

## Commands

Testing is Docker-based. You must have `podman` or `docker` available; the
Makefile auto-selects podman when present, else docker.

```bash
make build           # build Fedora test image (default)
make build-debian    # build Debian bookworm image
make build-arch      # build Arch image
make test-fedora     # build + smoke-test all major tools (default)
make test-debian
make test-arch
make test-all        # all three distros
make test-base       # only verify stow'ed shell config
make test-go         # only verify Go install
make test-neovim     # only verify Neovim install
make shell           # interactive shell in the Fedora test container
make lint            # shellcheck on all scripts (needs local shellcheck)
make clean           # remove test images
```

There is no unit test harness. The CI gate is the Docker build itself: each
Dockerfile runs `bash bootstrap.sh` in its `RUN` step, so **any failing feature
breaks the image build**. The `make test-*` targets then smoke-test the tools.

Note: `make build` / `make run` / `make test-*` are hardcoded to the Fedora
image; only the `-debian`/`-arch` variants use the other images.

## Running the bootstrap (without containers)

```bash
bash bootstrap.sh                 # install prereqs + run every feature
bash features/00_go/install.sh    # run a single feature directly
```

Requires root (installs to `/usr/local`, stows into `$HOME`) and a supported
distro (dnf / apt-get / pacman). When run via `sudo`, bootstrap operates on the
invoking user's home (not `/root`). The ergonomic launcher is symlinked to
`~/.local/bin/dots-bootstrap.sh` and supports `--force`, `--only <feature>`,
and `--list`.

## Architecture

```
dots/
├── bootstrap.sh              # Entry point: installs prereqs, runs features in lexical order
├── Makefile                  # Docker-based cross-distro testing
├── Dockerfile(.debian/.arch) # Test images — each runs bootstrap.sh at build time
├── features/
│   ├── utils.sh              # Shared: check_command_version + version_gte + stow_pkg (DOTS_FORCE-aware)
│   ├── NN_feature/
│   │   ├── install.sh        # The feature installer (run by bootstrap.sh)
│   │   └── dotfiles/         # Optional: stow packages
│   └── 05_openbao-approle/
│       └── bootstrap-approle.sh  # Manual machine-identity enrollment (NOT run by default)
└── scripts/.local/bin/vlook  # Image-inspection helper (Qwen3.6-VL via shell)
```

### Control flow

1. `bootstrap.sh` sources `features/utils.sh`, installs distro prereqs, prepends
   `/usr/local/go/bin:$HOME/go/bin:$HOME/.cargo/bin` to `PATH`, then loops over
   `features/*/install.sh` **in lexical order** (00, 01, 02, ...).
2. Each `install.sh` sources `../utils.sh`, checks if already installed, and
   either skips or installs.
3. `bootstrap.sh` and each installer run in a **subshell** (`(cd ... && bash
   install.sh)`), so exported variables do not leak between features — every
   feature must re-source what it needs.

### `scripts/.local/bin/vlook`

An independent Python helper (not a feature) that lets coding agents "see"
images by routing them to a multimodel LLM endpoint. Env-configurable via
`VLOOK_URL` / `VLOOK_MODEL`. Supports `ocr` and `scan` subcommands.

## Feature conventions (IMPORTANT)

- **The only distro-specific code lives in `bootstrap.sh`** (prereq install).
  All features must be fully distro-agnostic: build via `go install` /
  `cargo install`, or download pinned upstream binaries.
- Every `install.sh` must start with:
  ```bash
  #!/bin/bash
  set -euo pipefail
  source "$(dirname "$0")/../utils.sh"
  ```
  (Exception: `00_launcher` needs no shared code and doesn't source utils.sh.)
- **Idempotency is mandatory.** Gate on `check_command_version <cmd> "<ver>"`
  and `exit 0` with a "already installed, skipping" message. This function
  returns 1 when `DOTS_FORCE=1`, forcing a reinstall.
- Feature dirs are prefixed with an ordering number (e.g. `00_go`). `bootstrap.sh`
  runs them in lexical order, so prefix matters for dependency ordering.
- For `dotfiles/` subdirs, use `stow_pkg "$(dirname "$0")/dotfiles" <pkg>` (see
  `00_base` and `02_crush`). This backs up any existing real file the package would
  replace before running `stow -t "$HOME" -R <pkg>` — important because GNU stow
  >= 2.4 *adopts* an unmanaged target into the package dir, silently overwriting the
  repo's curated dotfiles.
- Features that depend on another tool explicitly invoke its installer by bash
  (see `03_lazyvim` running `00_go`/`00_neovim`/`02_ripgrep`/`02_fd`/`03_lazygit`, and
  `05_openbao-approle` running `04_openbao`). `go install`-ed tools compile at
  install time and need the `go` feature to have run first.

## Gotchas & non-obvious patterns

- **`check_command_version` has per-command version-parsing `case` branches** in
  `features/utils.sh` (go, nvim, gum, crush, bao, rg, fd, lazygit, cargo). If you
  add a new feature for a tool, you must add a matching branch here or the
  idempotency check will misparse the version (or fall through to a generic
  regex). Some binaries report versions in very different formats (e.g. lazygit
  has no reliable `--version`, so `03_lazygit` deliberately gates on presence +
  `DOTS_FORCE` rather than `check_command_version`).
- **Checksum source differs per tool** and is not uniform:
  - Go: fetches SHA256 from the official `go.dev/dl/?mode=json` API (no
    downloadable checksum file).
  - Neovim: fetches SHA256 from the GitHub releases API `assets[].digest`.
  - OpenBao: downloads a real `checksums.txt`, greps the hash for its exact
    tarball, and compares it to `sha256sum` output.
  - Go/Neovim remove the old install **only after** checksum verification passes
    (`rm -rf /usr/local/go` after the check).
- **rustup must be run with `--no-modify-path`** in `00_rust`. Otherwise it
  appends to the *stowed* `~/.profile` symlink, which would mutate the repo's
  source file. PATH is handled by bootstrap.sh and the stowed shell config.
  `rustup-init` is downloaded from `static.rust-lang.org` and its `.sha256`
  sibling is verified before execution.
- **oh-my-zsh must be installed with `--keep-zshrc --unattended`** in
  `00_ohmyzsh`. The installer would otherwise write its template over the
  *stowed* `~/.zshrc` (or wait on an interactive chsh prompt). `--keep-zshrc`
  preserves the repo's curated file; the external plugins `zsh-autosuggestions`
  and `zsh-syntax-highlighting` referenced in `~/.zshrc` are cloned into
  `$OH_MY_ZSH/custom/plugins` because they aren't bundled with oh-my-zsh.
  `zsh` is added to the prereq install in `bootstrap.sh`.
- **`lazygit` version detection is unreliable** (built via `go install`, no
  ldflags), so it skips version gating entirely.
- Architecture mapping is repeated per installer: `x86_64`→`amd64`/`x86_64`
  (differs by tool!), `aarch64`→`arm64`. Go uses `amd64`, Neovim uses `x86_64`
  for the same arch — don't assume a single mapping.
- `03_lazyvim` symlinks `features/03_lazyvim/lazyvim` to `~/.config/nvim`,
  backing up any existing real directory first. If the submodule isn't
  initialized it falls back to a direct shallow clone of the URL parsed from
  `.gitmodules` (the clone fallback only runs outside a cloned `.git`, e.g. in
  the Docker build where `.dockerignore` drops `.git`).
- The `05_openbao-approle/bootstrap-approle.sh` **mutates the live OpenBao
  server** (creates an AppRole, stores credentials in `/etc/bao/`, revokes the
  operator token). It is NOT run by `bootstrap.sh` — only its light-weight
  `install.sh` (which just ensures the `bao` binary) is a feature. Never
  auto-run `bootstrap-approle.sh`.
- The upstream repo URL/VAULT_ADDR `https://bao.hnatekmar.xyz` is hardcoded as a
  default in `bootstrap-approle.sh` via `${VAULT_ADDR:-...}`.

## Adding a new feature

1. Create `features/NN_name/` (NN = lexical ordering number).
2. Add `install.sh` following the conventions above (set -euo pipefail, source
   utils.sh, idempotency gate, `go install`/`cargo install` or verified download).
3. Add a `check_command_version` branch in `features/utils.sh` for new tools.
4. Add `dotfiles/` subdir if stowing config.
5. (Optional) Add a `make test-<feature>` target and/or extend the smoke-test
   line in the `test-*` targets.
6. Verify with `make build && make test-fedora` (or `make test-all`).

## Submodule

`features/03_lazyvim/lazyvim` is a git submodule (repo `Hnatekmar/lazyvim`).
It is normally empty/cloned at install time. After cloning the repo, use
`git submodule update --init` if you need it populated.
