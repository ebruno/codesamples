# Raspberry Pi OS (Bookworm) arm64 — Datestamp-tagged for reproducible builds
# Base image: debian:13 (trixie) — Bookworm GCC 12 lacks C++20 <format> support
# Debian 13 provides GCC 14.2 with full C++20 support

ARG BASE_IMAGE=debian:13
FROM ${BASE_IMAGE}

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required toolchains and utilities (GCC 14 for full C++20 <format> support)
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    openjdk-21-jdk-headless \
    maven \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app
