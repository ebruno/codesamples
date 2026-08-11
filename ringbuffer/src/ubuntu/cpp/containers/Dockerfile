FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required toolchains and utilities
# Force IPv4 to avoid "Network is unreachable" on ports.ubuntu.com (IPv6-only resolution in Lima containers)
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 \
    && apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    doxygen \
    clang \
    clang-tidy \
    vim \
    emacs-nox \
    patchelf \
    clang-format \
    procps \
    coreutils \
    file \
    strace \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
