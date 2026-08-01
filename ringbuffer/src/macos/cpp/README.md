# Ringbuffer Library (macOS)

A high-performance, C++20 compliant ring buffer implementation designed for macOS.
It uses a three-stage pipeline (Read, Transform, Write) running in separate threads with cooperative cancellation.

## Features
- C++20 compliant.
- Uses `std::jthread` and `std::stop_token` for thread management.
- Cache line alignment to prevent false sharing.
- Flexible logging with NVI pattern and variadic templates.
- POSIX file descriptor support for I/O.
- Universal Binary support (arm64 and x86_64).

## Build Instructions
The library is designed to be built using Clang on macOS.

To compile the fat binaries:
```bash
make -j$(sysctl -n hw.ncpu)
```

## License
This project is licensed under the BSD 3-Clause License.
