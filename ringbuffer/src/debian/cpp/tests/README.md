# Ringbuffer Test Suite - Ubuntu

## Overview
This test suite validates the ringbuffer library implementation on Ubuntu 24.04 LTS. It includes:
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
├── containers/ubuntu/  # Dockerfile for Ubuntu test container
└── utils/bin/          # Utility scripts (data generation, validation)
```

## Building and Running Tests

### Prerequisites
- Ubuntu 24.04 LTS or later
- g++ (GCC) with C++20 support
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
make container    # Build ringbuffer_ubuntu_test image
```

### Running Tests in Container
```bash
container run --rm -v $(pwd):/app ringbuffer_ubuntu_test sh -c "cd /app && make verify"
```

### Cleaning Container
```bash
make container-clean    # Remove test container image
```

## Test Matrix

| Test ID | Description | Slots | Size | Transform | Error | Expected |
|---------|-------------|-------|------|-----------|-------|----------|
| T001 | Exact match with input | 4 | 4096 | None (0) | No error (0) | Output matches input |
| T002 | Stress test | 1 | 1 | None (0) | No error (0) | Exact match with minimal resources |
| T003 | Uppercase transform | 4 | 10 | Uppercase (1) | No error (0) | All characters uppercase |
| T004 | Fast EOF termination | 4 | 4096 | None (0) | No error (0) | Input < 1 slot, fast EOF |
| T005 | Fatal error handling | 4 | 4096 | None (0) | Fatal (1) | Pipeline stops, exit code 1 |
| T006 | Non-fatal error handling | 4 | 4096 | None (0) | Non-fatal (2) | Pipeline continues, exit code 0 |
| T007 | Bit-inverted output | 4 | 4096 | XOR 0xFF (2) | No error (0) | Bit-inverted output |

## Utility Scripts

### Generate Test Data
```bash
./utils/bin/generate_test_data.sh -l 25 data/inputs/test001.txt
./utils/bin/generate_test_data.sh -l 50 data/inputs/test002.txt
# ... up to test007.txt (250 lines)
```

### Validate Test Data
```bash
./utils/bin/verify_test_data.sh data/inputs/test001.txt
```

## Clean Up
```bash
make clean        # Remove test binaries and logs
make dist-clean   # Full cleanup including reports directory
```
