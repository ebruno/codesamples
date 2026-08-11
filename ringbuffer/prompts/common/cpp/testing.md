# Testing Requirements - Ringbuffer (Common C++)

**Implementation Directive:**
This testing specification MUST be followed exactly to ensure that the validation process is identical across all target platforms and ensures binary symmetry.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/cpp/testing.md`) conflict with common specs (`prompts/common/cpp/testing.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

## Platform and Container Runtime Reference

**Native-Only Platforms** (no container support):
- **macOS**: All builds and tests run natively on the host. Containers are prohibited.
- **FreeBSD** (any version): All builds and tests run natively on the host. Containers are prohibited.

**Container-Supported Platforms** (Linux distributions):
- **Fedora**, **Ubuntu**, **Debian**, **RHEL**, **ArchLinux**: Builds and tests run in containers when the host OS does not match the target OS.

**Container Runtime Selection**:
- **macOS hosts**: Use the `container` command (Apple Container). Docker (`docker`) is NOT allowed.
- **Linux hosts**: Use `podman`. Docker (`docker`) is NOT allowed.

**Host-Target Rule**:
- If the host OS matches the target OS (e.g., Fedora build on a Fedora host), native execution is permitted.
- If the host OS does not match the target OS (e.g., macOS build targeting Ubuntu), a container matching the target OS MUST be used.
- If the target is macOS or FreeBSD, containers are NEVER used regardless of host OS.

## Infrastructure
To ensure consistency across environments, the following infrastructure strategy MUST be used:
- **Linux (Debian, Fedora, etc.)**: All build, verification, and testing activities MUST be performed within the `ringbuffer_<os>_test` container. The container is the authoritative environment.
- **macOS**: All activities MUST be performed natively on the host system using native build artifacts. Containers MUST NOT be used for macOS targets.

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
├── logs/               # Test execution logs
│   └── .required_directory
├── reports/            # Machine-readable test reports (JUnit XML)
│   └── .required_directory
├── containers/             # OS-specific container configurations
│   └── [platform]/
│       └── .required_directory
├── utils/              # Test utility scripts and tools
│   ├── bin/            # Compiled utility binaries
│   │   └── .required_directory
│   └── .required_directory
└── .required_directory
```

## Temporary Workspace
- **Centralized Storage**: All temporary files, utility scripts, or intermediate data generated during the execution of this prompt MUST be placed in a directory named `ringbuffer/tmp`.
- **Isolation**: Do NOT create temporary files (e.g., `.py`, `.txt`, `.sh` scripts used for auditing or listing) in the project root, source directories, or any other permanent project location.

## General Requirements
- All test directories must contain a `.required_directory` file.
- Test binaries should be isolated in the `bin/` directory.
- Use `tests/data/inputs` for source files and `tests/data/expected` for verification of the final output.
- A `README.md` file must be provided in the `tests/` directory describing the test suite, build process, and how to run the tests, including specific examples of how to run test scenarios T001, T002, and T003, with stderr redirected to corresponding log files in the logs directory (e.g., `2> logs/t001.log`). This file must also document the purpose and usage of the `tests/containers` directory.
- **Directory Initialization**: The `tests/logs` and `tests/reports` directories must be created if they do not exist before running any test scenarios.
- **The `_test` Image Mandate**: For Linux platforms, the image built from `tests/containers/<platform>/Dockerfile` (named `ringbuffer_<os>_test`) is the **authoritative environment** for the entire verification lifecycle. It MUST be equipped with all dependencies required to compile the main library, compile the test binaries, and execute the full test suite.
- **Container Command Usage**: When providing examples for using the containers in the `README.md` or other documentation:
    - On **macOS (including arm64 Apple Silicon)**, use the `container` command instead of `docker`. Docker (`docker`) is NOT allowed on macOS.
    - On **Fedora**, **Debian**, and **Ubuntu**, use the `podman` command instead of `docker`. Docker (`docker`) is NOT allowed on Linux.
- **Verification Scope**: Tests must verify not only the functional output (data integrity) but also the operational constraints (memory alignment, thread termination, and binary size).

## Build Configuration Standard
To avoid pathing ambiguity across different environments, the following standards MUST be used:
- **Source Includes**: In test source files, include headers using the relative filename: `#include "ringbuffer.hpp"`. Do NOT use `../` or absolute paths within the `#include` directives.
- **Makefile Search Path**: The `Makefile` MUST provide the necessary include path using the `-I` flag (e.g., `-I..`) to ensure the compiler finds the headers in the parent implementation directory.

