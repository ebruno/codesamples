# Testing Requirements - Ringbuffer (Common C++)

**Implementation Directive:**
This testing specification MUST be followed exactly to ensure that the validation process is identical across all platforms (macOS, Linux — debian, fedora, ubuntu, raspios) and ensures binary symmetry.

**Test Process Consistency Mandate:** The test execution process MUST be byte-identical across all platforms. When generating or updating the test suite for any platform:
- The `tests/Makefile` MUST match across platforms, except for container image name, Dockerfile path, report title (Linux only), and macOS native test execution
- The test matrix (T001–T007) MUST be identical in parameters, expected outcomes, and execution order
- The regression report format (both Markdown and JUnit XML) MUST be byte-identical across platforms
- The container build → test execution → report generation workflow MUST follow the same sequence

When updating tests for one platform, apply identical changes to all platforms.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/cpp/testing.md`) conflict with common specs (`prompts/common/cpp/testing.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

> **Quick Reference:** For platform-specific toolchain details (otool, lipo, size -m), binary format comparison tables (ELF vs Mach-O), and shared library linking conventions, see `prompts/common/cpp/session_hints.md`.

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

## Host-Target Compatibility
Build and test prompts may only be executed under the following conditions:
- **macOS host**: The target OS MUST be macOS. No container support is available for macOS — builds must run natively.
- **Linux host**: If the host distro does not match the target OS (e.g., Fedora build run from macOS or Ubuntu host), a container matching the target OS MUST be used. The Makefile's container-build override handles this automatically: `UNAME_S=macOS` ⇒ `container` command; non-matching Linux distro ⇒ `podman`. When the host already matches the target (e.g., Fedora build on Fedora), native execution is permitted.

## Container Runtime Pre-flight (macOS Host)
When the host OS is macOS and the target OS is a Linux distribution, the `container` command MUST be available in PATH before any container operations proceed.
- **Verification**: Execute `command -v container` to confirm availability.
- **Error Handling**: If `container` is NOT found, STOP and display:
  ```
  ERROR: The 'container' command is required for cross-OS builds from macOS to Linux targets, but it was not found in PATH.
  
  Please install Apple Container from: https://github.com/apple/container
  
  After installation, ensure the 'container' command is available in your PATH and re-run the build workflow.
  ```

**CRITICAL: Never Attempt Native Linux Builds on macOS**

When the target OS is a Linux distribution (Ubuntu, Fedora, Debian, RHEL, ArchLinux) and the host OS is macOS:
- **NEVER** attempt to compile or link Linux binaries natively on the macOS host. The resulting binaries will be Mach-O (macOS) format, not ELF (Linux), and will fail at runtime.
- **NEVER** use `g++` or `clang++` directly on the host to produce Linux artifacts.
- **ALWAYS** use a container matching the target OS for all build, test, and verification steps.
- If the container runtime is not available or fails to start, **STOP** and report an error. Do not fall back to native compilation.

This rule exists because macOS `clang++` produces Mach-O binaries and macOS `g++` (if installed via Homebrew) still targets the host architecture. Cross-compilation from macOS to Linux requires a proper cross-toolchain or, more reliably, a container.

