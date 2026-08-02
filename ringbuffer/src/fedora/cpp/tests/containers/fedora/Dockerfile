# Use Fedora 44 as the base image
FROM fedora:44

# Set the working directory for the container
WORKDIR /workspace

# Install the required build toolchain and utilities
RUN dnf update -y && dnf install -y \
    gcc \
    gcc-c++ \
    binutils \
    make \
    cmake \
    doxygen \
    clang \
    clang-tools-extra \
    procps-ng \
    coreutils \
    findutils \
    which \
    && dnf clean all

# Set environment variables for the default compiler
ENV CXX=g++
ENV CC=gcc

# Default command to launch a bash shell
CMD ["/bin/bash"]
