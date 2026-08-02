This file was generated on: 2026-Aug-02 01:24:03 by Llama-3.1-70B-Instruct (Q8_0), System Prompt v1.0
# Build Requirements - Ringbuffer (macOS, C++)

## Toolchain Requirements
- **Compiler**: GNU Compiler Collection (GCC) or Clang.
- **Standard**: C++20 compliant.
- **Build System**: CMake (preferred) or GNU Make.
- **Binary Format**: macOS Universal Binaries (Fat Binaries) supporting both `arm64` (Apple Silicon) and `x86_64` (Intel).

## Compilation Flags
To ensure maximum performance and the smallest possible binary footprint, the following flags must be used:

### Compiler Flags
- `-arch arm64` and `-arch x86_64`: Each source file must be compiled separately for each architecture, producing single-architecture object files (e.g., `file.arm64.o` and `file.x86_64.o`). Do NOT pass both `-arch` flags in a single compiler invocation.
- `-fPIC`: Position Independent Code, required for shared library creation.
- `-Wall -Wextra -Wpedantic`: Enable all common warnings to ensure code quality.
- `-O3`: Enable high-level optimizations.
- `-flto`: Enable Link Time Optimization to optimize across the large number of small source modules.
- `-fvisibility=hidden`: Hide all symbols by default to reduce the dynamic symbol table size and enable more aggressive stripping.
- `-ffunction-sections`: Place each function in its own section in the object file.
- `-fdata-sections`: Place each data item in its own section in the object file.

### Linker Flags
- `-dead_strip`: Required for the macOS linker to remove unreferenced functions and data (dead code elimination).
- `-dynamiclib`: Used specifically for the shared library target to create a `.dylib`.
- `-install_name`: Used to set the install name of the shared library. For this project, it must be set to `@rpath/libswtr_ringbuffer.dylib` to enable flexible loading via RPATH.

## Output Artifacts
All built libraries must be placed in a subdirectory named `lib`.

### Versioned Binaries
The libraries must be named using the version variables from `version.mk` in the format: `libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).{ext}`.

- **Static Library**:
    - **Target**: `lib/libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).a`
    - **Requirement**: Must be built using `libtool -static` instead of `ar`. `libtool -static` accepts single-architecture `.o` files for both architectures in a single invocation and produces a fat static library automatically.
- **Shared Library**:
    - **Target**: `lib/libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).dylib`

### Artifact Aliases (Symbolic Links)
To provide a consistent interface for consumers, the following symbolic links must be created in the `lib` directory:
- `libswtr_ringbuffer.a` → points to the current versioned static library.
- `libswtr_ringbuffer.dylib` → points to the current versioned shared library.
- **Requirement**: Symbolic links must be created using a relative path within the `lib` directory (e.g., by changing the working directory to `lib` before creating the link) to ensure the links remain valid if the library folder is moved.

## Binary Optimization Goals
- **Dead Code Elimination**: The primary goal of using `-ffunction-sections`, `-fdata-sections`, and `-dead_strip` (combined with `-fvisibility=hidden` and `-flto`) is to allow the linker to identify and remove unreferenced functions, resulting in the smallest possible binary.
- **Verifiability**: The resulting binary size should be monitored during testing to ensure that the dead code elimination is functioning as expected.

## Build Process
1. **Versioning**: The build system MUST explicitly source `version.mk` to resolve versioning variables before generating artifact names.
2. **Configuration**: Configure the project using CMake or a Makefile, ensuring the include path (`-I.`) is correctly set.
3. **Compilation**: Compile all source modules into position-independent object files. Each source file must be compiled twice — once with `-arch arm64` and once with `-arch x86_64` — producing separate single-architecture `.o` files (e.g., `build/obj/ReadOps.arm64.o` and `build/obj/ReadOps.x86_64.o`). This step should be performed in parallel (e.g., using `make -j$(sysctl -n hw.ncpu)`) to handle the high volume of small source modules.
4. **Linking — Static Library**: Link the object files into a static library using `libtool -static`. Both architecture variants of all `.o` files are passed to a single `libtool -static` invocation. `libtool` handles single-architecture `.o` files correctly and produces a fat `.a` containing both `arm64` and `x86_64`.
5. **Linking — Shared Library**: The shared library MUST be built using a **two-stage process**:
    - **Stage 1 — Single-Architecture Links**: Link all `arm64` object files into a single-architecture `.dylib` using `-arch arm64 -dynamiclib`. Separately, link all `x86_64` object files into a single-architecture `.dylib` using `-arch x86_64 -dynamiclib`. Each link invocation uses only ONE `-arch` flag matching the architecture of its input `.o` files. These intermediate `.dylib` files are placed in the build directory (e.g., `build/obj/`), NOT in `lib/`.
    - **Stage 2 — Combine with lipo**: Use `lipo -create` to combine the two single-architecture `.dylib` files into one fat universal `.dylib` placed in the `lib/` directory.
    - **Rationale**: Passing both `-arch arm64 -arch x86_64` to a single linker invocation requires each input `.o` file to itself be a fat binary containing both architectures. Since the compilation step produces single-architecture `.o` files, the linker will reject them with "found architecture 'x86_64', required architecture 'arm64'" errors. The two-stage lipo approach avoids this by keeping each link step single-architecture.
6. **Deployment**: Place the output artifacts in the `lib` directory. Create symbolic links from the unversioned names to the versioned artifacts using relative paths.
7. **Verification**: 
    - Verify the universal binary architecture using the `lipo -info` command on both the `.a` and `.dylib`.
    - Verify the shared library install name using `otool -L` (must be `@rpath/libswtr_ringbuffer.dylib`).
    - Verify the final binary size using `size -m`.
8. **Cleanup**: Use the `$(RM)` macro for file cleanup. The `-f` flag must not be explicitly specified as it is already included in the `$(RM)` macro definition. The clean target must remove both the `build/` and `lib/` directories, as well as any backup files (`*~` and `#*#`) using `$(RM)`.

- All code is covered under a BSD 3-Clause License.
