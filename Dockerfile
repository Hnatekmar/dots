FROM fedora:latest

# Prerequisites for bootstrap: downloads, checksum parsing, cargo/go compiles.
# bootstrap.sh also installs these at runtime, but having them baked in speeds
# rebuilds and avoids network during the RUN.
RUN dnf install -y \
        git \
        curl \
        tar \
        findutils \
        python3 \
        gcc \
        make \
        && dnf clean all

# Copy repo into the image
COPY . /dots

WORKDIR /dots

# Remove Fedora's default dotfiles that conflict with symlink targets
RUN rm -f /root/.bash_profile /root/.profile

# Ensure Go and go-installed binaries are in PATH for feature installers
ENV PATH=/root/.local/go/bin:/root/.local/bin:/root/go/bin:/root/.cargo/bin:$PATH

# Run the full bootstrap at build time.
# If any feature installer fails, the build fails — this is the CI gate.
RUN bash bootstrap.sh

# Run dots-doctor (BATS test suites) to validate the installation.
# If any test fails, the build fails.
RUN dots-doctor

# Drop into a shell for interactive debugging
CMD ["bash"]
