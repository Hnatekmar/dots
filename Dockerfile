ARG BASE=fedora:latest
FROM ${BASE}

# Refresh the Arch keyring on fresh images before bootstrap.sh uses pacman.
RUN if command -v pacman >/dev/null 2>&1; then pacman -Sy --noconfirm archlinux-keyring; fi

# Copy repo into the image
COPY . /dots

WORKDIR /dots

# Remove distro default dotfiles that conflict with symlink targets
RUN rm -f /root/.bash_profile /root/.profile

# Ensure Node, Go and go-installed binaries are in PATH for feature installers
ENV PATH=/root/.local/node/bin:/root/.local/go/bin:/root/.local/bin:/root/go/bin:/root/.cargo/bin:$PATH

# Run the full bootstrap at build time. If any feature installer fails, the build fails — this is the CI gate.
RUN bash bootstrap.sh

# Run dots-doctor (BATS test suites) to validate the installation.
RUN dots-doctor

# Drop into a shell for interactive debugging
CMD ["bash"]
