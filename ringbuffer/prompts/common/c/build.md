# Build Requirements — Ringbuffer (C)

**Implementation Directive:**
This build specification MUST be followed exactly to ensure consistency across platforms. Platform-specific deviations are permitted only for toolchain configuration, binary format, and build flags as documented in per-OS override files.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/c/build.md`) conflict with common specs (`prompts/common/c/build.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

## Language Standards
- **Primary Version**: C23 (ISO/IEC 9899:2024)
- **Fallback Versions** (in priority order): C17 (ISO/IEC 9899:2018), C11 (ISO/IEC 9899:2011)
- **Minimum Supported**: C11 — all implementations MUST be compatible with this version
- **Encoding**: UTF-8

## Build System: GNU Make
All C builds MUST use GNU Make as the build system. The project root for each platform MUST contain a `Makefile` and `version.mk`.

### Makefile Configuration
- **Compiler**: `gcc` or `clang` (platform-specific default)
- **Standard**: `-std=c23` (primary), fallback to `-std=c17` or `-std=c11` if C23 is not supported
- **Position Independent Code**: `-fPIC` (required for shared library creation)

### Required Tools
- `gcc` or `clang` (Compiler/Linker)
- `make` (Build orchestrator)
- `ar` (Static library archiver)
- `nm` (Symbol inspection)
- `readelf` (Binary analysis — Linux only)
- `otool` (Mach-O binary analysis — macOS only)
- `lipo` (Universal binary inspection — macOS only)

### Compilation Flags
To ensure maximum performance and the smallest possible binary footprint, the following flags must be used:

#### Compiler Flags
- `-fPIC`: Position Independent Code, required for shared library creation.
- `-Wall -Wextra -Wpedantic`: Enable all common warnings to ensure code quality.
- `-O3`: Enable high-level optimizations.
- `-flto`: Enable Link Time Optimization to optimize across modules.
- `-fvisibility=hidden`: Hide all symbols by default to reduce the dynamic symbol table size.
- `-ffunction-sections`: Place each function in its own section in the object file.
- `-fdata-sections`: Place each data item in its own section in the object file.

#### Linker Flags
- **Linux**: `-Wl,--gc-sections` (dead code elimination), `-shared`, `-Wl,-soname,libswtr_ringbuffer.so`
- **macOS**: `-dead_strip` (dead code elimination), `-dynamiclib`, install name `@rpath/libswtr_ringbuffer.dylib`

### Output Artifacts
All built libraries must be placed in a subdirectory named `./lib`.

#### Versioned Binaries
The libraries must be named using the version variables from `version.mk` in the format: `libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).{ext}`.

- **Static Library**:
    - **Target**: `./lib/libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).a`
    - **Requirement**: Must be built using the standard `ar` utility.
- **Shared Library**:
    - **Target**: `./lib/libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).{so|dylib}`

#### Artifact Aliases (Symbolic Links)
To provide a consistent interface for consumers, the following symbolic links must be created in the `./lib` directory:
- `libswtr_ringbuffer.a` → points to the current versioned static library.
- `libswtr_ringbuffer.so` (or `.dylib` on macOS) → points to the current versioned shared library.
- **Requirement**: Symbolic links must be created using a relative path within the `./lib` directory.

### Binary Optimization Goals
- **Dead Code Elimination**: The primary goal of using `-ffunction-sections`, `-fdata-sections`, and `--gc-sections` (combined with `-fvisibility=hidden` and `-flto`) is to allow the linker to identify and remove unreferenced functions, resulting in the smallest possible binary.
- **Verifiability**: The resulting binary size should be monitored during testing to ensure that the dead code elimination is functioning as expected.

### Required Makefile Targets
The following targets MUST be implemented:

| Target | Description |
|--------|-------------|
| `all` | Build both static and shared libraries. |
| `static` | Build the versioned static library and create the unversioned symbolic link. |
| `shared` | Build the versioned shared library and create the unversioned symbolic link. |
| `clean` | MUST remove the `build/` and `./lib/` directories, all object files (`*.o`) using a wildcard, and all backup files (`*~`, `#*#`). |
| `dist-clean` | Perform a full reset by calling `clean`, removing the `../reports` directory, the `c/logs` directory, and MUST execute `make -C tests dist-clean`. |

