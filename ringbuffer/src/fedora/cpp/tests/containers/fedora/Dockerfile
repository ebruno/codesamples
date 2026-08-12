ARG BASE_IMAGE=fedora:44
FROM ${BASE_IMAGE}

WORKDIR /app

RUN dnf install -y --setopt=timeout=300 \
        gcc \
        gcc-c++ \
        binutils \
        make \
        cmake \
        doxygen \
        clang \
        procps-ng \
        coreutils \
        findutils \
        file \
        patchelf \
        vim-minimal \
        strace \
        python3 \
    && dnf clean all

# Verify toolchain
RUN g++ --version && make --version
