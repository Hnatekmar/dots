.PHONY: test clean build run shell lint test-go test-neovim test-base \
        build-fedora build-debian build-arch \
        test-fedora test-debian test-arch test-all

# Container runtime (podman if available, docker otherwise)
CONTAINER = $(shell command -v podman 2>/dev/null || echo docker)

# Image tags
IMAGE = dots-test
IMAGE_DEBIAN = dots-test-debian
IMAGE_ARCH = dots-test-arch

# ── Build (default: Fedora) ──

build:
	$(CONTAINER) build -t $(IMAGE) -f Dockerfile .

build-fedora: build

build-debian:
	$(CONTAINER) build -t $(IMAGE_DEBIAN) -f Dockerfile.debian .

build-arch:
	$(CONTAINER) build -t $(IMAGE_ARCH) -f Dockerfile.arch .

# ── Smoke tests (per distro) ──

# Verify all major tools bootstrapped correctly
test-fedora: build-fedora
	$(CONTAINER) run --rm $(IMAGE) bash -c 'go version && nvim --version | head -1 && rg --version | head -1 && fd --version && lazygit --version | head -1 && cargo --version && bao version | head -1'

test-debian: build-debian
	$(CONTAINER) run --rm $(IMAGE_DEBIAN) bash -c 'go version && nvim --version | head -1 && rg --version | head -1 && fd --version && lazygit --version | head -1 && cargo --version && bao version | head -1'

test-arch: build-arch
	$(CONTAINER) run --rm $(IMAGE_ARCH) bash -c 'go version && nvim --version | head -1 && rg --version | head -1 && fd --version && lazygit --version | head -1 && cargo --version && bao version | head -1'

test-all: test-fedora test-debian test-arch

# Back-compat aliases
run: build
	$(CONTAINER) run --rm $(IMAGE) bash -c 'go version && nvim --version | head -1 && bao version | head -1'

# Drop into a shell in the test container for debugging
shell: build
	$(CONTAINER) run --rm -it $(IMAGE) /bin/bash

# Test only the base feature (stow + dotfiles)
test-base: build
	$(CONTAINER) run --rm $(IMAGE) bash -c 'cat ~/.bash_profile && echo "---" && cat ~/.profile'

# Test only the Go install
test-go: build
	$(CONTAINER) run --rm $(IMAGE) bash -c 'go version'

# Test only the Neovim install
test-neovim: build
	$(CONTAINER) run --rm $(IMAGE) bash -c 'nvim --version | head -1'

# Run shellcheck on all scripts (if shellcheck is installed locally)
lint:
	@which shellcheck >/dev/null 2>&1 || { echo "Install shellcheck (dnf/apt/pacman: shellcheck)"; exit 1; }
	shellcheck bootstrap.sh features/*/install.sh features/utils.sh features/05_openbao-approle/bootstrap-approle.sh features/00_launcher/dotfiles/local/bin/dots-bootstrap.sh

# Clean up test images
clean:
	-$(CONTAINER) rmi $(IMAGE) $(IMAGE_DEBIAN) $(IMAGE_ARCH) 2>/dev/null || true
