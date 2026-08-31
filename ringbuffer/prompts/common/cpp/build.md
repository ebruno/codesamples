# Build Requirements - Ringbuffer (Common C++)

**Implementation Directive:**
This build specification MUST be followed exactly to ensure binary symmetry across all platforms (macOS, Linux — debian, fedora, ubuntu, raspios). The source code is byte-identical across all platforms. Platform-specific deviations are permitted only for:
- Prerequisite package installation (Linux distro-specific)
- OS-detection macros in scripts
- Makefile linker flags (`-dead_strip` on macOS, `--gc-sections` on Linux)
- Container image names and paths (Linux only)

**Build Process Consistency Mandate:** The build process MUST be byte-identical across all platforms. The only permitted differences between platform Makefiles are:
- `CONTAINER_IMAGE` variable value (`ringbuffer_ubuntu_build`, `ringbuffer_debian_build`, etc., Linux only)
- Working directory path in container run commands (`src/ubuntu/cpp` vs `src/debian/cpp`, Linux only)
- Host distro detection check (`ubuntu` vs `debian`, Linux only)
- Linker flags: `-dead_strip` (macOS) vs `--gc-sections` (Linux)
- Universal binary creation: `lipo -create` on macOS, not needed on Linux

All other Makefile content — compiler flags, source file lists, build targets, artifact naming, optimization settings — MUST be byte-identical. When updating the Makefile for one platform, apply the same changes to all platforms.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/cpp/build.md`) conflict with common specs (`prompts/common/cpp/build.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

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
- If the target is macOS or FreeBSD, containers are NEVER used regardless of host OS.

## Toolchain Requirements
- **Shell Scripting Mandate**:
  - **Language Selection**:
    - For **macOS** targets: All scripts MUST be written in **Pure Zsh**.
    - For **Linux** targets (Debian, Fedora, Ubuntu, ArchLinux): All scripts MUST be written in **Pure Bash**.
    - For **Tcsh** scripts: All scripts MUST be written in **Pure Tcsh**.
  - **Minimum Version Requirements**:
    - **Zsh**: Version **5.8** or higher.
    - **Bash**: Version **5.0** or higher.
    - **Tcsh**: Version **6.22** or higher.
  - **Version Enforcement**: Every script MUST implement a version check at the beginning of the file. If the current shell version is below the minimum, the script must print a clear error message and exit with a non-zero status.
  - **Implementation Style**: MUST use shell built-ins (parameter expansion, arrays, redirection) for all data processing. Do NOT use platform-dependent external tools (`grep`, `sed`, `awk`, `cut`, `sort`, `find`) in Bash/Zsh scripts — their behavior differs between macOS (BSD) and Linux (GNU). Permitted utilities: `date`, `cat`, `mkdir -p`, `rm -rf`, `cp`, `mv`, `chmod` (guaranteed identical behavior across platforms).
  - **Shebang**: All utility scripts MUST use the `/usr/bin/env` wrapper for their shebang line (e.g., `#!/usr/bin/env bash`, `#!/usr/bin/env zsh`). Absolute paths to shells (e.g., `#!/bin/bash`) MUST NOT be used.
  - **Makefile recipes**: Makefile recipe lines execute under `/bin/sh -c`, which is a restricted POSIX shell. Bash/Zsh builtins like arrays, `<<<` (here-strings), and `[[ ]]` are NOT available. Makefile recipes may use external tools (`grep`, `sed`, `awk`) as needed since the shell is already POSIX sh. This exception does NOT apply to standalone shell scripts called from Makefiles.
- **Toolchain Configuration**:
  - The `Makefile` MUST configure `CXXFLAGS` and `LDFLAGS` based on the value of the `CXX` variable.
  - The only supported values for `CXX` are `g++` and `clang++`.
- **Required Tools**:
  - `g++` or `clang++` (Compiler/Linker — note: clang++ unsupported on Ubuntu due to C++ header mismatch)
  - `make` (Orchestrator)
  - `ar` (Archiver)
  - `nm` (Symbol Analysis)
  - `readelf` (Binary Analysis - Linux)
- **Standard**: C++20 compliant.
- **Build System**: GNU Make is the current implementation standard. CMake may be used for new projects, but all existing platforms use GNU Make and must continue to do so unless explicitly directed otherwise.
- **Binary Format**: ELF (Standard Linux Binary).

