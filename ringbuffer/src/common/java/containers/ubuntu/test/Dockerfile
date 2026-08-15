FROM ringbuffer_java_ubuntu

# Add test-only dependencies (JUnit, coverage tools, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
        junit4 \
        libjunit-java \
        && apt-get clean && rm -rf /var/lib/apt/lists/*