## Artifact Verification
Before running functional tests, the build artifacts must be verified to ensure they meet the "Small Binary" and Toolchain goals:
- **Architecture**: Use the `file` command to verify the binary architecture (e.g., x86-64).
- **SONAME**: Use `readelf -d <so>` to verify that the SONAME is set to `libswtr_ringbuffer.so`.
- **Binary Size**: Use `size -m <artifact>` to verify that dead code elimination has reduced the binary size to the expected baseline.
- **Symbol Visibility**: Use `nm -gjU <artifact>` to verify that internal symbols are hidden and that the public API is strictly limited to the intended interface.

## Test Data Generation
After the test utility scripts are created, the following 7 test files MUST be generated in `tests/data/inputs/` (named `test001.txt` through `test007.txt`) using the zig-zag space pattern:
- `test001.txt`: 25 lines
- `test002.txt`: 50 lines
- `test003.txt`: 75 lines
- `test004.txt`: 100 lines
- `test005.txt`: 150 lines
- `test006.txt`: 200 lines
- `test007.txt`: 250 lines

**Generation Tool Selection**:
The authoritative scripts are located in `ringbuffer/prompts/common/cpp/utils/bin/`. They MUST be deployed to `tests/utils/bin/` during environment setup.
- **Linux (Fedora, Debian, etc.)**: Use the `tests/utils/bin/generate_test_data.sh` script.
- **Darwin/macOS**: Use the `tests/utils/bin/generate_test_data.zsh` script.

**Format and Character Set Specification**:
To ensure binary symmetry and prevent generation errors, all input files MUST adhere to these exact constraints:
- **Literal Character Set**: The internal template string MUST be exactly: `"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"`. Do not omit any characters or add any others.
- **Strict Line Format**: Every line MUST follow this exact format: `[4-digit sequence] [single space] [47-char payload] [single space] [4-digit sequence]`.
- **Total Line Length**: Exactly 57 characters (excluding the newline). This is achieved by: 4 digits $\rightarrow$ 1 space $\rightarrow$ exactly 47 characters of template/modified content $\rightarrow$ 1 space $\rightarrow$ 4 digits.
- **Prefix**: Characters 1-4 must be digits, and character 5 MUST be a space.
- **Suffix**: Character 53 MUST be a space, and characters 54-57 must be digits.
- **Internal Template**: The template content must occupy characters 6 through 52.

**Pattern Specification**:
1. Template line: `NNNN ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<> NNNN`
2. `NNNN` is a 4-digit sequence number starting at `0001` and incrementing per line.
3. **Space Position Logic**:
   - Let $L$ be the length of the internal template string.
   - For line $n=1$, no space is inserted.
   - For line $n > 1$, calculate a 0-based index $i$ into the template:
     - Let $idx = n - 2$.
     - Let $cycle = 2 \times (L - 1)$.
     - Let $off = idx \pmod{cycle}$.
     - If $off < L - 1$, then $i = off + 1$. Otherwise, $i = cycle - off$.
   - Replace the character at index $i$ with a space.

**Reference Implementation (Python)**:
The following Python script serves as the ground truth for the zig-zag pattern. Shell implementations MUST produce identical output:

```python
def generate_zigzag_line(n: int) -> str:
    """Generate a single zig-zag test data line."""
    template = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
    prefix = f"{n:04d} "
    suffix = f" {n:04d}"
    
    if n == 1:
        return prefix + template + suffix
    
    L = len(template)
    idx = n - 2
    cycle = 2 * (L - 1)
    off = idx % cycle
    
    if off < L - 1:
        i = off + 1
    else:
        i = cycle - off
    
    chars = list(template)
    chars[i] = ' '
    return prefix + ''.join(chars) + suffix
```

To generate all test files, call `generate_zigzag_line(n)` for each line number $n$ from 1 to the desired count.
4. This ensures the space zig-zags from the 2nd character to the last character and back.

**Data Validation**:
After generation, the agent MUST verify the integrity of the data using a programmatic validator.

**Verification Tool**: A script named `tests/utils/bin/verify_test_data.sh` MUST be implemented to programmatically validate these constraints. The script MUST use the following regular expression to validate line format: `^[0-9]{4} .{47} [0-9]{4}$`.

The agent MUST verify:
- The line counts for `test001.txt` through `test007.txt` are exactly as specified.
- The `verify_test_data.sh` script returns a success exit code for all seven files.

