# Swtr Ringbuffer Library (FreeBSD)

## Description
A high-performance, thread-safe C++20 ring buffer implementation designed for pipeline processing (Read → Transform → Write).

## Build Instructions

### Using Make (Recommended)
```bash
make                    # Build both static and shared libraries
make static             # Build static library only (.a)
make shared             # Build shared library only (.so)
make clean              # Remove build artifacts
```

### Using clang++ (Manual)
```bash
clang++ -std=c++20 -O3 -fvisibility=hidden -shared \
    Lifecycle.cpp LoggingOps_*.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp Threading.cpp ErrorOps.cpp Accessors_*.cpp \
    -o libswtr_ringbuffer.so -soname libswtr_ringbuffer.so
```

## Library Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Static library | `lib/libswtr_ringbuffer-1.0.0-1.a` | Versioned static library (ar rcs) |
| Shared library | `lib/libswtr_ringbuffer-1.0.0-1.so` | Versioned shared library (ELF SONAME) |
| Unversioned symlink | `lib/libswtr_ringbuffer.so` | Convenience symlink to shared library |

All libraries are built for a single architecture (amd64 on FreeBSD 14). FreeBSD does not support universal/fat binaries.

## Threading Implementation Note
FreeBSD clang 19.1.7 does not provide `<jthread>` (C++20). This implementation uses `std::thread` + `std::stop_source`/`std::stop_token` from `<stop_token>` (which is available) for cooperative cancellation. This preserves the same semantics as `std::jthread` while remaining compatible with FreeBSD's standard library.

## Container Support
FreeBSD builds run natively — containers are prohibited. The `container` target is a no-op:
```bash
make container  # Outputs: "Container not used for FreeBSD native build"
```

## API Overview
The library provides a `RingBuffer` abstract interface and a `SwtrRingBuffer` concrete implementation.
