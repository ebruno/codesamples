ARG BASE_IMAGE=fedora:44
FROM ${BASE_IMAGE}

# Install Java 25 and Maven (latest available)
RUN dnf install -y --setopt=timeout=300 \
        java-25-openjdk \
        maven && \
    dnf clean all

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