## Shell Scripting Mandate
- **Language Selection**:
  - For **macOS** targets: All scripts MUST be written in **Pure Zsh**.
  - For **Linux** targets (Debian, Fedora, Ubuntu, ArchLinux): All scripts MUST be written in **Pure Bash**.
  - For **Tcsh** scripts: All scripts MUST be written in **Pure Tcsh**.
- **Minimum Version Requirements**:
  - **Zsh**: Version **5.8** or higher.
  - **Bash**: Version **5.0** or higher.
  - **Tcsh**: Version **6.22** or higher.
- **Version Enforcement**: Every script MUST implement a version check at the beginning of the file. Use shell-native version variables. For Zsh, extract the major and minor versions using parameter expansion (e.g., `major=${ZSH_VERSION%%.*}` and `minor=${ZSH_VERSION#*.}`) and perform numeric comparisons to enforce the minimum version. If the current shell version is below the minimum, the script must print a clear error message and exit with a non-zero status.
- **Implementation Style**: MUST use shell built-ins (parameter expansion, arrays, and redirection) for all data processing, file reading, and line counting. The use of external programs (e.g., `wc`, `sed`, `awk`, `cut`, `grep`, `cat`) is strictly prohibited for these tasks to ensure maximum portability and performance.
- **Shell-Specific Idioms**: 
    - When implementing for **Zsh**, be mindful that string and array indexing is **1-based** by default.
    - Use shell-native string replacement or array assignment to modify specific characters in the template string.
    - Ensure regex patterns in `[[ ... ]]` are properly quoted to avoid expansion errors.
- **Script Portability Standard**:
  - **Shebang**: All utility scripts MUST use the `/usr/bin/env` wrapper for their shebang line to ensure portability across different shell installations (e.g., `#!/usr/bin/env zsh`, `#!/usr/bin/env bash`, `#!/usr/bin/env tcsh`, `#!/usr/bin/env sh`). Absolute paths to shells (e.g., `#!/bin/zsh`) MUST NOT be used.
  - **Utility Usage**: Avoid platform-specific flags for standard utilities. For example, when using `sed -i`, be aware that macOS (BSD) and Linux (GNU) have different syntax. Prefer using temporary files or standard redirection for modifications to ensure cross-platform compatibility.

## Test Utility Scripts
The following scripts must be provided to automate the generation of test data and report processing. These scripts are centrally managed in `ringbuffer/prompts/common/cpp/utils/bin/` and MUST be copied/symlinked to `tests/utils/bin/` during setup:
- Zsh script: `tests/utils/bin/generate_test_data.zsh`
- Bash script: `tests/utils/bin/generate_test_data.sh`
- Tcsh script: `tests/utils/bin/generate_test_data.tcsh`
- Bourne shell script: `tests/utils/bin/generate_test_data_bin_sh.sh`
- JUnit XML Generator: `tests/utils/bin/generate_junit_report.sh`

**JUnit Report Generation Requirements**:
The `generate_junit_report.sh` script must:
1. Parse the test results (exit codes and logs) from the `logs/` directory.
2. Capture the execution time for each test scenario.
3. Generate a `regression_report_junit.xml` in `tests/reports/` following the mandated JUnit XML structure.

**Scripting Standards**:
- **Arithmetic**: For all numeric comparisons and calculations in Bash/Zsh, use the double-parentheses syntax `(( ... ))` (e.g., `if (( line_num > 1 )); then`) instead of the POSIX `[ ]` bracket syntax to avoid integer expression errors.

**Script Documentation Requirements**:
Each of the following scripts must be documented (via usage messages and/or comments) to include their purpose, usage, and options:
- `generate_test_data.zsh`
- `generate_test_data.sh`
- `generate_test_data.tcsh`
- `generate_test_data_bin_sh.sh`
- `generate_junit_report.sh`

**General Script Requirements**:
- **Usage**: `generate_test_data.[ext] [-l lines] [output_file]`
- **Options**:
    - `-l lines`: Number of lines to generate. Defaults to `10`.
    - `-h`: Display usage information.
- **Arguments**:
    - `output_file`: Optional. If specified, the output is written to this file. If omitted, output is printed to `stdout`.
- **Output Handling**: If an `output_file` is specified, the script MUST overwrite the existing file (truncate) using `>` or `exec >` and MUST NOT use the append operator `>>` for the primary output. This ensures that subsequent runs of the generator do not result in files with incorrect line counts.
- **Logic**: Must implement the zig-zag space pattern described in the "Test Data Generation" section.

