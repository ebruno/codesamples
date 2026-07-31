# Build Requirements - Ringbuffer (macOS, C++)

## Toolchain Requirements
- **Compiler**: GNU Compiler Collection (GCC) or Clang.
- **Standard**: C++20 compliant.
- **Build System**: CMake (preferred) or GNU Make.
- **Binary Format**: macOS Universal Binaries (Fat Binaries) supporting both `arm64` (Apple Silicon) and `x86_64` (Intel).

## Compilation Flags
To ensure maximum performance and the smallest possible binary footprint, the following flags must be used:

### Compiler Flags
- `-arch arm64 -arch x86_64`: Required to produce universal binaries.
- `-fPIC`: Position Independent Code, required for shared library creation.
- `-Wall -Wextra -Wpedantic`: Enable all common warnings to ensure code quality.
- `-O3`: Enable high-level optimizations.
- `-ffunction-sections`: Place each function in its own section in the object file.
- `-fdata-sections`: Place each data item in its own section in the object file.

### Linker Flags
- `--gc-sections`: (Linux/BSD/MacOS where supported) Remove unused sections (dead code elimination).
- `-dynamiclib`: Used specifically for the shared library target to create a `.dylib`.

## Output Artifacts
All built libraries must be placed in a subdirectory named `lib`.

### Versioned Binaries
The libraries must be named using the version variables from `version.mk` in the format: `libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).{ext}`.

- **Static Library**:
    - **Target**: `lib/libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).a`
    - **Requirement**: Must be built using `libtool -static` instead of `ar`.
- **Shared Library**:
    - **Target**: `lib/libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).dylib`

### Artifact Aliases (Symbolic Links)
To provide a consistent interface for consumers, the following symbolic links must be created in the `lib` directory:
- `libswtr_ringbuffer.a` $\rightarrow$ points to the current versioned static library.
- `libswtr_ringbuffer.dylib` $\rightarrow$ points to the current versioned shared library.
- **Requirement**: Symbolic links must be created using a relative path within the `lib` directory (e.g., by changing the working directory to `lib` before creating the link) to ensure the links remain valid if the library folder is moved.

## Binary Optimization Goals
- **Dead Code Elimination**: The primary goal of using `-ffunction-sections` and `--gc-sections` is to allow the linker to identify and remove unreferenced functions, resulting in the smallest possible static binary.
- **Verifiability**: The resulting binary size should be monitored during testing to ensure that the dead code elimination is functioning as expected.

## Build Process
1. Configure the project using CMake or a Makefile.
2. Compile all source modules into position-independent object files.
3. Link the object files into both a static library (`.a`) and a shared library (`.dylib`).
4. Place the output artifacts in the `lib` directory.
5. Verify the universal binary architecture using the `lipo -info` command.
6. **Cleanup**: Use the `$(RM)` macro for file cleanup. The `-f` flag must not be explicitly specified as it is already included in the `$(RM)` macro definition.
