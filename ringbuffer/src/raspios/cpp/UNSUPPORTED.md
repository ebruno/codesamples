# Raspios C++ — UNSUPPORTED

**Date:** 2026-08-20
**Status:** UNSUPPORTED — Toolchain does not support required C++20 features

## Reason

The Raspios container (`raspios:arm64-bookworm`) ships with toolchain versions that do not support the `<format>` header required by `ringbuffer.hpp`:

| Tool | Version in Container | C++20 `<format>` Support |
|------|---------------------|--------------------------|
| g++  | GCC 12.2.0          | ❌ No (requires GCC 13+) |
| clang++ | Clang 14.0.6      | ❌ No (requires Clang 15+) |

Both compilers were tested and fail with:
```
fatal error: 'format' file not found
#include <format>
         ^~~~~~~~
```

## Required Minimum Versions

- **GCC 13+** or **Clang 15+** for C++20 `<format>` support
- The Raspios Bookworm base image (Debian 12) only provides GCC 12.2 and Clang 14

## Options to Enable Support

1. **Upgrade the base image** — Use a newer Debian/Ubuntu base with GCC 13+ or Clang 15+
2. **Remove `<format>` dependency** — Replace `std::format` usage with an alternative (e.g., `printf`, `snprintf`, or a third-party format library)
3. **Use a different base image** — Switch to Fedora or Ubuntu 24.04 which have newer compilers

## Build Error Details

```
g++ -std=c++20 -fPIC -Wall -Wextra -Wpedantic -O3 -flto \
    -fvisibility=hidden -ffunction-sections -fdata-sections -I. \
    -c Lifecycle.cpp -o build/Lifecycle.o

In file included from Lifecycle.cpp:1:
ringbuffer.hpp:4:10: fatal error: format: No such file or directory
    4 | #include <format>
      |          ^~~~~~~~
```

## Notes

- This is a **toolchain limitation**, not a source code bug
- The same source builds successfully on: macOS (Apple clang 21), Fedora (GCC in container), Debian (GCC 14.2), Ubuntu (GCC in container)
- Raspios is the only platform where the required C++20 `<format>` header is unavailable
