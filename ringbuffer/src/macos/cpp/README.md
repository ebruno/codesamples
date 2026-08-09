# Swtr Ringbuffer Library (macOS)

## Description
A high-performance, thread-safe C++20 ring buffer implementation designed for pipeline processing (Read -> Transform -> Write).

## Build Instructions

### Using g++
```bash
g++ -std=c++20 -O3 -fvisibility=hidden -fvisibility-inlines-hidden \
    Lifecycle.cpp LoggingOps_*.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp Threading.cpp ErrorOps.cpp Accessors_*.cpp \
    -o libswtr_ringbuffer.dylib -dynamiclib
```

### Using clang++
```bash
clang++ -std=c++20 -O3 -fvisibility=hidden -fvisibility-inlines-hidden \
    Lifecycle.cpp LoggingOps_*.cpp ReadOps.cpp TransformOps.cpp \
    WriteOps.cpp Threading.cpp ErrorOps.cpp Accessors_*.cpp \
    -o libswtr_ringbuffer.dylib -dynamiclib
```

## API Overview
The library provides a `RingBuffer` abstract interface and a `SwtrRingBuffer` concrete implementation.
