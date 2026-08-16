FROM docker.io/vascoguita/raspios:arm64-bookworm

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ARG JDKVER=17

# Create man pages directory (raspios base image is missing it, causing dpkg failures)
RUN mkdir -p /usr/share/man/man1

# Install Java and Maven (version controlled via JDKVER arg)
# Note: Bookworm repos only have JDK 17; JDK 25 is not available
RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-${JDKVER}-jdk-headless \
        maven && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
