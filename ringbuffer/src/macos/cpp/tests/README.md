# Testing Requirements - Ringbuffer (macOS, C++)

## Test Directory Structure
The testing environment is organized as follows to ensure isolation of test logic, data, and artifacts:

```text
tests/
├── src/                # Test source code
├── data/               # Test assets and fixtures
│   ├── inputs/         # Files for the Reader to process
│   └── expected/       # "Golden" files for verifying Writer output
├── bin/                # Compiled test binaries
└── utils/              # Test utility scripts and tools
    └── bin/            # Compiled utility binaries
```

## General Requirements
- All test directories contain a `.required_directory` file.
- Test binaries are isolated in the `bin/` directory.
- A `README.md` is provided in the `tests/` directory describing the test suite and build process.

## Artifact Verification
Before running functional tests, the build artifacts must be verified:
- **Architecture**: Use `lipo -info <artifact>` to verify both `arm64` and `x86_64` slices.
- **Install Name**: Use `otool -L <dylib>` to verify the install name is `@rpath/libswtr_ringbuffer.dylib`.
- **Binary Size**: Use `size -m <artifact>` to verify dead code elimination efficiency.
- **Symbol Visibility**: Use `nm -gjU <artifact>` to verify internal symbols are hidden.

## Test Data Generation
Test files (`test001.txt` through `test005.txt`) are generated in `tests/data/inputs/` using a zig-zag space pattern.

### Utility Script
A Zsh script is provided at `tests/utils/bin/generate_test_data.zsh` to automate this:
- **Usage**: `generate_test_data.zsh [-l lines] [output_file]`
- **Options**: `-l lines` (default: 10), `-h` (usage).

## Test Binary Build Requirements
Test binaries are configured to verify different linking scenarios:
- **Static Linking (`test001_staticlib`)**: Links directly to the static library file (`../lib/libswtr_ringbuffer.a`) to ensure the linker does not prefer the shared library.

## Test Program Interface (`test001_staticlib`)
Usage: `test001_staticlib [-o output_file] [-l log_file] [-s slots] [-b size] [-t transform_type] [-e error_mode] [-r] [-w <ip:port>] <input_file>`

- **Options**:
    - `-o output_file`: Destination for `write_fd` (default: `stdout`).
    - `-l log_file`: Logger output (default: `stderr`).
    - `-s slots`: Number of ringbuffer slots (default: `4`).
    - `-b size`: Buffer size per slot (default: `4096`).
    - `-t transform_type`: `0`: None, `1`: Uppercase, `2`: XOR 0xFF.
    - `-e error_mode`: `0`: No error, `1`: Fatal (pipeline stops), `2`: Non-fatal (pipeline continues).
    - `-r`: Optional. Attaches `read_fd` to a socket. The app opens a socket on `127.0.0.1`, prints `LISTEN_PORT=<port>` to `stdout`, and uses the socket returned by `accept()` as the `read_fd`.
    - `-w <ip:port>`: Optional. Attaches `write_fd` to a socket. The app connects to the specified IP and port and uses the resulting socket as the `write_fd`.

## Running Tests

### Examples: Running Test Matrix Scenarios
Here are examples of how to execute the first few scenarios from the test matrix using the static library binary:

- **T001 (Standard Run)**: Exact match with input.
  ```bash
  ./bin/test001_staticlib data/inputs/test001.txt 2> t001.log
  ```
- **T002 (Stress Test)**: Minimum slots and buffer size.
  ```bash
  ./bin/test001_staticlib -s 1 -b 1 data/inputs/test001.txt 2> t002.log
  ```
- **T003 (Uppercase Transform)**: Small buffer with uppercase transformation.
  ```bash
  ./bin/test001_staticlib -b 10 -t 1 data/inputs/test001.txt 2> t003.log
  ```

## Test Matrix
The test suite executes the following scenarios:

| Test ID | Input File | Slots | Size | Transform | Error | Expected Outcome |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `T001` | `test001.txt` | 4 | 4096 | 0 | 0 | Exact match with input; Success. |
| `T002` | `test001.txt` | 1 | 1 | 0 | 0 | Exact match (Stress test); Success. |
| `T003` | `test001.txt` | 4 | 10 | 1 | 0 | All chars uppercase; Success. |
| `T004` | `test001.txt` | 4 | 4096 | 0 | 0 | Input < 1 slot; fast EOF termination; Success. |
| `T005` | `test001.txt` | 4 | 4096 | 0 | 1 | Pipeline stop; Exit status 1. |
| `T006` | `test001.txt` | 4 | 4096 | 0 | 2 | Pipeline continues; Success. |
| `T007` | `test001.txt` | 4 | 4096 | 2 | 0 | Bit-inverted output; Success. |
