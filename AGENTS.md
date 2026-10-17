# AGENTS.md

GNU Stow-based dotfiles and tool bootstrap for Linux. Installs and configures
development tools via a **feature system**: every directory under `features/` is
a self-contained installer. Not a typical dotfiles repo — this is an idempotent,
cross-distro provisioning system where each feature installs a pinned upstream
release binary with checksum verification (building from source only when no
binary is published or `DOTS_BUILD_FROM_SOURCE=1` is set).

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
make shell           # interactive shell in the Fedora test container
make lint            # shellcheck on all scripts (needs local shellcheck)
make clean           # remove test images
```

There is no unit test harness. The CI gate is the Docker build itself: each
Dockerfile runs `bash bootstrap.sh` followed by `dots-doctor` (BATS test suites)
in `RUN` steps, so **any failing feature or test breaks the image build**.
The `make test-*` targets re-run `dots-doctor` in the built image for a clean report.

Note: `make build` / `make test-*` default to the Fedora image; `test-debian`
and `test-arch` pass `--build-arg BASE=...` to the same Dockerfile.

## Running the bootstrap (without containers)

```bash
bash bootstrap.sh                 # check prereqs + run every feature
bash features/00_go/install.sh    # run a single feature directly
dots-doctor                       # run BATS test suites to validate installation
```

All tools are installed into the user's home directory (`~/.local/`,
`~/.local/go/`, `~/.local/node/`, `~/.cargo/`, `~/go/bin/`) — no root required
for tool installation. The only system-level step is installing distro
prerequisites (git, curl, zsh, etc.); when run as non-root, `bootstrap.sh`
checks for these and errors with guidance if any are missing. When run as root
(e.g. in Docker), it installs them via the distro package manager.
`bootstrap.sh` supports `--force`, `--only <feature>`, and `--list` (it
resolves its own path through symlinks); `00_launcher` symlinks it to
`~/.local/bin/dots-bootstrap.sh`.

## Architecture

```
dots/
├── bootstrap.sh              # Entry point: installs prereqs, runs features in lexical order
├── Makefile                  # Docker-based cross-distro testing
├── Dockerfile                # Test image (BASE build-arg: fedora/debian/arch) — runs bootstrap.sh
├── features/
│   ├── utils.sh              # Shared: check_command_version + version_gte + stow_pkg (DOTS_FORCE-aware)
│   │                          # stow_pkg is a built-in symlink function (no GNU stow dependency)
│   ├── NN_feature/
│   │   ├── install.sh        # The feature installer (run by bootstrap.sh)
│   │   └── dotfiles/         # Optional: packages symlinked into $HOME by stow_pkg
│   └── 99_doctor/
│       ├── install.sh        # Installs bats-core + symlinks dots-doctor
│       ├── dotfiles/         # dots-doctor wrapper script
│       └── tests/            # BATS test suites (tools, dotfiles, paths)
```

### Control flow

1. `bootstrap.sh` checks/installs distro prereqs (including `zsh`, then makes it
   the default login shell when run as root), prepends
   `$HOME/.local/node/bin:$HOME/.local/go/bin:$HOME/go/bin:$HOME/.cargo/bin:$HOME/.local/bin`
   to `PATH`, then loops over `features/*/install.sh` **in lexical order**
   (00, 01, 02, ...).
2. Each `install.sh` sources `../utils.sh`, checks if already installed, and
   either skips or installs.
3. `bootstrap.sh` and each installer run in a **subshell** (`(cd ... && bash
   install.sh)`), so exported variables do not leak between features — every
   feature must re-source what it needs.

## Feature conventions (IMPORTANT)

- **The only distro-specific code lives in `bootstrap.sh`** (prereq check/install).
  All features must be fully distro-agnostic and install into `$HOME` (typically
  `~/.local/`, `~/go/bin/`, `~/.cargo/bin/`): install the pinned upstream release
  binary, and only fall back to `go install` / `cargo install` behind
  `DOTS_BUILD_FROM_SOURCE=1`. No feature should write to system paths like
  `/usr/local`.
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
- **Every download goes through `fetch_cached <url> <cache-key> <dest> [digest]`**,
  never a bare `curl -o`. It reuses `DOTS_CACHE_DIR` (default
  `${XDG_CACHE_HOME:-$HOME/.cache}/dots`), verifies the digest on cache hits too,
  and publishes entries atomically so parallel bootstraps can share a cache.
  Cache keys are `<tool>/<version>/<filename>`. A digest can be bare SHA256 hex
  or `sha512:<hex>` (used for npm's integrity hash).
- **Prebuilt binaries are the default.** `install_bin <path> <name>` copies into
  `~/.local/bin` and removes stale copies from `~/go/bin` and `~/.cargo/bin`:
  both precede `~/.local/bin` on PATH, so a leftover source build would shadow
  the new binary and defeat version gating.
- **Version-gate lazygit-style tools only on the binary path.** Release binaries
  report a real version; `go install` builds have no ldflags and print
  `version=unversioned`, so the `DOTS_BUILD_FROM_SOURCE=1` path keeps a
  presence-only check.
- Feature dirs are prefixed with an ordering number (e.g. `00_go`). `bootstrap.sh`
  runs them in lexical order, so prefix matters for dependency ordering.
- For `dotfiles/` subdirs, use `stow_pkg "$(dirname "$0")/dotfiles" <pkg>` (see
  `00_base` and `02_opencode`). This backs up any existing real file the package would
  replace before symlinking it into `$HOME`. The built-in `stow_pkg` function in
  `features/utils.sh` replaces GNU stow — no external `stow` binary is needed.
- Features that depend on another tool explicitly invoke its installer by bash
  (see `03_lazyvim` running `00_go`/`00_neovim`/`02_ripgrep`/`02_fd`/`03_lazygit`).
  `go install`-ed tools compile at install time and need the `go` feature to have
  run first.

## Gotchas & non-obvious patterns

- **`check_command_version` has per-command version-parsing `case` branches** in
  `features/utils.sh` (go, nvim, gum, opencode, bao, rg, fd). There is no catch-all
  branch: if you add a new feature for a tool, you must add a matching branch or
  the idempotency check will treat the tool as not installed and reinstall it
  every run. Some binaries report versions in very different formats (e.g.
  lazygit has no reliable `--version`, so `03_lazygit` deliberately gates on
  presence + `DOTS_FORCE` rather than `check_command_version`).
- **Checksum source differs per tool** and is not uniform:
  - Go: fetches SHA256 from the official `go.dev/dl/?mode=json` API (no
    downloadable checksum file).
  - Node.js: fetches SHA256 from the official `nodejs.org` `SHASUMS256.txt`.
  - Neovim, fd, fzf, zoxide, lsd, hunk, herdr, direnv, uv, bat, fastfetch, yq:
    fetch SHA256 from the GitHub releases API `assets[].digest`.
  - gum, lazygit, OpenBao, jq, k9s, gh, kubectx, kubecolor, opentofu: download a real
    `checksums`/`sha256sum` file, match the hash for the exact asset, and
    compare it to `sha256sum` output.
  - ripgrep, helm, kubectl: a `.sha256`/`.sha256sum` sidecar next to each
    binary/tarball.
  - OpenCode: the npm registry's `dist.integrity` (SHA512, base64), converted to
    hex and passed to `fetch_cached` as `sha512:<hex>`.
  - Go/Neovim/Node.js remove the old install **only after** checksum
    verification passes (`rm -rf "$HOME/.local/go"` /
    `rm -rf "$HOME/.local/node"` / `rm -rf "$HOME/.local/bin/nvim ..."` after
    the check). All tools install under `$HOME/.local/` — no root needed.
- **rustup must be run with `--no-modify-path`** in `00_rust`. Otherwise it
  appends to the *symlinked* `~/.profile` symlink, which would mutate the repo's
  source file. PATH is handled by bootstrap.sh and the symlinked shell config.
  `rustup-init` is downloaded from `static.rust-lang.org` and its `.sha256`
  sibling is verified before execution.
- **oh-my-zsh must be installed with `--keep-zshrc --unattended`** in
  `00_ohmyzsh`. The installer would otherwise write its template over the
  *symlinked* `~/.zshrc` (or wait on an interactive chsh prompt). `--keep-zshrc`
  preserves the repo's curated file; the external plugins `zsh-autosuggestions`
  and `zsh-syntax-highlighting` referenced in `~/.zshrc` are cloned into
  `$OH_MY_ZSH/custom/plugins` because they aren't bundled with oh-my-zsh.
  `zsh` is added to the prereq install in `bootstrap.sh`.
- **`lazygit --version` prints `key=value` fields** (`commit=..., build
  source=binaryRelease, version=0.63.1, os=linux, ...`) and ends with a trailing
  `git version=2.5x`. Parse with `grep -o 'version=[0-9][0-9.]*' | head -1`;
  a `sed 's/.*version=//'` catches the git version instead.
- **OpenCode config quirks**: opencode v2 reads `opencode.json`, not
  `config.json` (which is silently ignored). In the config, a missing
  `{env:VAR}` becomes an empty string and opencode still starts, but a missing
  `{file:...}` target stops the whole server with `ConfigInvalidError`.
- Architecture mapping is repeated per installer: `x86_64`→`amd64`/`x86_64`
  (differs by tool!), `aarch64`→`arm64`. Go uses `amd64`, Neovim uses `x86_64`
  for the same arch — don't assume a single mapping.
- `03_lazyvim` symlinks `features/03_lazyvim/lazyvim` to `~/.config/nvim`,
  backing up any existing real directory first. If the submodule isn't
  initialized it falls back to a direct shallow clone of the URL parsed from
  `.gitmodules` (the clone fallback only runs outside a cloned `.git`, e.g. in
  the Docker build where `.dockerignore` drops `.git`).
## Adding a new feature

1. Create `features/NN_name/` (NN = lexical ordering number).
2. Add `install.sh` following the conventions above (set -euo pipefail, source
   utils.sh, idempotency gate, `go install`/`cargo install` or verified download).
3. Add a `check_command_version` branch in `features/utils.sh` for new tools.
4. Add `dotfiles/` subdir if symlinking config.
5. (Optional) Extend the BATS suites in `features/99_doctor/tests/`.
6. Verify with `make build && make test-fedora` (or `make test-all`).

## Submodule

`features/03_lazyvim/lazyvim` is a git submodule (repo `Hnatekmar/lazyvim`).
It is normally empty/cloned at install time. After cloning the repo, use
`git submodule update --init` if you need it populated.
