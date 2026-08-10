# Test Suite - Ringbuffer (Debian)

## Overview
This directory contains the test suite for the RingBuffer implementation on Debian. It ensures functional correctness and operational constraints.

## Directory Structure
- `src/`: Test source code.
- `data/`: Test assets.
    - `inputs/`: Source files.
    - `expected/`: Golden files for verification.
- `bin/`: Compiled test binaries.
- `containers/`: OS-specific container configurations.
- `utils/`: Test utility scripts.

## Build Process
The test binaries are built by linking against the static and shared libraries:
```bash
# For static linking
g++ -std=c++20 -I../ -o bin/test001_staticlib src/test001.cpp ../lib/libswtr_ringbuffer.a

# For dynamic linking
g++ -std=c++20 -I../ -o bin/test001_dynamiclib src/test001.cpp -L../lib -Wl,-rpath,$(pwd)/../lib -lswtr_ringbuffer
```
Use `make` to build all targets.

## Running Test Scenarios
Run the test program and redirect stderr to log files:
- **T001: Exact Match**
  `./bin/test001_staticlib -o data/expected/t001.out data/inputs/test001.txt 2> t001.log`
- **T002: Stress Test**
  `./bin/test001_staticlib -o data/expected/t002.out -s 1 -b 1 data/inputs/test001.txt 2> t002.log`
- **T003: Uppercase Transform**
  `./bin/test001_staticlib -o data/expected/t003.out -b 10 -t 1 data/inputs/test001.txt 2> t003.log`

## Container Usage
To run tests inside the Debian container:
```bash
podman run --rm -v $(pwd):/app ringbuffer_debian_build sh -c "cd /app/cpp/tests && make"
```
The `tests/containers/debian/Dockerfile` defines the build environment.