> **Ubuntu 24.04 Toolchain Note:** Ubuntu 24.04 ships `gcc-14-base` but only `g++-13` (C++ headers in `/usr/include/c++/13`). Clang 18 looks for headers in `/usr/include/c++/14`, causing `'atomic' file not found` errors. **clang++ is unsupported on Ubuntu.** Use `g++` as the compiler for all build and test operations. See [prompts/common/cpp/session_hints.md](session_hints.md) Section 10 for details.

## Compilation Flags
To ensure maximum performance and the smallest possible binary footprint, the following flags must be used:

### Compiler Flags
- `-fPIC`: Position Independent Code, required for shared library creation.
- `-Wall -Wextra -Wpedantic`: Enable all common warnings to ensure code quality.
- `-O3`: Enable high-level optimizations.
- `-flto`: Enable Link Time Optimization to optimize across the large number of small source modules while producing native object files compatible with both static and shared library linking across all platforms. Note: Linux g++ does not support `-flto=thin`; use `-flto` instead.
- `-fvisibility=hidden`: Hide all symbols by default to reduce the dynamic symbol table size and enable more aggressive stripping.
- `-ffunction-sections`: Place each function in its own section in the object file.
- `-fdata-sections`: Place each data item in its own section in the object file.

### Linker Flags
- `-Wl,--gc-sections`: Required for the Linux linker to remove unreferenced functions and data (dead code elimination).
- `-shared`: Used to create a shared object (`.so`).
- `-Wl,-soname,libswtr_ringbuffer.so`: Used to set the SONAME of the shared library for flexible loading.

## Output Artifacts
All built libraries must be placed in a subdirectory named `./lib`.

### Versioned Binaries
The libraries must be named using the version variables from `version.mk` in the format: `libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).{ext}`.

- **Static Library**:
    - **Target**: `./lib/libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).a`
    - **Requirement**: Must be built using the standard `ar` utility.
- **Shared Library**:
    - **Target**: `./lib/libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).{so|dylib}`

### Artifact Aliases (Symbolic Links)
To provide a consistent interface for consumers, the following symbolic links must be created in the `./lib` directory:
- `libswtr_ringbuffer.a` → points to the current versioned static library.
- `libswtr_ringbuffer.so` (or `.dylib` on macOS) → points to the current versioned shared library.
- **Requirement**: Symbolic links must be created using a relative path within the `./lib` directory (e.g., by changing the working directory to `lib` before creating the link) to ensure the links remain valid if the library folder is moved.

## Binary Optimization Goals
- **Dead Code Elimination**: The primary goal of using `-ffunction-sections`, `-fdata-sections`, and `--gc-sections` (combined with `-fvisibility=hidden` and `-flto`) is to allow the linker to identify and remove unreferenced functions, resulting in the smallest possible binary.
- **Verifiability**: The resulting binary size should be monitored during testing to ensure that the dead code elimination is functioning as expected.

## Project Documentation
The following files MUST be created in a subdirectory named `specs/` to document the implementation:
- `specs/build.md`: A copy of the build requirements used for this platform.
- `specs/testing_requirements.md`: A copy of the testing requirements used for this platform. Do NOT name this file `testing.md` — use `testing_requirements.md` to distinguish it from the testing prompt.
- `specs/artifacts.md`: A file documenting the discovery and location of all project artifacts.

## Required Makefile Targets
If using GNU Make, the following targets MUST be implemented:
- `all`: Build both static and shared libraries.
- `static`: Build the versioned static library and create the unversioned symbolic link.
- `shared`: Build the versioned shared library and create the unversioned symbolic link.
- `clean`: MUST remove the `build/` and `./lib/` directories, all object files (`*.o`) using a wildcard, and all backup files (`*~`, `#*#`).
- `dist-clean`: Perform a full reset by calling `clean`, removing the `../reports` directory (the platform-level reports folder), the `cpp/logs` directory, any platform-specific environment cleanup (e.g., `container-clean`), and MUST execute `make -C tests dist-clean`.

## Temporary Workspace
- **Centralized Storage**: All temporary files, utility scripts, or intermediate data generated during the execution of this prompt MUST be placed in a directory named `tmp`.
- **Isolation**: Do NOT create temporary files (e.g., `.py`, `.txt`, `.sh` scripts used for auditing or listing) in the project root, source directories, or any other permanent project location.

