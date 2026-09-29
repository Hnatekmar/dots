.PHONY: clean build shell lint \
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
	$(CONTAINER) build -t $(IMAGE_DEBIAN) --build-arg BASE=debian:bookworm -f Dockerfile .

build-arch:
	$(CONTAINER) build -t $(IMAGE_ARCH) --build-arg BASE=archlinux:latest -f Dockerfile .

# ── Tests (per distro) ──
#
# dots-doctor (BATS suites) runs as a Dockerfile RUN step during build, so
# the build itself fails if any test fails. The test-* targets below run
# dots-doctor again in the built image for a clean report.

test-fedora: build-fedora
	$(CONTAINER) run --rm $(IMAGE) dots-doctor

test-debian: build-debian
	$(CONTAINER) run --rm $(IMAGE_DEBIAN) dots-doctor

test-arch: build-arch
	$(CONTAINER) run --rm $(IMAGE_ARCH) dots-doctor

test-all: test-fedora test-debian test-arch

# Drop into a shell in the test container for debugging
shell: build
	$(CONTAINER) run --rm -it $(IMAGE) /bin/bash

# Run shellcheck on all scripts (if shellcheck is installed locally)
lint:
	@which shellcheck >/dev/null 2>&1 || { echo "Install shellcheck (dnf/apt/pacman: shellcheck)"; exit 1; }
	shellcheck bootstrap.sh features/*/install.sh features/utils.sh features/99_doctor/dotfiles/.local/bin/dots-doctor

# Clean up test images
clean:
	-$(CONTAINER) rmi $(IMAGE) $(IMAGE_DEBIAN) $(IMAGE_ARCH) 2>/dev/null || true
