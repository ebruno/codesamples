# Ringbuffer Library

A high-performance, C++20 compliant ring buffer implementation designed for Fedora 44. 
It uses a three-stage pipeline (Read, Transform, Write) running in separate threads with cooperative cancellation.

## Features
- C++20 compliant.
- Uses `std::jthread` and `std::stop_token` for thread management.
- Cache line alignment to prevent false sharing.
- Flexible logging with NVI pattern and variadic templates.
- POSIX file descriptor support for I/O.

## Build Instructions

The library can be built using the provided Makefile. It is compatible with both GCC and Clang.

To build the library:
```bash
make -j$(nproc)
```

This will create versioned static and shared libraries in the `lib/` directory, as well as unversioned symbolic links.

To clean the build artifacts:
```bash
make clean
```

## License
This project is licensed under the BSD 3-Clause License.
<EOF>
