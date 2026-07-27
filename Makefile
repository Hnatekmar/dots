.PHONY: test clean build run shell lint test-go test-neovim test-base

# Container runtime (podman if available, docker otherwise)
CONTAINER = $(shell command -v podman 2>/dev/null || echo docker)

# Image tag
IMAGE = dots-test

# Build the test image
build:
	$(CONTAINER) build -t $(IMAGE) .

# Run full bootstrap in a throwaway container (already baked into image via RUN)
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
	@which shellcheck >/dev/null 2>&1 || { echo "Install shellcheck: dnf install shellcheck"; exit 1; }
	shellcheck bootstrap.sh features/*/install.sh features/utils.sh

# Clean up test images
clean:
	$(CONTAINER) rmi $(IMAGE) 2>/dev/null || true
