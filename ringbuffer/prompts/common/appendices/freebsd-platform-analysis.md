# FreeBSD Platform Analysis (FreeBSD 14)

> **Purpose:** Reference data collected from the FreeBSD 14 test system for ringbuffer C++ implementation planning.
>
> **System Access:** `ssh ebruno@10.10.41.244`
> **Collected:** 2026-08-16

---

## System Information

| Field | Value |
|-------|-------|
| **OS** | FreeBSD 14.4-RELEASE-p3 |
| **Kernel** | FreeBSD freebsd144vm03 14.4-RELEASE-p3 FreeBSD 14.4-RELEASE-p3 GENERIC amd64 |
| **Architecture** | amd64 (x86_64) |
| **hw.machine_arch** | amd64 |

---

## Toolchain

### C++ Compiler
| Field | Value |
|-------|-------|
| **Compiler** | FreeBSD clang 19.1.7 |
| **Target** | x86_64-unknown-freebsd14.4 |
| **Thread model** | posix |
| **Location** | `/usr/bin/clang++` |
| **LLVM repo** | https://github.com/llvm/llvm-project.git llvmorg-19.1.7-0-gcd708029e0b2 |

### g++ (GCC)
- **Not installed** — no GCC package on this system. `g++` returns "Command not found."
- Only clang is available as the C++ compiler.

### Linker
| Field | Value |
|-------|-------|
| **Linker** | LLD 19.1.7 (FreeBSD) |
| **Location** | `/usr/bin/ld.lld` (also `/usr/bin/ld`) |
| **Compatibility** | GNU-compatible linker interface |

### Make
- FreeBSD make (not GNU make)
- No `-v` flag — use `make -V VERSION` to query version

### Standard Library
| Field | Value | Location |
|-------|-------|----------|
| **libc++** (LLVM) | Static: `libc++.a`, Shared: `libc++.so` | `/usr/lib/` |
| **libstdc++** (GNU) | **Not available** | N/A |

> **Key difference from macOS:** FreeBSD uses LLVM's libc++ by default (same as clang), but there is no libstdc++ fallback. On macOS, Homebrew g++ defaults to libstdc++. FreeBSD has no GCC at all.

### C++20 Header Availability
| Header | Available? | Location |
|--------|-----------|----------|
| `<format>` | ✅ Yes | `/usr/include/c++/v1/format` |
| `<stop_token>` | ✅ Yes | `/usr/include/c++/v1/__stop_token` |
| `<jthread>` | ✅ Yes (via clang 19) | `/usr/include/c++/v1/` |

> **C++20 support:** FreeBSD clang 19.1.7 provides full C++20 standard library headers via the `__cpp_lib_format` and `<stop_token>` support. This matches macOS clang 21 in capability.

---

## Available Binutils / Analysis Tools

| Tool | Location | Notes |
|------|----------|-------|
| `ar` | `/usr/bin/ar` | Static library archiver ✅ |
| `nm` | `/usr/bin/nm` | Symbol inspection ✅ |
| `objdump` | `/usr/bin/objdump` | Object file analysis ✅ |
| `readelf` | `/usr/bin/readelf` | ELF binary analysis ✅ |
| `strip` | `/usr/bin/strip` | Symbol stripping ✅ |
| `file` | `/usr/bin/file` | File type detection ✅ |
| `size` | `/usr/bin/size` | Binary size analysis ✅ |

### Missing Tools (macOS-specific)
| Tool | Status | Notes |
|------|--------|-------|
| `lipo` | ❌ Not available | macOS Universal Binary tool — not needed on FreeBSD (single-arch only) |
| `otool` | ❌ Not available | macOS Mach-O binary analyzer — FreeBSD uses ELF, use `readelf` instead |

---

## Installed Packages Summary

- **Total packages installed:** 102
- **C++ libraries:** Only `jsoncpp-1.9.6_1` (JSON reader/writer)
- **No GCC package** installed
- **No binutils package** installed (but base system includes `ar`, `nm`, `readelf`, `strip`)
- **cmake** 3.31.7 installed (meta-port + core)

---

## Platform-Specific Notes for Ringbuffer Implementation

