FROM debian:13

RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    binutils \
    make \
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
    strace \
    emacs-nox \
    patchelf \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
