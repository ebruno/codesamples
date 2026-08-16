ARG BASE_IMAGE=fedora:44

FROM ${BASE_IMAGE}

# Install Java and Maven (version controlled via JDKVER arg)
ARG JDKVER=25

RUN dnf install -y --setopt=timeout=300 \
        java-${JDKVER}-openjdk \
        maven && \
    dnf clean all

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
