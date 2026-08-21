ARG BASE_IMAGE=fedora:44

FROM ${BASE_IMAGE}

# Install all tools needed for all supported languages on Fedora
RUN dnf install -y --setopt=timeout=300 \
    # C/C++ toolchain
    gcc gcc-c++ binutils make cmake doxygen clang clang-tidy clang-format \
    # Java
    java-25-openjdk maven \
    # Python
    python3 python3-pip python3-pytest python3-coverage \
    # Utilities
    procps-ng coreutils findutils which file patchelf vim-minimal strace \
    && dnf clean all

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
