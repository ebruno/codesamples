# Ringbuffer (macOS, C++)

The `swtr_ringbuffer` is a high-performance, fixed-size, first-in-first-out (FIFO) ring buffer library implemented in C++20 for macOS. It is designed as a three-stage pipeline (Read -> Transform -> Write) running in separate threads, ensuring efficient data processing with a minimal binary footprint.

## Key Features

- **Three-Stage Pipeline**: Dedicated threads for reading from a source, transforming the data, and writing to a destination.
- **C++20 Powered**: Utilizes `std::jthread` for managed threading, cooperative cancellation via `std::stop_token`, and advanced synchronization.
- **Memory Efficient**: Pre-allocated fixed array with cache-line alignment (`alignas(64)`) to prevent false sharing between threads.
- **Robust EOF Handling**: Graceful shutdown sequence that propagates an EOF marker through the pipeline:
    1. **Reader**: Detects EOF $\rightarrow$ marks buffer as `LAST_BUFFER_TO_TRANSFORM` $\rightarrow$ terminates.
    2. **Transformer**: Processes `LAST_BUFFER_TO_TRANSFORM` $\rightarrow$ marks as `LAST_BUFFER_TO_WRITE` $\rightarrow$ terminates.
    3. **Writer**: Processes `LAST_BUFFER_TO_WRITE` $\rightarrow$ writes data $\rightarrow$ terminates.
- **Flexible Transformation**: Accepts a `std::function` to define the transformation operation. If no function is provided, the data passes through unchanged.
- **Comprehensive Logging**: Implements a Non-Virtual Public Interface (NVI) logging system with:
    - Multiple log levels (`Trace`, `Debug`, `Info`, `Warning`, `Error`, `Critical`).
    - Independent enable/disable flags and verbosity settings for Read, Transform, and Write stages.
    - Customizable output stream (default is `std::cerr`).
- **Binary Optimization**: Optimized for small binaries using dead code elimination (`-ffunction-sections`, `-fdata-sections`, and `--gc-sections`).

## Build Instructions

The library is designed to produce macOS Universal Binaries (supporting both `arm64` Apple Silicon and `x86_64` Intel).

### Requirements
- **Compiler**: GNU Compiler Collection (GCC) or Clang (C++20 compliant).
- **Build System**: GNU Make.

### Building the Library
To build the library, execute the `make` command in the source directory:

```bash
make
```

### Output Artifacts
All built libraries are placed in the `lib/` subdirectory. The build process creates versioned binaries and provides consistent symbolic links:

- **Static Library**: `libswtr_ringbuffer.a` $\rightarrow$ `libswtr_ringbuffer-$(VERSION).a`
- **Shared Library**: `libswtr_ringbuffer.dylib` $\rightarrow$ `libswtr_ringbuffer-$(VERSION).dylib`

### Verification
You can verify that the resulting binaries are universal binaries using the `lipo` tool:

```bash
lipo -info lib/libswtr_ringbuffer.dylib
```

## Technical Specifications

- **Threading**: Separate threads for each stage using `std::jthread` and `std::stop_callback`.
- **Synchronization**: Advanced synchronization primitives to manage buffer status transitions.
- **Complexity**: Fixed-size buffer ensuring $O(1)$ time complexity for read/write operations.
- **Alignment**: Buffer slots and counters are aligned to 64-byte boundaries to avoid false sharing.
