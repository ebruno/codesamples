# Build Requirements - Ringbuffer (macOS, C++)

**Implementation Directive:**
This build specification MUST follow the common build specification exactly to ensure binary symmetry across platforms. Platform-specific deviations are permitted only for toolchain specifics and binary format requirements.

Refer to the following document for all shared requirements, flags, and process:
[ringbuffer/prompts/common/cpp/build.md](../../common/cpp/build.md)

**Platform Specifics:**
- **Target Environment**: macOS (Apple Silicon and Intel).
- **Compiler**: Clang (Default).
- **Binary Format**: macOS Universal Binaries (Fat Binaries) supporting both `arm64` (Apple Silicon) and `x86_64` (Intel).

## Required Tools
- `clang++` (Compiler/Linker)
- `make` (Orchestrator)
- `ar` (Archiver)
- `otool` (Binary Analysis)
- `nm` (Symbol Analysis)
- `lipo` (Universal Binary Management)

## macOS Binary Requirements
To ensure the library is universal, the following specific process MUST be used:

### Compilation
- Each source file must be compiled separately for each architecture using `-arch arm64` and `-arch x86_64`, producing single-architecture object files (e.g., `file.arm64.o` and `file.x86_64.o`).
- Do NOT pass both `-arch` flags in a single compiler invocation.

### Linking
- **Static Library**: 
    - Use `libtool -static` to combine single-architecture `.o` files into a fat static library.
    - **Target**: `./lib/libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).a`
- **Shared Library (Two-Stage Process)**:
    1. Link `arm64` objects into a single-architecture `.dylib` using `-arch arm64 -dynamiclib`.
    2. Link `x86_64` objects into a single-architecture `.dylib` using `-arch x86_64 -dynamiclib`.
    3. Use `lipo -create` to combine the two into the final fat versioned `.dylib`: `./lib/libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).dylib`.
- **Install Name**: The shared library MUST be linked with `-install_name @rpath/libswtr_ringbuffer.dylib`.

### Artifact Aliases (Symbolic Links)
To provide a consistent interface for consumers, the following symbolic links must be created in the `./lib` directory:
- `libswtr_ringbuffer.a` → points to the current versioned static library.
- `libswtr_ringbuffer.dylib` → points to the current versioned shared library.

## Host-Target Compatibility
macOS builds are native-only. The host OS MUST be macOS; no containerized cross-compilation is supported.
- **Host Detection**: Verify the host OS using `sw_vers --productName` (must return "macOS").
- **Container Prohibition**: The Makefile MUST NOT define a `container`, `container-clean`, or any container-related target. If an agent encounters a prompt requesting cross-compilation from macOS to Linux, it MUST refuse and require the build to run on a native Linux host or inside a Linux container managed externally.
- **Docker Prohibition**: Docker (`docker`) MUST NOT be used on macOS under any circumstances. The `container` command is the only supported container runtime for macOS, and even that is prohibited — macOS builds must run natively.

## Required Makefile Targets
- `dist-clean`: Must perform a full reset by calling `clean` and removing the `../reports` and `logs` directories.

### Linker Flags
- Use `-dead_strip` for dead code elimination (macOS equivalent of `--gc-sections`).

## Verification
- **Architecture**: Verify the universal binary architecture using `lipo -info`.
- **Install Name**: Verify the shared library install name using `otool -L`.
- **Binary Size**: Use `size -m` to verify dead code elimination.

- All code is covered under a BSD 3-Clause License.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
