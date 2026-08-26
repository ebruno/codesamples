# Swtr Ringbuffer (Raspberry Pi OS C++ Implementation)

## Description
A high-performance, fixed-size circular buffer implementation for C++20. This library provides a three-stage pipeline (Read → Transform → Write) with strong thread safety and cache-line alignment to prevent false sharing.

## Features
- **C++20 Compliant**: Uses `std::jthread`, `std::stop_token`, and `std::format`.
- **Thread Safe**: Atomic state management and synchronization primitives.
- **Optimized**: `alignas(64)` on critical structures to avoid cache line contention.
- **Flexible**: Custom transform functions and error handlers.

## Build Instructions

### Using Make (Recommended)
```bash
make                    # Build both static and shared libraries (clean first)
make all                # Same as above — clean + build
make static             # Build static library only (.a)
make shared             # Build shared library only (.so)
make clean              # Remove build artifacts
```

### Compilation Example (Manual)
> **Note:** The compilation examples below use explicit filenames. Glob patterns like `LoggingOps_*.cpp` work in Makefiles but not in shell commands.

```bash
g++ -std=c++20 -fPIC -flto \
    -Wall -Wextra -O3 -fvisibility=hidden \
    -ffunction-sections -fdata-sections \
    Lifecycle.cpp Threading.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp ErrorOps.cpp LoggingOps_1.cpp LoggingOps_2.cpp \
    LoggingOps_3.cpp LoggingOps_4.cpp LoggingOps_5.cpp LoggingOps_6.cpp \
    Accessors_Status.cpp Accessors_ChecksumAlg.cpp Accessors_ChecksumVal.cpp \
    Accessors_Size_Max.cpp Accessors_Size_Data.cpp Accessors_Size_Transformed.cpp \
    -o libswtr_ringbuffer.so -shared -Wl,--gc-sections
```

### Compilation Example (Clang++)
```bash
clang++ -std=c++20 -fPIC \
    -Wall -Wextra -O3 -fvisibility=hidden \
    -ffunction-sections -fdata-sections \
    Lifecycle.cpp Threading.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp ErrorOps.cpp LoggingOps_1.cpp LoggingOps_2.cpp \
    LoggingOps_3.cpp LoggingOps_4.cpp LoggingOps_5.cpp LoggingOps_6.cpp \
    Accessors_Status.cpp Accessors_ChecksumAlg.cpp Accessors_ChecksumVal.cpp \
    Accessors_Size_Max.cpp Accessors_Size_Data.cpp Accessors_Size_Transformed.cpp \
    -o libswtr_ringbuffer.so -shared -Wl,--gc-sections
```

## Library Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Static library (versioned) | `lib/libswtr_ringbuffer-1.0.0-1.a` | Versioned static library |
| Static library (unversioned) | `lib/libswtr_ringbuffer.a` | Symlink → versioned static library |
| Shared library (versioned) | `lib/libswtr_ringbuffer-1.0.0-1.so` | Versioned shared library (soname: `libswtr_ringbuffer.so`) |
| Shared library (unversioned) | `lib/libswtr_ringbuffer.so` | Symlink → versioned shared library |

## Architecture
The implementation follows a strict separation of concerns:
- `RingBuffer`: Abstract interface defining the API.
- `SwtrRingBuffer`: Concrete implementation.
- `BufferSlot`: The unit of data storage, containing state and checksum information.

## Containerized Build Environment
This project supports containerized builds for reproducible environments:

### Building the Container Image
```bash
make container    # Build ringbuffer_raspios_build image from Dockerfile
```

### Running Builds in Container
The Makefile automatically detects the host OS and uses the appropriate container runtime:
- **macOS**: Uses Apple Container (`container` command)
- **Linux (non-raspios)**: Uses Podman (`podman` command)

### Cleaning Up Containers
```bash
make container-clean    # Remove the ringbuffer_raspios_build image
```

## License
This project is licensed under the BSD 3-Clause License.
