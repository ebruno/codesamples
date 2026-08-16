FROM ringbuffer_python_ubuntu

# Add test-only dependencies (pytest, coverage tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3-pytest \
        python3-coverage \
        && apt-get clean && rm -rf /var/lib/apt/lists/*
