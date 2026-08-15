FROM ringbuffer_java_fedora

# Add test-only dependencies (JUnit, coverage tools, etc.)
RUN dnf install -y --setopt=timeout=300 \
        junit4 \
        && dnf clean all