### Build Process
1. **Versioning**: The build system MUST explicitly source `version.mk` to resolve versioning variables before generating artifact names.
2. **Configuration**: Configure the project using a Makefile, ensuring the include path (`-I.`) is correctly set.
3. **Compilation**: Compile all source modules into position-independent object files. This step should be performed in parallel (e.g., using `make -j$(nproc)`) to handle the high volume of small source modules.
4. **Linking — Static Library**: Link the object files into a static library using `ar`.
5. **Linking — Shared Library**: Link the object files into a shared object (`.so` on Linux, `.dylib` on macOS) using the appropriate flags.
6. **Deployment**: Place the output artifacts in the `./lib` directory. Create symbolic links from the unversioned names to the versioned artifacts using relative paths.
7. **Verification**: 
    - Verify the binary architecture using `file -L` (with the `-L` flag to follow symlinks) on both `.a` and `.so`/`.dylib`.
    - Verify the shared library SONAME using `readelf -d <so>` (Linux, must contain `SONAME [libswtr_ringbuffer.so]`) or `otool -L <dylib>` (macOS, must contain `@rpath/libswtr_ringbuffer.dylib`).
    - Verify the final binary size using `size <artifact>` on both platforms.

### Platform-Specific Build Considerations

#### macOS
- **Universal Binaries**: macOS builds MUST produce fat binaries with both `arm64` and `x86_64` slices.
  ```bash
  # Compile for both architectures
  CFLAGS="-arch arm64 -arch x86_64 ..."
  # Verify with lipo
  lipo -info lib/libswtr_ringbuffer.dylib   # Should show both architectures
  ```
- **Linker Flags**: Use `-dead_strip` instead of `--gc-sections`.
- **Install Name**: Must use `@rpath/libswtr_ringbuffer.dylib` (not absolute paths).
- **No Containers**: macOS builds run natively on the host. No container support.

#### Linux (Fedora, Debian, Ubuntu)
- **ELF Format**: Shared libraries use `.so` extension.
- **SONAME**: Must be `libswtr_ringbuffer.so` (not versioned).
- **RPATH**: Use `-Wl,-rpath,$ORIGIN/../lib` for test binaries.
- **Container Support**: Builds may run in containers when the host OS does not match the target OS.

### Temporary Workspace
- **Centralized Storage**: All temporary files, utility scripts, or intermediate data generated during the execution of this prompt MUST be placed in a directory named `tmp`.
- **Isolation**: Do NOT create temporary files (e.g., `.py`, `.txt`, `.sh` scripts used for auditing or listing) in the project root, source directories, or any other permanent project location.

### Build Process Logging
- Create a directory at `src/<os>/c/logs/`.
- Log build actions to `build.log` in the format: `[YYYY-MM-DD HH:MM:SS +/-HHMM] <Action Description>`.
- Append to existing log files; do NOT overwrite.

### Scope Boundary — Build Phase Only
The purpose of this prompt is to compile the library and produce artifacts in `./lib/`. **Your task ends once both `libswtr_ringbuffer.a` and `libswtr_ringbuffer.so` (or `.dylib`) exist with correct symlinks.**

You MUST NOT:
- Run `make verify` or `make -C tests`
- Generate test data, compile test binaries, or execute any tests
- Invoke `create_regression.md` or any testing workflow
- Proceed to verification, reporting, or test matrix execution

**Directory Scope Restriction:**
- **NEVER create, modify, or delete any files inside the `tests/` directory.** This includes:
  - Test source code (`tests/src/`)
  - Test data files (`tests/data/inputs/`, `tests/data/expected/`)
  - Test utility scripts (`tests/utils/bin/`)
  - Test container configurations (`tests/containers/`)
  - Test Makefiles, logs, or reports
- If the `tests/` directory is missing required files (e.g., test data, logs/reports directories), **report this as a finding and STOP**. Do not create or fix them.
- The `tests/` directory is managed exclusively by testing-related prompts (e.g., `create_testing.md`, `update_testing.md`). Build-only prompts must treat it as read-only.

### Excluded Platforms
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development.
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/`.
- The only files that should exist in these directories are zero-length `build.md`, `functional.md`, and `testing.md` files.
- If these directories contain any non-zero files, remove them.

If the user wants testing, they will issue a separate request (e.g., "run tests" or "verify the build"). Do not assume testing is part of a build request.

### Version Reporting
The build process MUST detect and report the actual C compiler version in use:
- At the start of `build.log`: `[timestamp] Compiler=<compiler_name> Version=<detected_version>`
- If the primary version (C23) is not supported, detect the highest fallback version that IS supported and report it.
- If the detected compiler does not support at least C11, STOP and report: `ERROR: Detected <compiler> version does not support C11. Cannot proceed.`

Example log entries:
```
[2026-08-14 10:30:00 -0700] Compiler=clang Version=Apple clang 18.1.8 (target: arm64-apple-darwin25.5.0)
[2026-08-14 10:30:00 -0700] C Standard=c23 (primary target)
[2026-08-14 10:30:01 -0700] Build started for target macos
```
