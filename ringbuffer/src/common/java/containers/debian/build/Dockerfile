FROM debian:13

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ARG JDKVER=25

# Install Java and Maven (version controlled via JDKVER arg)
RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-${JDKVER}-jdk \
        maven && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
