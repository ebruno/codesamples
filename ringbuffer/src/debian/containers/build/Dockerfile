FROM debian:13

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install all tools needed for all supported languages on Debian
RUN apt-get update && apt-get install -y --no-install-recommends \
    # C/C++ toolchain
    build-essential cmake doxygen clang clang-tidy clang-format \
    gcc g++ binutils make file patchelf vim strace emacs-nox procps \
    # Java
    openjdk-25-jdk maven \
    # Python
    python3 python3-pip python3-pytest python3-coverage \
    # Utilities
    coreutils findutils which \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
