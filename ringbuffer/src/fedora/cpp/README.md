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
The library is designed to be buildable using both Clang and GCC. 

To compile:
```bash
g++ -std=c++20 -O3 -ffunction-sections -fdata-sections *.cpp -o libringbuffer.so -shared -fPIC
```

Or using Clang:
```bash
clang++ -std=c++20 -O3 -ffunction-sections -fdata-sections *.cpp -o libringbuffer.so -shared -fPIC
```

## License
This project is licensed under the BSD 3-Clause License.