**Excluded Platforms:**
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development.
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/`.
- The only files that should exist in these directories are zero-length `build.md`, `functional.md`, and `testing.md` files.
- If these directories contain any non-zero files, remove them.

## Infrastructure
To ensure consistency across environments, the following infrastructure strategy MUST be used:
- **Linux (Debian, Fedora, etc.)**: All build, verification, and testing activities MUST be performed within the `ringbuffer_<os>_test` container. The container is the authoritative environment.
- **macOS**: All activities MUST be performed natively on the host system using native build artifacts. Containers MUST NOT be used for macOS targets.

## Execution Workflow — Host Detection Step

Before performing ANY build, test, or verification step, you MUST execute this decision tree:

1. **Detect Host OS**: Run `uname -s` to determine the host operating system.
2. **Determine Target OS**: Identify which platform you are building/testing for (from the prompt context).
3. **Apply Routing Rule**:
   - If host is macOS and target is Linux (Ubuntu, Fedora, Debian, RHEL, ArchLinux):
     - **MUST** use a container. All build and test commands MUST be wrapped in `container run --rm -v <paths> ringbuffer_<target>_test`.
     - **NEVER** run `g++`, `clang++`, or `make` directly on the host for Linux targets.
   - If host is macOS and target is macOS:
     - Run natively on the host. Containers are prohibited.
   - If host is Linux and target matches host distro:
     - Run natively.
   - If host is Linux and target differs from host distro:
     - **MUST** use a container matching the target OS.
   - If target is FreeBSD:
     - Run natively on FreeBSD host. Containers are prohibited.

4. **Verify Container Availability**: If routing requires a container, verify the runtime is available before proceeding:
   - macOS: `command -v container` — if not found, STOP and report with installation instructions.
   - Linux: `command -v podman` — if not found, STOP and report.

5. **Log Your Decision**: Before executing any build or test command, print a one-line summary:
   ```
   HOST=<uname -s> TARGET=<target_os> ROUTING=container|native REASON=<brief explanation>
   ```

This step MUST be performed before every build or test operation, not just once at the beginning.

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
- **Centralized Storage**: All temporary files, utility scripts, or intermediate data generated during the execution of this prompt MUST be placed in a directory named `tmp`.
- **Isolation**: Do NOT create temporary files (e.g., `.py`, `.txt`, `.sh` scripts used for auditing or listing) in the project root, source directories, or any other permanent project location.

## General Requirements
- All test directories must contain a `.required_directory` file.
- Test binaries should be isolated in the `bin/` directory.
- Use `tests/data/inputs` for source files and `tests/data/expected` for verification of the final output.
- A `README.md` file must be provided in the `tests/` directory describing the test suite, build process, and how to run the tests, including specific examples of how to run test scenarios T001, T002, and T003, with stderr redirected to corresponding log files in the logs directory (e.g., `2> logs/t001.log`). This file must also document the purpose and usage of the `tests/containers` directory.
- **Directory Initialization**: The `tests/logs` and `tests/reports` directories must be created if they do not exist before running any test scenarios.
- **The `_test` Image Mandate**: For Linux platforms, the image built from `tests/containers/<platform>/Dockerfile` (named `ringbuffer_<os>_test`) is the **authoritative environment** for the entire verification lifecycle. It MUST be equipped with all dependencies required to compile the main library, compile the test binaries, and execute the full test suite.

> **Ubuntu 24.04 Test Container Note:** clang++ is unsupported on Ubuntu (see `prompts/common/cpp/session_hints.md` Section 10). Use `g++` for all build and test operations. The Ubuntu test Dockerfile (`tests/containers/ubuntu/Dockerfile`) includes clang packages for reference but only g++ is used in practice.
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
- **Architecture**: Use `file -L` (with the `-L` flag to follow symlinks) on both `.a` and `.so` artifacts to verify the binary architecture. The `-L` flag is required because unversioned library names are symbolic links to versioned artifacts.
- **SONAME**: Use `readelf -d <so>` (or `readelf -d <versioned.so>`) to verify that the SONAME is set to `libswtr_ringbuffer.so`. When using unversioned symlinks, use `readelf -d -L` to follow the symlink.
- **Binary Size**: Use `size <artifact>` on Linux or `size -m <artifact>` on macOS to verify that dead code elimination has reduced the binary size. The `-m` flag (megabyte output) is a macOS/BSD extension not supported on Linux. The verification step MUST detect the host OS and use the appropriate flag:
  ```bash
  if [ "$(uname -s)" = "Darwin" ]; then size -m "$artifact"; else size "$artifact"; fi
  ```
- **Symbol Visibility**: Use `nm -gjU <artifact>` to verify that internal symbols are hidden and that the public API is strictly limited to the intended interface.
- **Universal Binary Check (macOS only)**: On macOS, verify whether the shared library is a universal binary using `lipo -info <dylib>`. If the compiler was `g++` (Homebrew GCC), expect an arm64-only binary — this is **acceptable** and must be flagged as INFO (not ERROR) in the regression report. See `prompts/common/cpp/build.md` → "Toolchain Limitations — g++ on macOS Apple Silicon" for details.

## Test Data Generation
After the test utility scripts are created, the following 7 test files MUST be generated in `tests/data/inputs/` (named `test001.txt` through `test007.txt`) using the pattern defined in the common testing patterns directory.

**Pattern Specification:**
The authoritative pattern specification is located at `prompts/common/testing/patterns/zigzag.md`. This file contains:
- The template string (48 characters)
- Line format constraints (prefix, payload, suffix, total length)
- The zig-zag space position algorithm
- Python reference implementation (ground truth for all shell variants)
- Validation regex: `^[0-9]{4} .{47} [0-9]{4}$`
- Test file line counts (T001=25, T002=50, T003=75, T004=100, T005=150, T006=200, T007=250)
- JUnit test matrix with expected exit codes

**Generation Tool Selection:**
The authoritative scripts are located in `prompts/common/cpp/utils/bin/`. They MUST be deployed to `tests/utils/bin/` during environment setup.
- **Linux (Fedora, Debian, etc.)**: Use the `tests/utils/bin/generate_test_data.sh` script.
- **Darwin/macOS**: Use the `tests/utils/bin/generate_test_data.zsh` script.

**Cross-Platform Consistency:**
The Python reference implementation in the pattern file is the ground truth. All shell script variants (Bash, Zsh, Tcsh, Bourne) MUST produce byte-identical output. The `create_scripts.md` prompt in `prompts/common/testing/` governs the creation and updating of these scripts.

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
  - **Exception**: Tcsh and POSIX Bourne shell lack native string manipulation capabilities. Scripts for these shells may use `expr` and `cut` as a necessary compromise — the built-ins-only rule cannot be met in pure Tcsh or POSIX sh. Scripts using these exceptions MUST include a comment noting this limitation.
- **Shell-Specific Idioms**: 
    - When implementing for **Zsh**, be mindful that string and array indexing is **1-based** by default.
    - Use shell-native string replacement or array assignment to modify specific characters in the template string.
    - Ensure regex patterns in `[[ ... ]]` are properly quoted to avoid expansion errors.
- **Script Portability Standard**:
  - **Shebang**: All utility scripts MUST use the `/usr/bin/env` wrapper for their shebang line to ensure portability across different shell installations (e.g., `#!/usr/bin/env zsh`, `#!/usr/bin/env bash`, `#!/usr/bin/env tcsh`, `#!/usr/bin/env sh`). Absolute paths to shells (e.g., `#!/bin/zsh`) MUST NOT be used.
  - **Utility Usage**: Avoid platform-specific flags for standard utilities. For example, when using `sed -i`, be aware that macOS (BSD) and Linux (GNU) have different syntax. Prefer using temporary files or standard redirection for modifications to ensure cross-platform compatibility.

