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
> **Note:** The compilation example below uses explicit filenames. Glob patterns like `LoggingOps_*.cpp` work in Makefiles but not in shell commands.

```bash
clang++ -std=c++20 -O3 -fPIC -flto=thin \
    -fvisibility=hidden \
    -ffunction-sections -fdata-sections \
    Lifecycle.cpp Threading.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp ErrorOps.cpp \
    LoggingOps_1.cpp LoggingOps_2.cpp LoggingOps_3.cpp \
    LoggingOps_4.cpp LoggingOps_5.cpp LoggingOps_6.cpp \
    Accessors_Status.cpp Accessors_ChecksumAlg.cpp \
    Accessors_ChecksumVal.cpp Accessors_Size_Max.cpp \
    Accessors_Size_Data.cpp Accessors_Size_Transformed.cpp \
    -o libswtr_ringbuffer.so -shared -Wl,--gc-sections
```

## Library Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Static library (versioned) | `lib/libswtr_ringbuffer-1.0.0-1.a` | Versioned static library (ar rcs) |
| Static library (unversioned) | `lib/libswtr_ringbuffer.a` | Symlink → versioned static library |
| Shared library (versioned) | `lib/libswtr_ringbuffer-1.0.0-1.so` | Versioned shared library (ELF SONAME) |
| Shared library (unversioned) | `lib/libswtr_ringbuffer.so` | Symlink → versioned shared library |

All libraries are built for a single architecture (amd64 on FreeBSD 14). FreeBSD does not support universal/fat binaries.

## Threading Implementation Note
FreeBSD clang 19.1.7 does not provide `<jthread>` (C++20). This implementation uses `std::thread` + `std::stop_source`/`std::stop_token` from `<stop_token>` (which is available) for cooperative cancellation. This preserves the same semantics as `std::jthread` while remaining compatible with FreeBSD's standard library.

## RPATH Limitation (FreeBSD 14)
FreeBSD 14's `ld-elf.so.1` does NOT support `$ORIGIN` in RUNPATH — the dynamic linker strips it to empty at runtime. **Dynamic library testing is not possible on FreeBSD 14.** Use static library only (via `make verify` target). See [freebsd-platform-analysis.md](../../common/appendices/freebsd-platform-analysis.md) for details.

## Container Support
FreeBSD builds run natively — containers are prohibited. The `container` target is a no-op:
```bash
make container  # Outputs: "Container not used for FreeBSD native build"
```

## API Overview
The library provides a `RingBuffer` abstract interface and a `SwtrRingBuffer` concrete implementation.
