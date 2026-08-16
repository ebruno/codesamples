FROM ringbuffer_python_fedora

# Add test-only dependencies (pytest, coverage tools)
RUN dnf install -y --setopt=timeout=300 \
        python3-pytest \
        python3-coverage \
        && dnf clean all
