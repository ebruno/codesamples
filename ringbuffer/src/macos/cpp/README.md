# Ringbuffer (macOS, C++)

## Overview
The Ringbuffer is a high-performance, fixed-size, first-in-first-out (FIFO) data structure implemented in C++20 for macOS. It connects its memory end-to-end in a loop using a read pointer and a write pointer that wrap around the array.

### Key Architecture
- **Pipeline Model**: Implements a three-stage pipeline (Read -> Transform -> Write) running in separate threads using `std::jthread`.
- **Synchronization**: Utilizes cooperative cancellation and advanced synchronization primitives to ensure thread safety and responsiveness.
- **Memory Efficiency**: Employs `alignas(64)` on buffer slots and index counters to prevent false sharing between threads.
- **Performance**: Optimized for small binary footprints using Link Time Optimization (LTO) and dead code elimination (`-ffunction-sections`, `-fdata-sections`, `-dead_strip`).

## Functional Requirements
- **C++ Standard**: C++20 compliant.
- **Threading**: Uses `std::jthread` and `std::stop_token` for graceful shutdown and resource release.
- **I/O**: Uses POSIX file descriptors for reading and writing.
- **Transformations**: Supports customizable transformation operations via `std::function`.
- **Checksums**: Supports multiple checksum algorithms (MD5, SHA256, SHA512, NONE).
- **Logging**: Implements a thread-safe, level-based logging system with independent control for each pipeline stage.

## Build Instructions
The project is designed to produce macOS Universal Binaries (Fat Binaries) supporting both `arm64` (Apple Silicon) and `x86_64` (Intel).

### Toolchain
- **Compilers**: GCC or Clang.
- **Build System**: Makefile (provided).

### Artifacts
Built libraries are located in the `lib/` directory:
- **Static Library**: `libswtr_ringbuffer.a`
- **Shared Library**: `libswtr_ringbuffer.dylib` (Install name: `@rpath/libswtr_ringbuffer.dylib`)

### Build Process
1. Run `make` to compile all modules for both architectures.
2. The build system handles the two-stage linking process for the shared library using `lipo` to ensure a valid universal binary.
3. Use `make clean` to remove build artifacts and the `lib/` directory.

## Licensing
All code is covered under a BSD 3-Clause License. A full copy of the license can be found in the `LICENSE` file.
