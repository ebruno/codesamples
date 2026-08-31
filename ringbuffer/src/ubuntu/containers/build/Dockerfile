ARG BASE_IMAGE=ubuntu:24.04

FROM ${BASE_IMAGE}

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Force IPv4 to avoid "Network is unreachable" on ports.ubuntu.com (IPv6-only resolution in Lima containers)
# Install all tools needed for all supported languages on Ubuntu.
# C/C++: build-essential, cmake, doxygen, clang, clang-tidy, clang-format, llvm, lld, gcc, g++, binutils, make, file, patchelf, vim, strace, emacs-nox, procps
# Java: openjdk-25-jdk, maven
# Python: python3, python3-pip, python3-pytest, python3-coverage
# Utilities: coreutils, findutils, which
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 \
    && apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake doxygen clang clang-tidy clang-format llvm lld \
    gcc g++ binutils make file patchelf vim strace emacs-nox procps \
    openjdk-25-jdk maven \
    python3 python3-pip python3-pytest python3-coverage \
    coreutils findutils which \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
