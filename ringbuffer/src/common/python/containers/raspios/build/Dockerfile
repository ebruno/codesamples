FROM docker.io/vascoguita/raspios:arm64-bookworm

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Create man pages directory (raspios base image is missing it, causing dpkg failures)
RUN mkdir -p /usr/share/man/man1

# Install Python 3 (latest available) and pip
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
