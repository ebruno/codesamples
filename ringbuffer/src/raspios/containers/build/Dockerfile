ARG BASE_IMAGE=docker.io/vascoguita/raspios:arm64-bookworm

FROM ${BASE_IMAGE}

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Create man pages directory (raspios base image is missing it, causing dpkg failures)
RUN mkdir -p /usr/share/man/man1

# Install all tools needed for all supported languages on Raspios
# Note: Bookworm repos only have JDK 17; JDK 25 is not available
RUN apt-get update && apt-get install -y --no-install-recommends \
    # C/C++ toolchain
    build-essential cmake doxygen clang clang-tidy clang-format llvm lld \
    gcc g++ binutils make file patchelf vim strace emacs-nox procps \
    # Java (JDK 17 is latest available on Bookworm)
    openjdk-17-jdk maven \
    # Python
    python3 python3-pip python3-pytest python3-coverage \
    # Utilities
    coreutils findutils which \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