### ELF vs Mach-O
- FreeBSD uses **ELF** binary format (like Linux), not Mach-O (macOS)
- Shared library extension: `.so` (same as Linux, different from macOS `.dylib`)
- SONAME support via `readelf -d` (same as Linux)
- Install name: Use `-soname libswtr_ringbuffer.so` (ELF convention, not `@rpath`)

### No Universal Binaries
- FreeBSD does **not** support fat/universal binaries like macOS
- Single architecture only (amd64 on this system)
- No `-arch` flag needed in compiler invocations

### Linker Flags
- Dead code elimination: `-Wl,--gc-sections` (same as Linux)
- Position-independent code: `-fPIC` (required for shared libraries on FreeBSD)
- Visibility hidden: `-fvisibility=hidden`

### Standard Library Path
- libc++ headers are in `/usr/include/c++/v1/` (Clang's C++ standard library)
- libc++ libraries are in `/usr/lib/`
- No need for `-stdlib=libc++` — it's the default on FreeBSD clang

### POSIX Compatibility
- FreeBSD has full POSIX.1 support (like macOS)
- `fsync()` works identically to Linux/macOS
- `<unistd.h>` provides POSIX I/O (`read`, `write`, `fsync`)
- No `O_DIRECT` support (similar to macOS)

### Container Support
- **Native-only** — no Docker/Podman support on FreeBSD
- All builds and tests run natively on the host

---

## Comparison: macOS vs FreeBSD 14 Toolchain

| Aspect | macOS (Apple clang 21) | FreeBSD 14 (FreeBSD clang 19.1.7) |
|--------|----------------------|----------------------------------|
| **Compiler** | Apple clang 21.0.0 | FreeBSD clang 19.1.7 |
| **Target** | arm64-apple-darwin25.5.0 | x86_64-unknown-freebsd14.4 |
| **Std Lib** | libc++ (Apple) | libc++ (LLVM upstream) |
| **g++ available** | Yes (Homebrew, limited) | No |
| **Binary format** | Mach-O | ELF |
| **Shared lib ext** | `.dylib` | `.so` |
| **Install name** | `@rpath/libswtr_ringbuffer.dylib` | `-soname libswtr_ringbuffer.so` |
| **Universal binaries** | Yes (lipo) | No |
| **Linker** | ld64 (Apple) | LLD 19.1.7 |
| **C++20 `<format>`** | ✅ Yes | ✅ Yes |
| **C++20 `<stop_token>`** | ✅ Yes | ✅ Yes |
| **`lipo`/`otool`** | ✅ Available | ❌ Not available |
| **`readelf`** | ❌ Not available (use `otool`) | ✅ Available |
| **Dead code elim** | `-dead_strip` | `-Wl,--gc-sections` |
| **Container support** | None (native-only) | None (native-only) |

---

## Source Code Compatibility Assessment

### Likely Byte-Identical (no changes needed)
The following source files should compile on FreeBSD without modification:
- `status.hpp` — pure enum definitions, no platform dependencies
- `ringbuffer.hpp` — uses standard C++20 headers (`<atomic>`, `<format>`, `<stop_token>`)
- `swtr_ringbuffer_impl.hpp` — implementation class header
- `Lifecycle.cpp`, `ReadOps.cpp`, `TransformOps.cpp` — standard C++20 + POSIX I/O
- `Accessors_*.cpp`, `LoggingOps_*.cpp` — standard C++20
- `ErrorOps.cpp`, `WriteOps.cpp` — uses `<unistd.h>` (POSIX, available on FreeBSD)

### Potential Differences
- **Makefile**: Needs platform-specific adjustments:
  - No universal binary targets (no `-arch arm64` / `-arch x86_64`)
  - Shared library uses `.so` extension and ELF SONAME convention
  - Linker flag: `-Wl,--gc-sections` instead of `-dead_strip`
  - No `libtool -static` needed (use `ar rcs`)
- **No `lipo` or `otool`**: Binary verification uses `readelf`, `file`, `nm` instead
- **No Homebrew g++**: Only clang++ is available (no multi-compiler Makefile targets)

### POSIX I/O Compatibility
FreeBSD has full POSIX.1 support:
- `read()`, `write()`, `fsync()` — all available via `<unistd.h>`
- `ssize_t` return type for I/O functions — same as Linux/macOS
- `EAGAIN`, `EINTR` errno values exist but may differ numerically from Linux
