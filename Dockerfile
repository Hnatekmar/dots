FROM fedora:latest

# Install base dependencies that bootstrap.sh expects (git, stow)
# plus tools needed for downloads
RUN dnf install -y \
        git \
        stow \
        curl \
        tar \
        sha256sum \
        findutils \
        && dnf clean all

# Copy repo into the image
COPY . /dots

WORKDIR /dots

# Default command: run the full bootstrap
CMD ["bash", "bootstrap.sh"]
