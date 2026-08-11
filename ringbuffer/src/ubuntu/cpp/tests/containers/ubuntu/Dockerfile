FROM ubuntu:24.04

WORKDIR /app

# Force IPv4 for reliability
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc g++ binutils make \
        cmake cmake-data cmake-doc dh-cmake debhelper devscripts doxygen \
        clang clang-tidy clang-format \
        procps coreutils findutils which file strace emacs-nox patchelf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Verify toolchain
RUN g++ --version && make --version
