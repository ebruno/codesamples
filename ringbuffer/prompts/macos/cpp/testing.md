# Testing Requirements - Ringbuffer (macOS, C++)

## Test Directory Structure
The testing environment must follow this directory structure to ensure isolation of test logic, data, and artifacts:

```text
tests/
├── src/                # Test source code
│   └── .required_directory
├── data/               # Test assets and fixtures
│   ├── inputs/         # Files for the Reader to process
│   │   └── .required_directory
│   ├── expected/       # "Golden" files for verifying Writer output
│   │   └── .required_directory
│   └── .required_directory
├── bin/                # Compiled test binaries
│   └── .required_directory
├── utils/              # Test utility scripts and tools
│   ├── bin/            # Compiled utility binaries
│   │   └── .required_directory
│   └── .required_directory
└── .required_directory
```

## General Requirements
- All test directories must contain a `.required_directory` file.
- Test binaries should be isolated in the `bin/` directory.
- Use `tests/data/inputs` for source files and `tests/data/expected` for verification of the final output.
- A `README.md` file must be provided in the `tests/` directory describing the test suite, build process, and how to run the tests, including specific examples of how to run test scenarios T001, T002, and T003, with stderr redirected to corresponding log files (e.g., `2> t001.log`).
- **Verification Scope**: Tests must verify not only the functional output (data integrity) but also the operational constraints (memory alignment, thread termination, and binary size).

## Artifact Verification
Before running functional tests, the build artifacts must be verified to ensure they meet the "Small Binary" and Toolchain goals:
- **Architecture**: Use `lipo -info <artifact>` to verify that both `arm64` and `x86_64` slices are present.
- **Install Name**: Use `otool -L <dylib>` to verify that the install name is set to `@rpath/libswtr_ringbuffer.dylib`.
- **Binary Size**: Use `size -m <artifact>` to verify that dead code elimination has reduced the binary size to the expected baseline.
- **Symbol Visibility**: Use `nm -gjU <artifact>` to verify that internal symbols are hidden and that the public API is strictly limited to the intended interface.

## Test Data Generation
Generate 5 test files in `tests/data/inputs/` (named `test001.txt` through `test005.txt`) using the zig-zag space pattern:
- `test001.txt`: 25 lines
- `test002.txt`: 50 lines
- `test003.txt`: 75 lines
- `test004.txt`: 100 lines
- `test005.txt`: 150 lines

**Pattern Specification**:
1. Template line: `NNNN ABCEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<> NNNN`
2. `NNNN` is a 4-digit sequence number starting at `0001` and incrementing per line.
3. Line 1 has no space.
4. Line 2 replaces the 2nd character ('B') with a space.
5. Subsequent lines move the space one position to the right until the last character ('>') is replaced.
6. Then the pattern reverses, moving the space one position to the left until the 1st character ('A') is replaced.
7. This zig-zag continues until the target number of lines is reached.

## Test Utility Scripts
A Zsh script must be provided at `tests/utils/bin/generate_test_data.zsh` to automate the generation of test data.

**Script Requirements**:
- **Shebang**: `#!/usr/bin/env zsh`
- **Usage**: `generate_test_data.zsh [-l lines] [output_file]`
- **Options**:
    - `-l lines`: Number of lines to generate. Defaults to `10`.
    - `-h`: Display usage information.
- **Arguments**:
    - `output_file`: Optional. If specified, the output is written to this file. If omitted, output is printed to `stdout`.
- **Logic**: Must implement the zig-zag space pattern described in the "Test Data Generation" section.

## Test Binary Build Requirements
Test binaries must be configured to verify different linking scenarios:
- **Static Linking (`test001_staticlib`)**:
    - Must link directly to the static library file (e.g., using the path `../lib/libswtr_ringbuffer.a`) rather than the `-lswtr_ringbuffer` flag. This ensures the linker does not prefer the shared library (`.dylib`).
    - The output binary should be placed in the `bin/` directory.
- **Headers**: Must include the directory `ringbuffer/src/macos/cpp` in the search path.

## Test Program Interface (`test001_staticlib`)
The test program must support the following command-line interface:
`test001_staticlib [-o output_file] [-l log_file] [-s slots] [-b size] [-t transform_type] [-e error_mode] <input_file>`

- **Arguments**:
    - `<input_file>`: Required. Path to the binary input file to be processed.
- **Options**:
    - `-o output_file`: Optional. Specifies a file to use for the RingBuffer's `write_fd`. Defaults to `stdout`.
    - `-l log_file`: Optional. Specifies a file for logger output. Defaults to `stderr`.
    - `-s slots`: Optional. Overrides the number of slots in the ringbuffer. Defaults to `4`.
    - `-b size`: Optional. Overrides the buffer size per slot. Defaults to `4096`.
    - `-t transform_type`: Optional. Specifies the transformation logic:
        - `0`: None (Identity/Bypass).
        - `1`: Uppercase.
        - `2`: XOR with 0xFF.
    - `-e error_mode`: Optional. Simulates an error condition:
        - `0`: No error.
        - `1`: Fatal error (return non-zero from handler, pipeline must stop).
        - `2`: Non-fatal error (return zero from handler, pipeline must continue).
- **Behavior**:
    - Must print "waiting for ringbuffer" to `stdout` before calling `rb.wait()`.
    - Must flush `stdout` after the RingBuffer completes processing.
    - Must return exit status `1` if the input file cannot be opened, a fatal exception occurs, or the error mode was set to `1`.

## Test Matrix
The test suite must execute the following scenarios to ensure full coverage:

| Test ID | Input File | Slots | Size | Transform | Error | Expected Outcome |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `T001` | `test001.txt` | 4 | 4096 | 0 | 0 | Exact match with input; Success. |
| `T002` | `test001.txt` | 1 | 1 | 0 | 0 | Exact match (Stress test); Success. |
| `T003` | `test001.txt` | 4 | 10 | 1 | 0 | All chars uppercase; Success. |
| `T004` | `test001.txt` | 4 | 4096 | 0 | 0 | Input < 1 slot; fast EOF termination; Success. |
| `T005` | `test001.txt` | 4 | 4096 | 0 | 1 | Pipeline stop; Exit status 1. |
| `T006` | `test001.txt` | 4 | 4096 | 0 | 2 | Pipeline continues; Success. |
| `T007` | `test001.txt` | 4 | 4096 | 2 | 0 | Bit-inverted output; Success. |

- All code is covered under a BSD 3-Clause License.
