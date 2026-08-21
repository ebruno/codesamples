ARG BASE_IMAGE=archlinux:2026.05.21

FROM ${BASE_IMAGE}

# Install all tools needed for C++ development on Arch Linux
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        base-devel gcc clang make file binutils patchelf vim strace procps-ng \
        cmake doxygen && \
    pacman -Sc --noconfirm

# Verify toolchain
RUN g++ --version && clang++ --version && make --version

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
