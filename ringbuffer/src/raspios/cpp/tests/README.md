# Ringbuffer Test Suite - Raspberry Pi OS

## Overview
This test suite validates the ringbuffer library implementation on Raspberry Pi OS (Debian 13/trixie). It includes:
- Test data generation with zig-zag space pattern
- Static and dynamic linking test binaries
- Full test matrix (T001-T007) covering functional, stress, and error scenarios
- JUnit XML report generation

## Directory Structure
```
tests/
├── src/                # Test source code (test001.cpp)
├── data/
│   ├── inputs/         # Input test files (test001.txt - test007.txt)
│   └── expected/       # Expected output files for verification
├── bin/                # Compiled test binaries
├── logs/               # Test execution logs
├── reports/            # JUnit XML test reports
├── containers/raspios/  # Dockerfile for Raspios test container
└── utils/bin/          # Utility scripts (data generation, validation)
```

## Building and Running Tests

### Prerequisites
- Raspberry Pi OS (Debian 13/trixie) or container with matching toolchain
- g++ (GCC 14+) with C++20 support
- make

### Build Test Binaries
```bash
make all          # Build both static and dynamic test binaries
make static       # Build only static linking binary
make dynamic      # Build only dynamic linking binary
```

### Run Tests
```bash
make verify       # Run full test matrix with artifact verification
```

### Example Test Scenarios

**T001 - Exact match with input (4 slots, 4096 bytes):**
```bash
./bin/test001_staticlib -s 4 -b 4096 -t 0 -e 0 data/inputs/test001.txt > data/expected/t001.out 2> logs/t001.log
```

**T002 - Stress test (1 slot, 1 byte):**
```bash
./bin/test001_staticlib -s 1 -b 1 -t 0 -e 0 data/inputs/test001.txt > data/expected/t002.out 2> logs/t002.log
```

**T003 - Uppercase transform:**
```bash
./bin/test001_staticlib -s 4 -b 10 -t 1 -e 0 data/inputs/test001.txt > data/expected/t003.out 2> logs/t003.log
```

## Container Support

### Building the Test Container
```bash
make container    # Build ringbuffer_raspios_test image
```

### Running Tests in Container
```bash
container run --rm -v $(pwd)/../..:/app ringbuffer_raspios_test sh -c "cd /app/cpp/tests && make verify"
```

### Cleaning Container
```bash
make container-clean    # Remove test container image
```

## Test Matrix

| Test ID | Description | Slots | Size | Transform | Error | Expected Exit Code |
|---------|-------------|-------|------|-----------|-------|--------------------|
| T001 | Exact match with input | 4 | 4096 | None (0) | None (0) | 0 |
| T002 | Stress test (1 slot, 1 byte) | 1 | 1 | None (0) | None (0) | 0 |
| T003 | All chars uppercase | 4 | 10 | Uppercase (1) | None (0) | 0 |
| T004 | Input < 1 slot (fast EOF) | 4 | 4096 | None (0) | None (0) | 0 |
| T005 | Pipeline stop (Fatal Error) | 4 | 4096 | None (0) | Fatal (1) | 1 |
| T006 | Pipeline continues (Non-fatal) | 4 | 4096 | None (0) | Non-fatal (2) | 0 |
| T007 | Bit-inverted output | 4 | 4096 | Invert (2) | None (0) | 0 |
