# Build Requirements - Ringbuffer (macOS, C++)

## Toolchain Requirements
- **Compiler**: GNU Compiler Collection (GCC) or Clang.
- **Standard**: C++20 compliant.
- **Build System**: CMake (preferred) or GNU Make.

## Compilation Flags
To ensure maximum performance and the smallest possible binary footprint, the following flags must be used:

### Compiler Flags
- `-Wall -Wextra -Wpedantic`: Enable all common warnings to ensure code quality.
- `-O3`: Enable high-level optimizations.
- `-ffunction-sections`: Place each function in its own section in the object file.
- `-fdata-sections`: Place each data item in its own section in the object file.

### Linker Flags
- `--gc-sections`: (Linux/BSD/MacOS where supported) Remove unused sections (dead code elimination).
- `-Wl,--gc-sections`: Alternative syntax for passing the flag to the linker.

## Binary Optimization Goals
- **Dead Code Elimination**: The primary goal of using `-ffunction-sections` and `--gc-sections` is to allow the linker to identify and remove unreferenced functions, resulting in the smallest possible static binary.
- **Verifiability**: The resulting binary size should be monitored during testing to ensure that the dead code elimination is functioning as expected.

## Build Process
1. Configure the project using CMake or a Makefile.
2. Compile all source modules into object files.
3. Link the object files into a static and a shared library the libraries should be MacOS universal binaries.
4. Verify the binary size using `size` or `nm`.
