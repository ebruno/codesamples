# Build Requirements - Ringbuffer (Common C++)

**Implementation Directive:**
This build specification MUST be followed exactly to ensure binary symmetry across platforms. Platform-specific deviations are permitted only for prerequisite package installation.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/cpp/build.md`) conflict with common specs (`prompts/common/cpp/build.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

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
  - **Implementation Style**: Prefer shell built-ins (parameter expansion, arrays) over external tools (sed, awk, cut) to ensure maximum portability and performance.
- **Toolchain Configuration**:
  - The `Makefile` MUST configure `CXXFLAGS` and `LDFLAGS` based on the value of the `CXX` variable.
  - The only supported values for `CXX` are `g++` and `clang++`.
- **Required Tools**:
  - `g++` or `clang++` (Compiler/Linker)
  - `make` (Orchestrator)
  - `ar` (Archiver)
  - `nm` (Symbol Analysis)
  - `readelf` (Binary Analysis - Linux)
- **Standard**: C++20 compliant.
- **Build System**: GNU Make is the current implementation standard. CMake may be used for new projects, but all existing platforms use GNU Make and must continue to do so unless explicitly directed otherwise.
- **Binary Format**: ELF (Standard Linux Binary).

## Compilation Flags
To ensure maximum performance and the smallest possible binary footprint, the following flags must be used:

### Compiler Flags
- `-fPIC`: Position Independent Code, required for shared library creation.
- `-Wall -Wextra -Wpedantic`: Enable all common warnings to ensure code quality.
- `-O3`: Enable high-level optimizations.
- `-flto`: Enable Link Time Optimization to optimize across the large number of small source modules.
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
- `specs/testing.md`: A copy of the testing requirements used for this platform.
- `specs/artifacts.md`: A file documenting the discovery and location of all project artifacts.

## Required Makefile Targets
If using GNU Make, the following targets MUST be implemented:
- `all`: Build both static and shared libraries.
- `static`: Build the versioned static library and create the unversioned symbolic link.
- `shared`: Build the versioned shared library and create the unversioned symbolic link.
- `clean`: MUST remove the `build/` and `./lib/` directories, all object files (`*.o`) using a wildcard, and all backup files (`*~`, `#*#`).
- `dist-clean`: Perform a full reset by calling `clean`, removing the `../reports` directory (the platform-level reports folder), the `cpp/logs` directory, any platform-specific environment cleanup (e.g., `container-clean`), and MUST execute `make -C tests dist-clean`.

## Temporary Workspace
- **Centralized Storage**: All temporary files, utility scripts, or intermediate data generated during the execution of this prompt MUST be placed in a directory named `ringbuffer/tmp`.
- **Isolation**: Do NOT create temporary files (e.g., `.py`, `.txt`, `.sh` scripts used for auditing or listing) in the project root, source directories, or any other permanent project location.

## Build Process
1. **Versioning**: The build system MUST explicitly source `version.mk` to resolve versioning variables before generating artifact names.
2. **Configuration**: Configure the project using CMake or a Makefile, ensuring the include path (`-I.`) is correctly set.
3. **Compilation**: Compile all source modules into position-independent object files. This step should be performed in parallel (e.g., using `make -j$(nproc)`) to handle the high volume of small source modules.
4. **Linking — Static Library**: Link the object files into a static library using `ar`.
5. **Linking — Shared Library**: Link the object files into a shared object (`.so`) using the `-shared` flag and appropriate `-Wl,-soname` setting.
6. **Deployment**: Place the output artifacts in the `./lib` directory. Create symbolic links from the unversioned names to the versioned artifacts using relative paths.
7. **Verification**: 
    - Verify the binary architecture using the `file` command on both the `.a` and `.so`.
    - Verify the shared library SONAME using `readelf -d <so>` (must contain `SONAME [libswtr_ringbuffer.so]`).
    - Verify the final binary size using `size -m`.
8. **Cleanup**: Use the `$(RM)` macro for file cleanup. The `-f` flag must not be explicitly specified as it is already included in the `$(RM)` macro definition. The clean target must remove both the `build/` and `./lib/` directories, as well as any backup files (`*~` and `#*#`) using `$(RM)`.



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

If the user wants testing, they will issue a separate request (e.g., "run tests" or "verify the build"). Do not assume testing is part of a build request.
<EOF>
