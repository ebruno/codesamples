# Swtr Ringbuffer (Debian C++ Implementation)

## Description
A high-performance, fixed-size circular buffer implementation for C++20. This library provides a three-stage pipeline (Read -> Transform -> Write) with strong thread safety and cache-line alignment to prevent false sharing.

## Features
- **C++20 Compliant**: Uses `std::jthread`, `std::stop_token`, and `std::format`.
- **Thread Safe**: Atomic state management and synchronization primitives.
- **Optimized**: `alignas(64)` on critical structures to avoid cache line contention.
- **Flexible**: Custom transform functions and error handlers.

## Architecture
The implementation follows a strict separation of concerns:
- `RingBuffer`: Abstract interface defining the API.
- `SwtrRingBuffer`: Concrete implementation.
- `BufferSlot`: The unit of data storage, containing state and checksum information.

## Building the Library
This library is designed to be built with GCC or Clang.

### Compilation Example
```bash
g++ -std=c++20 -O3 -fvisibility=hidden -fvisibility-inlines-hidden \
    -ffunction-sections -fdata-sections \
    -Wall -Wextra -Werror \
    Lifecycle.cpp Threading.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp ErrorOps.cpp LoggingOps_1.cpp LoggingOps_2.cpp \
    LoggingOps_3.cpp LoggingOps_4.cpp LoggingOps_5.cpp LoggingOps_6.cpp \
    Accessors_Status.cpp Accessors_ChecksumAlg.cpp Accessors_ChecksumVal.cpp \
    Accessors_Size_Max.cpp Accessors_Size_Data.cpp Accessors_Size_Transformed.cpp \
    -o libswtr_ringbuffer.so -shared -Wl,--gc-sections
```

## License
This project is licensed under the BSD 3-Clause License.