## Test Utility Scripts
The following scripts must be provided to automate the generation of test data and report processing. These scripts are centrally managed in `prompts/common/cpp/utils/bin/` and MUST be copied/symlinked to `tests/utils/bin/` during setup:
- Zsh script: `tests/utils/bin/generate_test_data.zsh`
- Bash script: `tests/utils/bin/generate_test_data.sh`
- Tcsh script: `tests/utils/bin/generate_test_data.tcsh`
- Bourne shell script: `tests/utils/bin/generate_test_data_bin_sh.sh`
- JUnit XML Generator: `tests/utils/bin/generate_junit_report.sh`

**Execute Permission:** All utility scripts MUST be created with execute permission (`chmod +x`). Every script file placed in `tests/utils/bin/` must have the executable bit set before any test execution begins.

**JUnit Report Generation Requirements**:
The `generate_junit_report.sh` script must:
1. Parse the test results from companion `.exit` files (e.g., `T001.exit`) for pass/fail determination, and `.time` files (e.g., `T001.time`) for per-test execution time. Fall back to log file pattern matching (`grep -q "ERROR:"` / `grep -q "FAIL"`) if companion files are absent.
2. **Expected Exit Codes:** Maintain an authoritative mapping of expected exit codes per test ID (e.g., T005 expects exit code 1 for fatal error mode). Pass/fail determination MUST compare the actual exit code against the expected one — a test passes when `actual_exit_code == expected_exit_code`. Do NOT treat all non-zero exit codes as failures.
3. Capture the execution time for each test scenario from `.time` files, with millisecond precision.
4. Generate a `regression_report_junit.xml` in `tests/reports/` following the mandated JUnit XML structure, including per-test `<testcase time="...">` attributes and a `<system-out>` summary with total execution time.

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
- **Output Handling**: If an `output_file` is specified, the script MUST first truncate the file using `> "$output_file"`, then append generated lines using `>>`. The `exec >` form is discouraged because it redirects all stdout (including error messages) into the data file. This two-step pattern ensures that subsequent runs of the generator do not result in files with incorrect line counts and that error messages are never captured in data files.
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
    - `clean`: MUST remove the **contents** of the `bin/` directory using `$(RM) -r` (e.g., `bin/*`), while **preserving the directory itself**. It MUST NOT remove anything from `data/expected/` — those are golden reference files used for test verification. It MUST also remove all object files (`*.o`), all log files in `logs/` using `$(RM) -r`, and any backup files (`*~` and `#*#`) using `$(RM)`.
    - `dist-clean`: Must perform a full cleanup by calling the `clean` target and explicitly removing both the `logs/` and `reports/` directories using `$(RM) -r`.

