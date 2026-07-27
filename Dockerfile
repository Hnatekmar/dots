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

# Run the full bootstrap at build time.
# If any feature installer fails, the build fails — this is the CI gate.
RUN bash bootstrap.sh

# Drop into a shell for interactive debugging
CMD ["bash"]
