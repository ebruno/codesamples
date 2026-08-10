FROM debian:13

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required toolchains and utilities
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    doxygen \
    clang \
    clang-tidy \
    clang-format \
    procps \
    coreutils \
    findutils \
    which \
    gcc \
    g++ \
    binutils \
    make \
    file \
    patchelf \
    vim \
    strace \
    emacs-nox \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
