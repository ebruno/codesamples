# Swtr Ringbuffer Library (macOS)

## Description
A high-performance, thread-safe C++20 ring buffer implementation designed for pipeline processing (Read → Transform → Write).

## Build Instructions

### Using Make (Recommended)
```bash
make                    # Build both static and shared libraries
make static             # Build static library only (.a)
make shared             # Build shared library only (.dylib)
make clean              # Remove build artifacts
```

### Using clang++ (Manual)
```bash
clang++ -std=c++20 -O3 -fvisibility=hidden -fvisibility-inlines-hidden \
    Lifecycle.cpp LoggingOps_*.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp Threading.cpp ErrorOps.cpp Accessors_*.cpp \
    -o libswtr_ringbuffer.dylib -dynamiclib
```

### Using g++ (Manual)
```bash
g++ -std=c++20 -O3 -fvisibility=hidden -fvisibility-inlines-hidden \
    Lifecycle.cpp LoggingOps_*.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp Threading.cpp ErrorOps.cpp Accessors_*.cpp \
    -o libswtr_ringbuffer.dylib -dynamiclib
```

## Library Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Static library | `lib/libswtr_ringbuffer-1.0.0-1.a` | Versioned static library |
| Shared library | `lib/libswtr_ringbuffer-1.0.0-1.dylib` | Versioned shared library |
| Unversioned symlink | `lib/libswtr_ringbuffer.dylib` | Convenience symlink to shared library |

All libraries are built as **universal binaries** (arm64 + x86_64) via `lipo -create`, enabling execution on both Apple Silicon and Intel Macs.

## Container Support
macOS builds run natively — containers are prohibited. The `container` target is a no-op:
```bash
make container  # Outputs: "Container not used for macOS native build"
```

## API Overview
The library provides a `RingBuffer` abstract interface and a `SwtrRingBuffer` concrete implementation.
