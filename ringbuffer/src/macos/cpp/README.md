# Swtr Ringbuffer Library (macOS)

## Description
A high-performance, thread-safe C++20 ring buffer implementation designed for pipeline processing (Read → Transform → Write).

## Build Instructions

### Using Make (Recommended)
```bash
make                    # Build both static and shared libraries (clean first)
make all                # Same as above — clean + build
make static             # Build static library only (.a)
make shared             # Build shared library only (.dylib)
make clean              # Remove build artifacts
make dist-clean         # Full cleanup including reports and logs
```

### Using clang++ (Manual)
> **Note:** The file lists below use explicit filenames. Glob patterns like `LoggingOps_*.cpp` work in Makefiles but not in shell commands.

```bash
clang++ -std=c++20 -O3 -fPIC -flto=thin \
    -fvisibility=hidden -fvisibility-inlines-hidden \
    -ffunction-sections -fdata-sections -Wall -Wextra -Wpedantic \
    Lifecycle.cpp Threading.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp ErrorOps.cpp \
    LoggingOps_1.cpp LoggingOps_2.cpp LoggingOps_3.cpp \
    LoggingOps_4.cpp LoggingOps_5.cpp LoggingOps_6.cpp \
    Accessors_Status.cpp Accessors_ChecksumAlg.cpp \
    Accessors_ChecksumVal.cpp Accessors_Size_Max.cpp \
    Accessors_Size_Data.cpp Accessors_Size_Transformed.cpp \
    -o libswtr_ringbuffer.dylib -dynamiclib
```

### Using g++ (Manual)
```bash
g++ -std=c++20 -O3 -fPIC -flto \
    -fvisibility=hidden -fvisibility-inlines-hidden \
    -ffunction-sections -fdata-sections -Wall -Wextra -Wpedantic \
    Lifecycle.cpp Threading.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp ErrorOps.cpp \
    LoggingOps_1.cpp LoggingOps_2.cpp LoggingOps_3.cpp \
    LoggingOps_4.cpp LoggingOps_5.cpp LoggingOps_6.cpp \
    Accessors_Status.cpp Accessors_ChecksumAlg.cpp \
    Accessors_ChecksumVal.cpp Accessors_Size_Max.cpp \
    Accessors_Size_Data.cpp Accessors_Size_Transformed.cpp \
    -o libswtr_ringbuffer.dylib -dynamiclib
```

## Library Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Static library (versioned) | `lib/libswtr_ringbuffer-1.0.0-1.a` | Versioned static library |
| Static library (unversioned) | `lib/libswtr_ringbuffer.a` | Symlink → versioned static library |
| Shared library (versioned) | `lib/libswtr_ringbuffer-1.0.0-1.dylib` | Versioned shared library |
| Shared library (unversioned) | `lib/libswtr_ringbuffer.dylib` | Symlink → versioned shared library |

All libraries are built as **universal binaries** (arm64 + x86_64) via `lipo -create`, enabling execution on both Apple Silicon and Intel Macs.

## Container Support
macOS builds run natively — containers are prohibited. The `container` target is a no-op:
```bash
make container  # Outputs: "Container not used for macOS native build"
```
All builds and tests execute directly on the host using native toolchains (clang++, make, ar).

## API Overview
The library provides a `RingBuffer` abstract interface and a `SwtrRingBuffer` concrete implementation.

Key methods include:
- `start()` — Launches the three pipeline threads (read, transform, write)
- `stop()` — Signals cooperative cancellation to all threads
- `wait()` — Blocks until pipeline completes and threads join
- `setTransform(func)` — Registers a user-supplied transform callback
- `setErrorCallback(handler)` — Registers an error handler that returns non-zero to trigger shutdown
