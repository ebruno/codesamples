# Ringbuffer Regression Test Suite — Fedora 44

## Overview

This test suite validates the C++ Ringbuffer library across seven scenarios (T001–T007), covering:

- **Data integrity** — exact match, uppercase transform, bit-inverted output
- **Stress testing** — minimal slot/size configuration
- **Error handling** — fatal and non-fatal error modes
- **EOF termination** — fast EOF with small input

## Directory Structure

```
tests/
├── src/                # Test source code (test001.cpp)
├── data/
│   ├── inputs/         # Input files (test001.txt – test007.txt)
│   └── expected/       # Golden output files (t001.out – t007.out)
├── bin/                # Compiled test binaries
│   ├── test001_staticlib    # Linked against static library (.a)
│   └── test001_dynamiclib   # Linked against shared library (.so) with rpath
├── logs/               # Test execution logs and exit codes
├── reports/            # JUnit XML and Markdown regression reports
├── containers/fedora/  # Dockerfile for the test container (ringbuffer_fedora_test)
└── utils/bin/          # Utility scripts (generate_test_data, verify_test_data, generate_junit_report)
```

## Build

### Build Test Binaries (Native or Container)

```bash
# Native (on Fedora host):
make static dynamic

# Container (from macOS or non-Fedora host):
make container   # Builds ringbuffer_fedora_test image if needed
make static dynamic  # Runs inside container automatically via Makefile routing
```

### Build Test Container Image

```bash
make container
```

This builds (or updates) the `ringbuffer_fedora_test` image from `containers/fedora/Dockerfile`.

### Clean Artifacts

```bash
make clean        # Removes bin/*, expected/*, logs/*, object files
make dist-clean   # Full cleanup including logs/ and reports/ directories
```

## Running Tests

### Run the Full Test Matrix

```bash
make verify
```

This executes all 7 test scenarios, captures exit codes and timing, generates a JUnit XML report (`reports/regression_report_junit.xml`) and a Markdown regression report (`reports/regression_report.md`).

### Run Individual Test Scenarios

Each test scenario uses `test001_staticlib` with specific parameters:

```bash
# T001 — Exact match with input (slots=4, size=4096, transform=none, error=none)
./bin/test001_staticlib -s 4 -b 4096 -t 0 -e 0 data/inputs/test001.txt > data/expected/t001.out 2> logs/t001.log

# T002 — Stress test (slots=1, size=1)
./bin/test001_staticlib -s 1 -b 1 -t 0 -e 0 data/inputs/test001.txt > data/expected/t002.out 2> logs/t002.log

# T003 — All chars uppercase (transform=uppercase)
./bin/test001_staticlib -s 4 -b 10 -t 1 -e 0 data/inputs/test001.txt > data/expected/t003.out 2> logs/t003.log
```

### Test Container Usage

On macOS, the container command is used instead of Docker:

```bash
# Build test image
container build -t ringbuffer_fedora_test -f containers/fedora/Dockerfile .

# Run tests inside container
container run --rm -v $(pwd):/app ringbuffer_fedora_test sh -c "cd /app && make verify"
```

On Linux hosts, use `podman` instead of `container`.

## Test Matrix

| Test ID | Description | Slots | Size | Transform | Error | Expected Exit Code |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| T001 | Exact match with input | 4 | 4096 | 0 (none) | 0 (none) | 0 |
| T002 | Stress test (1 slot, 1 byte) | 1 | 1 | 0 (none) | 0 (none) | 0 |
| T003 | All chars uppercase | 4 | 10 | 1 (uppercase) | 0 (none) | 0 |
| T004 | Input < 1 slot (fast EOF) | 4 | 4096 | 0 (none) | 0 (none) | 0 |
| T005 | Pipeline stop (Fatal Error) | 4 | 4096 | 0 (none) | 1 (fatal) | 1 |
| T006 | Pipeline continues (Non-fatal) | 4 | 4096 | 0 (none) | 2 (non-fatal) | 0 |
| T007 | Bit-inverted output | 4 | 4096 | 2 (XOR 0xFF) | 0 (none) | 0 |

## Transform Types

- `0` — None (Identity/Bypass): output matches input exactly
- `1` — Uppercase: all characters converted to uppercase
- `2` — XOR with 0xFF: each byte bit-inverted

## Error Modes

- `0` — No error: normal pipeline execution
- `1` — Fatal error: handler returns non-zero, pipeline stops, exit code 1
- `2` — Non-fatal error: handler returns zero, pipeline continues, exit code 0

## Utility Scripts

- `utils/bin/generate_test_data.sh` — Generate zig-zag pattern test data (Bash)
- `utils/bin/generate_test_data.zsh` — Generate zig-zag pattern test data (Zsh)
- `utils/bin/generate_test_data.tcsh` — Generate zig-zag pattern test data (Tcsh)
- `utils/bin/generate_test_data_bin_sh.sh` — Generate zig-zag pattern test data (Bourne)
- `utils/bin/verify_test_data.sh` — Validate test data format and line counts
- `utils/bin/generate_junit_report.sh` — Generate JUnit XML report from test results

## Container Directory (`containers/`)

The `containers/fedora/Dockerfile` defines the test environment image (`ringbuffer_fedora_test`). It includes all dependencies needed to compile the library, compile test binaries, and execute the full test suite. The image is built automatically by `make container` when it does not exist or when the Dockerfile has been modified.
