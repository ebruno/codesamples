# Ringbuffer Test Suite (macOS)

## Overview
This test suite validates the SwtrRingBuffer library on macOS through a comprehensive matrix of 7 test scenarios (T001–T007). Tests verify functional correctness, error handling, transform operations, and stress conditions.

## Directory Structure
```
tests/
├── src/                # Test source code (test001.cpp)
├── bin/                # Compiled test binaries
│   ├── test001_staticlib    # Static-linked variant
│   └── test001_dynamiclib   # Dynamic-linked variant
├── data/
│   ├── inputs/         # Test input files (test001.txt – test007.txt)
│   └── expected/       # Golden output files for verification
├── utils/bin/          # Utility scripts (Zsh)
│   ├── generate_test_data.zsh
│   ├── verify_test_data.zsh
│   └── generate_junit_report.zsh
├── logs/               # Test execution logs and exit codes
└── reports/            # Regression reports (JUnit XML + Markdown)
```

## Build Process
```bash
# From tests/ directory:
make all              # Build test binaries (static + dynamic)
make deploy_utils     # Deploy utility scripts from prompts
```

## Running Tests

### Full Verification (All 7 Test Scenarios)
```bash
make verify
```
This runs the complete test matrix and generates reports in `reports/`.

### Individual Test Scenarios
Each test scenario can be run manually with stderr redirected to log files:

**T001 — Identity Transform (Normal Operation)**
```bash
bin/test001_staticlib -o logs/t001_out.txt -l logs/t001.log data/inputs/test001.txt 2> logs/t001_err.log
```

**T002 — Stress Test (1 slot, 1-byte buffer)**
```bash
bin/test001_staticlib -s 1 -b 1 -o logs/t002_out.txt -l logs/t002.log data/inputs/test001.txt 2> logs/t002_err.log
```

**T003 — Uppercase Transform**
```bash
bin/test001_staticlib -b 10 -t 1 -o logs/t003_out.txt -l logs/t003.log data/inputs/test001.txt 2> logs/t003_err.log
```

### Test Matrix Summary
| Test ID | Description | Transform | Error Mode | Expected Exit Code |
|---------|-------------|-----------|------------|-------------------|
| T001    | Identity (normal) | 0 (none) | 0 (no error) | 0 |
| T002    | Stress test (1 slot, 1 byte) | 0 (none) | 0 (no error) | 0 |
| T003    | Uppercase transform | 1 (uppercase) | 0 (no error) | 0 |
| T004    | Small input, fast EOF | 0 (none) | 0 (no error) | 0 |
| T005    | Fatal error mode | 0 (none) | 1 (fatal) | 1 |
| T006    | Non-fatal error mode | 0 (none) | 2 (non-fatal) | 0 |
| T007    | XOR transform | 2 (XOR 0xFF) | 0 (no error) | 0 |

## Utility Scripts

### Test Data Generation
```bash
# Generate 100 lines to test_data.txt
utils/bin/generate_test_data.zsh -l 100 data/inputs/test_new.txt

# Generate to stdout
utils/bin/generate_test_data.zsh -l 50
```

### Test Data Validation
```bash
# Validate a single test file
utils/bin/verify_test_data.zsh data/inputs/test001.txt

# Exit code 0 = valid, non-zero = invalid
```

## Container Support
macOS builds and tests run natively — containers are prohibited. The `container` target is a no-op:
```bash
make container  # Outputs: "Container not used for macOS native build"
```

## Cleanup
```bash
make clean      # Remove binaries, logs, reports (preserve directories)
make dist-clean # Full cleanup including directory removal
```

## Requirements
- **macOS**: Native execution only (no containers)
- **Compiler**: clang++ with C++20 support
- **Zsh**: Version 5.8+ (for utility scripts)