## Build Process
1. **Versioning**: The build system MUST explicitly source `version.mk` to resolve versioning variables before generating artifact names.
2. **Configuration**: Configure the project using CMake or a Makefile, ensuring the include path (`-I.`) is correctly set.
3. **Compilation**: Compile all source modules into position-independent object files. This step should be performed in parallel (e.g., using `make -j$(nproc)`) to handle the high volume of small source modules.
4. **Linking — Static Library**: Link the object files into a static library using `ar`.
5. **Linking — Shared Library**: Link the object files into a shared object (`.so`) using the `-shared` flag and appropriate `-Wl,-soname` setting.
6. **Deployment**: Place the output artifacts in the `./lib` directory. Create symbolic links from the unversioned names to the versioned artifacts using relative paths.
7. **Verification**: 
    - Verify the binary architecture using `file -L` (with the `-L` flag to follow symlinks) on both `.a` and `.so`. The `-L` flag is required because unversioned library names are symbolic links to versioned artifacts.
    - Verify the shared library SONAME using `readelf -d <so>` (must contain `SONAME [libswtr_ringbuffer.so]`).
    - Verify the final binary size using `size <artifact>` on both platforms (Linux and macOS). The output format may differ slightly between implementations; parse the total column. For a consistent breakdown, use: `size <artifact> | tail -1 | awk '{print "Binary size: "$1+$2+$3" bytes (text="$1", data="$2", bss="$3")"}'`.
8. **Cleanup**: Use the `$(RM)` macro for file cleanup. The `-f` flag must not be explicitly specified as it is already included in the `$(RM)` macro definition. The clean target must remove both the `build/` and `./lib/` directories, as well as any backup files (`*~` and `#*#`) using `$(RM)`.

## Toolchain Limitations — g++ on macOS Apple Silicon
**IMPORTANT:** When building with `CXX=g++` (Homebrew GCC) on macOS Apple Silicon, the compiler does **not** support the `-arch x86_64` flag. This means:
- The static library (`.a`) will contain only arm64 object files.
- The shared library (`.dylib`) will be **arm64-only** — no universal binary.
- The Makefile detects this and emits a `WARNING:` message during the build, then falls back to arm64-only.

**This is acceptable and expected behavior.** The limitation exists because Homebrew GCC on Apple Silicon does not ship with an x86_64 target. It is **not** a build failure.

**Report Flagging Requirement:** When `CXX=g++` is used on macOS, the build log and regression report MUST include an INFO or WARNING entry documenting:
- The compiler used (`g++` / Homebrew GCC)
- That universal binary (arm64 + x86_64) was not produced
- The reason (Homebrew GCC does not support `-arch x86_64` on Apple Silicon)
- That this is acceptable behavior and not a build failure

For production builds requiring universal binaries, use `clang++` (the default).



- All code is covered under a BSD 3-Clause License.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

## Scope Boundary — Build Phase Only
The purpose of this prompt is to compile the library and produce artifacts in `./lib/`. **Your task ends once both `libswtr_ringbuffer.a` and `libswtr_ringbuffer.so` (or `.dylib`) exist with correct symlinks.**

You MUST NOT:
- Run `make verify` or `make -C tests`
- Generate test data, compile test binaries, or execute any tests
- Invoke `regression_test_execution.md` or any testing workflow
- Proceed to verification, reporting, or test matrix execution

**Directory Scope Restriction:**
- **NEVER create, modify, or delete any files inside the `tests/` directory.** This includes:
  - Test source code (`tests/src/`)
  - Test data files (`tests/data/inputs/`, `tests/data/expected/`)
  - Test utility scripts (`tests/utils/bin/`)
  - Test container configurations (`tests/containers/`)
  - Test Makefiles, logs, or reports
- If the `tests/` directory is missing required files (e.g., `verify_test_data.sh`, test data, logs/reports directories), **report this as a finding and STOP**. Do not create or fix them.
- The `tests/` directory is managed exclusively by testing-related prompts (e.g., `create_testing.md`, `update_testing.md`). Build-only prompts must treat it as read-only.

**Excluded Platforms:**
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development.
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/`.
- The only files that should exist in these directories are zero-length `build.md`, `functional.md`, and `testing.md` files.
- If these directories contain any non-zero files, remove them.

If the user wants testing, they will issue a separate request (e.g., "run tests" or "verify the build"). Do not assume testing is part of a build request.
<EOF>
