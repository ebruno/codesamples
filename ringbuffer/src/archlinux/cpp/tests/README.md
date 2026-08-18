# Ringbuffer Test Suite (Arch Linux)

## Overview
This test suite validates the SwtrRingBuffer library on Arch Linux through a comprehensive matrix of 7 test scenarios (T001–T007). Tests verify functional correctness, error handling, transform operations, and stress conditions.

## Directory Structure
```
tests/
├── src/                # Test source code (test001.cpp)
├── bin/                # Compiled test binaries
│   ├── test001_staticlib        # Static-linked variant (g++)
│   ├── test001_dynamiclib       # Dynamic-linked variant (g++)
│   ├── test001_staticlib_g++    # Per-compiler static binary (g++)
│   ├── test001_staticlib_clang++ # Per-compiler static binary (clang++)
│   └── ...                     # Additional per-compiler variants
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
make all              # Build test binaries (static + dynamic) with default compiler (g++)
make deploy_utils     # Deploy utility scripts from prompts
```

## Multi-Compiler Support
Arch Linux provides both `g++` and `clang++`. The Makefile auto-detects available compilers:

```bash
# Build with default compiler (g++)
make all

# Build per-compiler test binaries
make test001_staticlib_g++
make test001_staticlib_clang++

# Run full multi-compiler test cycle
make test-all
```

### Compiler Configuration
| Compiler | LTO Flag | Default | Notes |
|----------|----------|---------|-------|
| `g++` (16.2.1) | `-flto` | ✅ Yes | Primary compiler, full LTO |
| `clang++` (22.1.8) | `-flto=thin` | — | Secondary compiler, thinLTO |

## Running Tests

### Full Verification (All 7 Test Scenarios)
```bash
make verify
```
This runs the complete test matrix with the default compiler (g++) and generates reports in `reports/`.

### Multi-Compiler Verification
```bash
make test-all
```
Runs the full test matrix with each available compiler, generating per-compiler reports.

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
| Test ID | Description | Transform | Error Mode | Expected Exit Code | Output Check |
|---------|-------------|-----------|------------|-------------------|--------------|
| T001    | Identity (normal) | 0 (none) | 0 (no error) | 0 | ✅ Yes |
| T002    | Stress test (1 slot, 1 byte) | 0 (none) | 0 (no error) | 0 | ✅ Yes |
| T003    | Uppercase transform | 1 (uppercase) | 0 (no error) | 0 | ✅ Yes |
| T004    | Small input, fast EOF | 0 (none) | 0 (no error) | 0 | ✅ Yes |
| T005    | Fatal error mode | 0 (none) | 1 (fatal) | 1 | ❌ Exit code only |
| T006    | Non-fatal error mode | 0 (none) | 2 (non-fatal) | 0 | ✅ Yes |
| T007    | XOR transform | 2 (XOR 0xFF) | 0 (no error) | 0 | ✅ Yes |

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
# Validate test data against expected outputs
utils/bin/verify_test_data.zsh

# Verify specific test case
utils/bin/verify_test_data.zsh -t T001
```

### JUnit Report Generation
```bash
# Generate JUnit XML and Markdown reports from test logs
utils/bin/generate_junit_report.zsh
```

## Regression Results (Arch Linux)
All 7 tests pass on both g++ and clang++:

| Compiler | T001 | T002 | T003 | T004 | T005 | T006 | T007 | Total |
|----------|------|------|------|------|------|------|------|-------|
| g++ 16.2.1 | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | 7/7 |
| clang++ 22.1.8 | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | 7/7 |

## Notes
- Source files are byte-identical to `src/macos/cpp/tests/src/test001.cpp`
- Test data (inputs/expected) is shared across all platforms
- T005 validates exit code only (no output comparison) — the test binary returns 1 when `error_mode=1`
- No container support on Apple Silicon — all builds/tests run natively via SSH to remote Linux host
