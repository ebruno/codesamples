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
```bash
g++ -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic -flto \
    Lifecycle.cpp LoggingOps_*.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp Threading.cpp ErrorOps.cpp Accessors_*.cpp \
    -o libswtr_ringbuffer.so -shared -Wl,--gc-sections
```

### Using clang++ (Manual)
```bash
clang++ -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic -flto=thin \
    Lifecycle.cpp LoggingOps_*.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp Threading.cpp ErrorOps.cpp Accessors_*.cpp \
    -o libswtr_ringbuffer.so -shared
```

### Prerequisites (Arch Linux)
```bash
sudo pacman -S --needed base-devel gcc clang make binutils
```

## Library Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Static library | `lib/libswtr_ringbuffer-1.0.0-1.a` | Versioned static library |
| Shared library | `lib/libswtr_ringbuffer-1.0.0-1.so` | Versioned shared library (soname: `libswtr_ringbuffer.so`) |
| Unversioned symlink | `lib/libswtr_ringbuffer.so` | Convenience symlink to shared library |

## Container Support
Arch Linux builds run natively on Linux hosts. On Apple Silicon Macs, containers are not available (Arch Linux container images are amd64-only):

```bash
make container  # Outputs: "Container not used for Arch Linux native build"
```

On macOS, the `container` target detects Apple Silicon and skips gracefully with a logged message. Build and test must be performed on a Linux host via SSH.

## API Overview
The library provides a `RingBuffer` abstract interface and a `SwtrRingBuffer` concrete implementation.

## License
This project is licensed under the BSD 3-Clause License.
