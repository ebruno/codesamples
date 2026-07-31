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