## Test Binary Build Requirements
Test binaries must be configured to verify different linking scenarios:
- **Static Linking (`test001_staticlib`)**:
    - MUST link directly to the static library file (e.g., using the path `../lib/libswtr_ringbuffer.a`).
    - MUST NOT use the `-lswtr_ringbuffer` flag or any other mechanism that might resolve to the shared library (`.so`).
    - The output binary should be placed in the `bin/` directory.
- **Dynamic Linking (`test001_dynamiclib`)**:
    - MUST link against the shared library using the `-lswtr_ringbuffer` flag.
    - MUST use the `rpath` option (e.g., `-Wl,-rpath,$(abspath ../lib)`) to ensure the binary can locate the shared library at runtime.
    - The output binary should be placed in the `bin/` directory.
- **Headers**: Must include the project's primary implementation directory in the search path.
- **Mandatory Includes**: Must include `<fcntl.h>` for file control options, `<iostream>` for standard I/O, and the following networking headers: `<netinet/in.h>`, `<sys/socket.h>`, and `<arpa/inet.h>`.
- **Code Quality**: Must handle unused function parameters (e.g., using `(void)param;`) to ensure the code compiles without `-Wunused-parameter` warnings.
- **Makefile Macros**: MUST define a macro `RM = rm -f` and use it for all file removal operations.
- **Cleanup Requirements**: The `Makefile` must provide the following targets:
    - `clean`: MUST remove the **contents** of the `bin/` and `data/expected/` directories using `$(RM) -r` (e.g., `bin/*` and `data/expected/*`), while **preserving the directories themselves**. It MUST also remove all object files (`*.o`), all log files in `logs/` using `$(RM) -r`, and any backup files (`*~` and `#*#`) using `$(RM)`.
    - `dist-clean`: Must perform a full cleanup by calling the `clean` target and explicitly removing both the `logs/` and `reports/` directories using `$(RM) -r`.

## Test Makefile Requirements
The `tests/Makefile` is the authoritative orchestrator for the test suite:
- **`container` Target**: MUST build the `ringbuffer_<os>_test` image from the `Dockerfile` in `tests/containers/<os>/`.
- **Invalidation Logic**: The `container` target MUST rebuild the image if the `Dockerfile` OR `version.mk` has been modified since the image was created.
- **`verify` Target**: MUST orchestrate the Artifact Verification, the full Test Matrix execution (capturing execution time for each test), and the generation of the JUnit XML report in `tests/reports/regression_report_junit.xml`.
- **Dependency**: The `verify` target MUST depend on the library and test binaries being current.
- **Utility Deployment**: The `Makefile` MUST ensure that authoritative scripts from `ringbuffer/prompts/common/cpp/utils/bin/` are copied or symlinked into `tests/utils/bin/` before any generation or verification steps are performed.

## Test Program Interface (`test001`)
The test program must support the following command-line interface:
`test001_staticlib [-o output_file] [-l log_file] [-s slots] [-b size] [-t transform_type] [-e error_mode] [-r] [-w <ip:port>] <input_file>`

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
    - `-r`: Optional. Indicates that `read_fd` should be attached to a socket.
        - The application must open a socket and use `SO_REUSEADDR` to allow immediate reuse of the port.
        - It must obtain the port number and print `"LISTEN_PORT=<port>"` followed by `std::endl` to `stdout`.
        - It must call `accept()`.
        - If `accept()` returns a value other than `-1`, that value is used as the `read_fd` passed to the ringbuffer.
        - If `accept()` returns `-1`, the socket must be closed and the program must exit.
    - `-w <ip:port>`: Optional. Indicates that `write_fd` should be attached to a socket.
        - The parameter must be a string in the format `N[NN].N[NN].N[NN].N[NN]:<port>`.
        - The application must attempt to connect to the specified IP and port.
        - If the connection is successful, the resulting socket file descriptor is used as the `write_fd` passed to the ringbuffer.
        - If the connection fails, the program must report an error and terminate.
- **Implementation Note**: Use `std::make_unique<SwtrRingBuffer>` to instantiate the ring buffer. The `ErrorHandler` and `TransformFn` functions passed to the constructor MUST be non-capturing lambdas (or raw function pointers) to ensure they are compatible with the defined types (`ErrorHandler` and `TransformFn`) and compatible with `std::make_unique`.

- **Behavior**:
    - If no input file is provided, the program MUST print a usage message to `std::cerr` and return exit status `1`.
    - All operational errors (e.g., socket creation, bind, accept, or file open failures) MUST be reported to `std::cerr` with descriptive messages.
    - The program MUST use `try-catch` blocks to handle `std::exception` and print the error message to `std::cerr`.

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