## Test Makefile Requirements
The `tests/Makefile` is the authoritative orchestrator for the test suite:
- **`container` Target**: MUST build the `ringbuffer_<os>_test` image from the `Dockerfile` in `tests/containers/<os>/`.
- **Invalidation Logic**: The `container` target MUST rebuild the image if the `Dockerfile` OR `version.mk` has been modified since the image was created.
- **Container Staleness Check**: The `container` target's staleness comparison MUST reference the correct platform-specific Dockerfile path (e.g., `containers/debian/Dockerfile` for Debian, `containers/ubuntu/Dockerfile` for Ubuntu). A common mistake is copying the path from another platform — always verify the Dockerfile path matches `$(DOCKERFILE)`.
- **`verify` Target**: MUST orchestrate the Artifact Verification, the full Test Matrix execution (capturing execution time for each test), and the generation of both:
  - A JUnit XML report at `tests/reports/regression_report_junit.xml`
  - A Markdown regression report at `tests/reports/regression_report.md` containing the audit trail (compiler and linker versions from `g++ -v` and `ld -v`) and a test results table with pass/fail status, execution time (ms), and exit codes for each test scenario.
  - **Directory Pre-creation**: The `verify` target MUST create the `logs/` and `reports/` directories (via `mkdir -p`) **before** any file writes — including the audit trail section that captures compiler/linker versions to `reports/compiler_version.txt`. Failure to do so causes silent write failures.
- **Dependency**: The `verify` target MUST depend on the library and test binaries being current.
- **Shell Block Directives:** Inside multi-line shell blocks (lines joined with `\`), use plain `echo ""` — NOT `@echo ""`. The `@` prefix is a Make directive that only works at the top-level recipe line; inside shell blocks it is passed literally to the shell interpreter and causes `"@echo: not found"` errors. To produce blank lines inside shell blocks, use `echo ""` (without the `@` prefix).
- **No Comments in Shell Blocks:** Inside multi-line shell blocks (lines joined with `\`), do NOT use `#` comments. The Make recipe parser treats them as part of the shell command, which can cause syntax errors. Use `echo "# comment"` if a visible comment is needed in output.
- **Container Command Compatibility:** When using the `container` command (Apple Container on macOS), note these differences from Docker/Podman:
  - Use `container system status` to check service health (NOT `container info`, which does not exist).
  - Use `container image inspect <image>` to get image metadata (NOT `container inspect`, which is for containers).
  - Use `container image ls --quiet` to list images without headers.
  - The `--format` flag with Go template syntax (e.g., `{{.Created}}`) is NOT supported; parse JSON output instead.
  - Image inspection returns JSON with `creationDate` field in ISO format (e.g., `"2026-08-05T23:23:38Z"`).
- **Utility Deployment**: The `Makefile` MUST ensure that authoritative scripts from `prompts/common/cpp/utils/bin/` are copied or symlinked into `tests/utils/bin/` before any generation or verification steps are performed.
  - **Host-side deployment:** Script deployment MUST be performed on the host before container execution begins (e.g., as a pre-step in `create_testing.md` or the first action of `verify`).
  - **Container fallback:** If deployment is attempted from within a container and the source path does not exist, the Makefile MUST check whether scripts already exist in `tests/utils/bin/` and skip deployment with a non-fatal warning. If no scripts exist, it MUST report an error and STOP.

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
- **Implementation Note**: Use `std::make_unique<swtr::SwtrRingBuffer>` to instantiate the ring buffer. The `ErrorHandler` type is a **plain C function pointer** (`int (*)(size_t, swtr::BufferStatus)`), NOT a `std::function`. You MUST pass either:
  - A static/free function (e.g., `static int my_handler(...) { ... }`), or
  - A non-capturing lambda (e.g., `[](size_t, swtr::BufferStatus) -> int { ... }`)
  - **NEVER** use a capturing lambda (e.g., `[error_mode](...)`) — it cannot convert to a function pointer and will cause a compilation error.
  - The `TransformFn` type is `std::function<...>` and CAN accept capturing lambdas.

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
