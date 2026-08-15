ARG BASE_IMAGE=fedora:44
FROM ${BASE_IMAGE}

# Install Python 3 (latest available) and pip
RUN dnf install -y --setopt=timeout=300 \
        python3 python3-pip && \
    dnf clean all

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
