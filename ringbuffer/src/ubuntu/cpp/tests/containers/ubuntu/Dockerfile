FROM ubuntu:24.04

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc g++ binutils make \
        cmake cmake-data cmake-doc dh-cmake debhelper devscripts doxygen \
        clang clang-tidy clang-format llvm lld \
        procps coreutils findutils which file strace emacs-nox patchelf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Verify toolchain
RUN g++ --version && make --version
