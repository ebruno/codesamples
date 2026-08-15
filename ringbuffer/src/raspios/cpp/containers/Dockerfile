# Raspberry Pi OS (Bookworm) arm64 — Datestamp-tagged for reproducible builds
# Base image: vascoguita/raspios with arm64-specific tags
# Tag strategy: YYYYMMDD datestamp (3 months prior) for reproducibility, falls back to codename

ARG BASE_IMAGE=vascoguita/raspios:arm64-bookworm
FROM ${BASE_IMAGE}

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
    file \
    patchelf \
    vim \
    strace \
    emacs-nox \
    python3 \
    openjdk-17-jdk-headless \
    maven \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app
