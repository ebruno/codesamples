# Swtr Ringbuffer (Arch Linux C++ Implementation)

## Description
A high-performance, thread-safe C++20 ring buffer implementation designed for pipeline processing (Read → Transform → Write).

**Note:** Arch Linux is a rolling-release distribution — there are no point-release version numbers. The container image used for builds (on Linux hosts) is pinned to a specific datestamp (e.g., `archlinux:2026.08.01`) to ensure reproducible builds.

## Build Instructions

### Using Make (Recommended)
```bash
make                    # Build both static and shared libraries
make static             # Build static library only (.a)
make shared             # Build shared library only (.so)
make clean              # Remove build artifacts
```

### Using g++ (Manual)
> **Note:** The compilation examples below use explicit filenames. Glob patterns like `LoggingOps_*.cpp` work in Makefiles but not in shell commands.

```bash
g++ -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic -flto \
    Lifecycle.cpp Threading.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp ErrorOps.cpp \
    LoggingOps_1.cpp LoggingOps_2.cpp LoggingOps_3.cpp \
    LoggingOps_4.cpp LoggingOps_5.cpp LoggingOps_6.cpp \
    Accessors_Status.cpp Accessors_ChecksumAlg.cpp \
    Accessors_ChecksumVal.cpp Accessors_Size_Max.cpp \
    Accessors_Size_Data.cpp Accessors_Size_Transformed.cpp \
    -o libswtr_ringbuffer.so -shared -Wl,--gc-sections
```

### Using clang++ (Manual)
```bash
clang++ -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic -flto=thin \
    Lifecycle.cpp Threading.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp ErrorOps.cpp \
    LoggingOps_1.cpp LoggingOps_2.cpp LoggingOps_3.cpp \
    LoggingOps_4.cpp LoggingOps_5.cpp LoggingOps_6.cpp \
    Accessors_Status.cpp Accessors_ChecksumAlg.cpp \
    Accessors_ChecksumVal.cpp Accessors_Size_Max.cpp \
    Accessors_Size_Data.cpp Accessors_Size_Transformed.cpp \
    -o libswtr_ringbuffer.so -shared
```

### Prerequisites (Arch Linux)
```bash
sudo pacman -S --needed base-devel gcc clang make binutils
```

## Library Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Static library (versioned) | `lib/libswtr_ringbuffer-1.0.0-1.a` | Versioned static library |
| Static library (unversioned) | `lib/libswtr_ringbuffer.a` | Symlink → versioned static library |
| Shared library (versioned) | `lib/libswtr_ringbuffer-1.0.0-1.so` | Versioned shared library (soname: `libswtr_ringbuffer.so`) |
| Shared library (unversioned) | `lib/libswtr_ringbuffer.so` | Symlink → versioned shared library |

## Multi-Compiler Support
Arch Linux ships both `g++` and `clang++`. The Makefile auto-detects available compilers and defaults to the first one found. You can override with `CXX=g++` or `CXX=clang++`:

```bash
make CXX=g++    # Build with GCC
make CXX=clang++ # Build with Clang
```

## Container Support
Arch Linux builds run natively on Linux hosts. On Apple Silicon Macs, containers are not available because Arch Linux does not provide an official, standard container image for ARM architectures (e.g., Apple Silicon, Raspberry Pi). The official archlinux Docker images are built exclusively for the x86_64 architecture.

```bash
make container  # Outputs: "Container not used for Arch Linux native build"
```

On macOS, the `container` target detects Apple Silicon and skips gracefully with a logged message. Build and test must be performed on a Linux host via SSH.

## API Overview
The library provides a `RingBuffer` abstract interface and a `SwtrRingBuffer` concrete implementation.

## License
This project is licensed under the BSD 3-Clause License.
