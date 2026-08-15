FROM debian:13

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Java 25 and Maven (latest available)
RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-25-jdk \
        maven && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
