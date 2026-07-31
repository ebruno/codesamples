# Ringbuffer Test Suite (macOS, C++)

This directory contains the test suite for the `swtr_ringbuffer` library. It is designed to verify the functional requirements of the three-stage pipeline (Read $\rightarrow$ Transform $\rightarrow$ Write) under various linking scenarios and data patterns.

## Directory Structure

```text
tests/
├── src/                # Test source code (e.g., test001.cpp)
├── data/               # Test assets and fixtures
│   ├── inputs/         # Source files for the Reader stage
│   └── expected/       # Golden files for verifying the Writer output
├── bin/                # Compiled test binaries
└── utils/              # Test utility scripts
    └── bin/            # Compiled utility binaries (e.g., generate_test_data.zsh)
```

## Building the Tests

The test suite uses GNU Make. To build the tests, ensure the main library is built first, then run `make` from the `tests/` directory.

```bash
# From ringbuffer/src/macos/cpp/tests
make
```

### Target Binaries
The build process generates two versions of the same test logic to verify linking:
- `bin/test001_staticlib`: Linked against the static library (`libswtr_ringbuffer.a`).
- `bin/test001_dynlib`: Linked against the shared library (`libswtr_ringbuffer.dylib`) with an embedded absolute RPATH.

## Running Tests

The test binaries accept the following command-line interface:

```bash
./bin/test001_{staticlib|dynlib} [-o output_file] [-l log_file] <input_file>
```

### Arguments & Options
- `<input_file>`: **Required**. Path to the binary input file to be processed.
- `-o output_file`: **Optional**. File to use for the writer output. If omitted, output goes to `stdout`.
- `-l log_file`: **Optional**. File to use for logger output. If omitted, logs go to `stderr`.

### Example
To process a test file, save the output to a file, and capture logs:
```bash
./bin/test001_staticlib -o results.txt -l test.log data/inputs/test001.txt
```

## Test Data Generation

A utility script is provided to generate specific test patterns used to verify the ring buffer's stability and correctness.

### Utility Script
Location: `utils/bin/generate_test_data.zsh`

**Usage**:
```bash
./utils/bin/generate_test_data.zsh [-l lines] [output_file]
```
- `-l lines`: Number of lines to generate (default: 10).
- `output_file`: Optional file to write to. Defaults to `stdout`.

### The Zig-Zag Pattern
The script generates a "zig-zag" space pattern to test data consistency:
1. **Line 1**: No space in the template.
2. **Right Shift**: The space moves from the 2nd character ('B') one position to the right per line until the last character ('>') is reached.
3. **Left Shift**: The space moves one position to the left per line until the 1st character ('A') is reached.
4. **Repeat**: This pattern continues until the requested number of lines is reached.

This pattern ensures that every single byte position in the buffer is exercised as a "gap" or "modification" during the pipeline's lifecycle.
