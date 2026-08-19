ARG BASE_IMAGE=fedora:44
FROM ${BASE_IMAGE}

# Install required toolchains and utilities
# Use default repos with very long timeout (vmnet network is slow/unreliable)
RUN dnf install -y --setopt=timeout=300 \
        gcc \
        gcc-c++ \
        binutils \
        make \
        which \
        cmake \
        doxygen \
        clang \
        procps-ng \
        coreutils \
        findutils \
        file \
        patchelf \
        vim-minimal \
        strace \
        python3 && \
    dnf clean all

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
