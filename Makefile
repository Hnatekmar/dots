.PHONY: test clean build run shell lint test-go test-neovim test-base

# Docker image tag
IMAGE = dots-test

# Build the test image
build:
	docker build -t $(IMAGE) .

# Run full bootstrap in a throwaway container
run: build
	docker run --rm $(IMAGE)

# Drop into a shell in the test container for debugging
shell: build
	docker run --rm -it $(IMAGE) /bin/bash

# Test only the base feature (stow + dotfiles)
test-base: build
	docker run --rm $(IMAGE) bash -c 'bash features/00_base/install.sh && \
		cat ~/.bash_profile && cat ~/.profile'

# Test only the Go install
test-go: build
	docker run --rm $(IMAGE) bash -c 'bash features/00_go/install.sh && \
		/usr/local/go/bin/go version'

# Test only the Neovim install
test-neovim: build
	docker run --rm $(IMAGE) bash -c 'bash features/00_neovim/install.sh && \
		nvim --version | head -1'

# Run shellcheck on all scripts (if shellcheck is installed locally)
lint:
	@which shellcheck >/dev/null 2>&1 || { echo "Install shellcheck: dnf install shellcheck"; exit 1; }
	shellcheck bootstrap.sh features/*/install.sh features/utils.sh

# Clean up test images
clean:
	docker rmi $(IMAGE) 2>/dev/null || true
