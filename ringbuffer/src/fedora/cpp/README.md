# Ringbuffer Library — Fedora

A high-performance, thread-safe ring buffer (circular buffer) library implementing a three-stage pipeline architecture: **Read → Transform → Write**. Built for binary symmetry across Linux distributions.

## Overview

The Ringbuffer connects its memory end-to-end in a loop, using independent read, transform, and write threads with atomic index counters. It supports configurable slot counts, buffer sizes, custom transformation functions, and error handling callbacks.

## Build Requirements

- **Compiler**: `g++` or `clang++` (C++20 compliant)
- **Build System**: GNU Make
- **Target OS**: Fedora Linux

### Prerequisites (Fedora)

```bash
sudo dnf install -y gcc-c++ make binutils cmake doxygen clang clang-tools-extra
```

## Building

### Using Make (Recommended)
```bash
cd ringbuffer/src/fedora/cpp
make                    # Build both static and shared libraries
make static             # Build static library only (.a)
make shared             # Build shared library only (.so)
make clean              # Remove build artifacts
```

### Using g++ (Manual)

```bash
g++ -std=c++20 -fPIC -Wall -Wextra -O3 -flto=thin \
    -I. -c Lifecycle.cpp ReadOps.cpp TransformOps.cpp WriteOps.cpp \
       Threading.cpp ErrorOps.cpp LoggingOps_1.cpp LoggingOps_2.cpp \
       LoggingOps_3.cpp LoggingOps_4.cpp LoggingOps_5.cpp LoggingOps_6.cpp \
       Accessors_Status.cpp Accessors_ChecksumAlg.cpp Accessors_ChecksumVal.cpp \
       Accessors_Size_Max.cpp Accessors_Size_Data.cpp Accessors_Size_Transformed.cpp

ar rcs lib/libswtr_ringbuffer-1.0.0-1.a *.o
g++ -shared -Wl,-soname,libswtr_ringbuffer.so -o lib/libswtr_ringbuffer-1.0.0-1.so *.o
```

### Using clang++ (Manual)

```bash
clang++ -std=c++20 -fPIC -Wall -Wextra -O3 -flto=thin \
    -I. -c Lifecycle.cpp ReadOps.cpp TransformOps.cpp WriteOps.cpp \
       Threading.cpp ErrorOps.cpp LoggingOps_1.cpp LoggingOps_2.cpp \
       LoggingOps_3.cpp LoggingOps_4.cpp LoggingOps_5.cpp LoggingOps_6.cpp \
       Accessors_Status.cpp Accessors_ChecksumAlg.cpp Accessors_ChecksumVal.cpp \
       Accessors_Size_Max.cpp Accessors_Size_Data.cpp Accessors_Size_Transformed.cpp

ar rcs lib/libswtr_ringbuffer-1.0.0-1.a *.o
clang++ -shared -Wl,-soname,libswtr_ringbuffer.so -o lib/libswtr_ringbuffer-1.0.0-1.so *.o
```

## Library Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Static library | `lib/libswtr_ringbuffer-1.0.0-1.a` | Versioned static library |
| Shared library | `lib/libswtr_ringbuffer-1.0.0-1.so` | Versioned shared library (soname: `libswtr_ringbuffer.so`) |

## Containerized Build

```bash
make container          # Build the Fedora build image
make container-clean    # Remove the build image
```

## Architecture

- **RingBuffer**: Abstract base class defining the public interface
- **SwtrRingBuffer**: Concrete implementation with three pipeline threads (read, transform, write)
- **BufferSlot**: Cache-line aligned slot structure with atomic state management

## License

BSD 3-Clause License — see [LICENSE](LICENSE) for details.