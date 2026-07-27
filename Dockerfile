FROM fedora:latest

# Install base dependencies that bootstrap.sh expects (git, stow)
# plus tools needed for downloads
RUN dnf install -y \
        git \
        stow \
        curl \
        tar \
        findutils \
        && dnf clean all

# Copy repo into the image
COPY . /dots

WORKDIR /dots

# Remove Fedora's default dotfiles that conflict with stow targets
RUN rm -f /root/.bash_profile /root/.profile

# Ensure Go and go-installed binaries are in PATH for feature installers
ENV PATH=/usr/local/go/bin:/usr/local/bin:/root/go/bin:$PATH

# Run the full bootstrap at build time.
# If any feature installer fails, the build fails — this is the CI gate.
RUN bash bootstrap.sh

# Drop into a shell for interactive debugging
CMD ["bash"]
