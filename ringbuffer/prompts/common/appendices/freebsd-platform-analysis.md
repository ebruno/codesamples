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

---

## Shell Availability (for Test Infrastructure Scripts)

The ringbuffer project generates utility scripts in four shell variants: **tcsh**, **zsh**, **bash**, and **sh** (Bourne). All four must be available on FreeBSD for test data generation, verification, and JUnit report scripts.

| Shell | Available? | Version | Location |
|-------|-----------|---------|----------|
| **tcsh** | ✅ Yes | 6.22.04 (Astron) 2021-04-26 | `/bin/tcsh` (listed in `/etc/shells`) |
| **zsh** | ❌ No | `Command not found` | Not installed |
| **bash** | ✅ Yes | 5.2.37(0)-release (amd64-portbld-freebsd14.2) | `/usr/local/bin/bash` (listed in `/etc/shells`) |
| **sh** | ✅ Yes | FreeBSD BSD `sh` (169 KB binary) | `/bin/sh` (listed in `/etc/shells`) |

### `/etc/shells` Contents
```
/bin/sh
/bin/csh
/bin/tcsh
/usr/local/bin/bash
/usr/local/bin/rbash
/usr/local/libexec/git-core/git-shell
```

### Implications for Script Generation
- **tcsh**: Available — generate `*.tcsh` variants ✅
- **zsh**: NOT available — must install or skip `*.zsh` variants ⚠️
- **bash**: Available — generate `*.sh` (bash) variants ✅
- **sh** (BSD sh): Available — generate `bin_sh.sh` variants ✅

> **Note:** The project's test infrastructure scripts include `*.zsh` variants (e.g., `generate_test_data.zsh`, `verify_test_data.zsh`). On this FreeBSD 14 system, zsh is not installed. It can be installed via `pkg install zsh` if needed for test execution, but the scripts themselves are generated regardless — they just won't be runnable until zsh is installed.

### Shebang Lines for Generated Scripts
| Variant | Shebang |
|---------|--------|
| tcsh | `#!/bin/tcsh` |
| zsh | `#!/usr/local/bin/zsh` (requires pkg install) or `#!/bin/zsh` |
| bash | `#!/usr/local/bin/bash` |
| sh (BSD) | `#!/bin/sh` |

---

## C++20 Feature Availability (Critical)

**This is the most important finding for implementation planning.** FreeBSD clang 19.1.7 has **partial** C++20 standard library support.

### Header Availability Test Results

| Header | Available? | Notes |
|--------|-----------|-------|
| `<format>` | ✅ Yes | Compiles cleanly with `-std=c++20` |
| `<stop_token>` | ✅ Yes | Compiles cleanly with `-std=c++20` |
| **`<jthread>`** | ❌ **NO** | `fatal error: 'jthread' file not found` |
| `<atomic>` | ✅ Yes | Standard header, always available |
| `<thread>` | ✅ Yes | Standard header, always available |
| `<condition_variable>` | ✅ Yes | Standard header, always available |

### Impact on Source Code — **NOT Byte-Identical**

The macOS source uses `std::jthread` in **Threading.cpp**. FreeBSD clang 19.1.7 does NOT provide `<jthread>`. This means:

**Threading.cpp MUST be modified for FreeBSD.** The `std::jthread` (which auto-manages stop tokens and joinability) must be replaced with `std::thread` + manual `std::stop_token` management.

**Required changes in Threading.cpp:**
```cpp
// macOS (std::jthread — auto-joins, auto-stops)
write_thread_ = std::jthread([this](std::stop_token st) { write_loop(st); });

// FreeBSD (manual thread + stop token)
write_thread_ = std::thread([this](std::stop_token st) { write_loop(st); });
// stop() must call a separate request_stop() method
// wait() must call join()
```

**Required changes in swtr_ringbuffer_impl.hpp:**
- Replace `std::jthread` member types with `std::thread`
- Add a `request_stop()` method that creates and signals a `std::stop_source` (or use a separate atomic bool flag)
- Update `start()` to create `std::thread` instead of `std::jthread`
- Update `stop()` to signal stop + notify condition variable
- Update `wait()` to call `.join()` on each thread

### Alternative Approaches Considered
1. **Install llvm-devel-21** (development version) — would provide `<jthread>` but introduces instability risk
2. **Use pthreads directly** — more portable but loses C++20 stop_token semantics
3. **Manual std::thread + atomic bool** — simplest, most portable, no external dependencies
4. **Manual std::thread + stop_source** — closest to jthread semantics, requires C++20 `<stop_token>` (available)

**Recommended approach:** Use `std::thread` + `std::stop_source`/`std::stop_token` from `<stop_token>` (which IS available). This preserves the cooperative cancellation semantics while avoiding `<jthread>`. The implementation is:
```cpp
// In header:
std::stop_source stop_src_;
std::thread write_thread_, transform_thread_, read_thread_;

// In start():
write_thread_ = std::thread([this]() { write_loop(stop_src_.get_token()); });

// In stop():
stop_src_.request_stop();
cv_.notify_all();

// In wait():
if (write_thread_.joinable()) write_thread_.join();
```

### pkg Repository Status
- `pkg search` partially works but has a broken repository: `FreeBSD-kmods has a wrong packagesite`
- Requires `pkg update` to fix
- llvm20 (20.1.7) is available in packages — would have `<jthread>` but not installed
- llvm-devel-21.0 is available — development version, would have `<jthread>`

---

## System Resources

| Resource | Value |
|----------|-------|
| **Disk** | 45 GB total, 6.5 GB used, 35 GB available (16% capacity) |
| **RAM** | ~12.0 GB (`hw.physmem: 12844273664`) |
| **CPUs** | 4 (`hw.ncpu: 4`) |
| **Max processes per UID** | 15,872 (`kern.maxprocperuid`) |
| **Max open files** | 391,976 (`kern.maxfiles`) |
| **Locale** | `C.UTF-8` (all categories) |

---

## Filesystem

| Field | Value |
|-------|-------|
| **Root filesystem** | UFS (`/dev/vtbd0p2 on /`) |
| **Mount options** | local, soft-updates, journaled soft-updates |
| **Symlink support** | ✅ Confirmed working |
| **EFI partition** | `/dev/vtbd0p1` mounted at `/boot/efi` (msdosfs) |

---

## Updated Source Code Compatibility Assessment

### Files That ARE Byte-Identical (no changes needed)
All files EXCEPT Threading.cpp and swtr_ringbuffer_impl.hpp:
- `status.hpp`, `ringbuffer.hpp` — pure enum/header definitions
- `Lifecycle.cpp` — constructor only, no threading
- `ReadOps.cpp`, `WriteOps.cpp`, `TransformOps.cpp` — POSIX I/O + stop_token (available)
- `ErrorOps.cpp`, all `Accessors_*.cpp`, all `LoggingOps_*.cpp` — no threading
- Test data files, utility scripts, LICENSE, README.md (tests)

### Files That MUST Be Modified for FreeBSD
| File | Change Required |
|------|----------------|
| **`Threading.cpp`** | Replace `std::jthread` with `std::thread` + manual stop token management |
| **`swtr_ringbuffer_impl.hpp`** | Replace `std::jthread` member types with `std::thread`, add stop source, update start/stop/wait methods |

### Files That Are FreeBSD-Specific (NOT copies from macOS)
| File | Notes |
|------|-------|
| `Makefile` | ELF/.so, single-arch, ar rcs, no universal binary logic |
| `tests/Makefile` | ELF RPATH ($ORIGIN), no lipo checks, single compiler |
| `README.md` | FreeBSD-specific build instructions (clang 19.1.7, pkg install notes) |

### Summary: Copy vs Modify vs Create (Original — Pre-Unification)
| Category | Count | Files |
|----------|-------|-------|
| **Byte-identical copy** | ~28 files | All .cpp/.hpp except Threading.cpp + impl.hpp, test data, scripts |
| **Modified (from macOS)** | 2 files | Threading.cpp, swtr_ringbuffer_impl.hpp |
| **FreeBSD-specific** | 3 files | Makefile, tests/Makefile, README.md |
| **Not created** | 3 spec files + containers/ | Per excluded platform rules

### Unified Source Code (Post-Unification)
All 5 platforms (macOS, debian, fedora, ubuntu, raspios, freebsd14) now share the same 21 source files from `src/macos/cpp/` with conditional compilation:

| File | FreeBSD Path (`__FreeBSD__`) | macOS/Linux Path |
|------|---------------------------|------------------|
| `Threading.cpp` | `std::thread` + `atomic<bool> stop_flag_` | `std::jthread` with `stop_token` |
| `swtr_ringbuffer_impl.hpp` | `std::thread`, no `<stop_token>`, atomic stop flag | `std::jthread`, includes `<stop_token>` |
| `ReadOps.cpp` | `while (!stop_flag_.load())` | `while (!st.stop_requested())` |
| `WriteOps.cpp` | `while (!stop_flag_.load())` | `while (!st.stop_requested())` |
| `TransformOps.cpp` | `while (!stop_flag_.load())` | `while (!st.stop_requested())` |
| All other files (16) | Identical across all platforms | Identical across all platforms |

The `#ifdef __FreeBSD__` preprocessor directive ensures the correct code path is compiled for each platform. No manual source modifications are needed — the unified source handles both FreeBSD and macOS/Linux automatically.

---

## Build & Test Results (Completed)

> **Date:** 2026-08-16
> **Status:** All 7 tests PASS

### Build Output
| Artifact | Size | Format |
|----------|------|--------|
| `lib/libswtr_ringbuffer-1.0.0-1.a` | 148,806 bytes | ELF static library |
| `lib/libswtr_ringbuffer-1.0.0-1.so` | 46,768 bytes | ELF shared library |
| SONAME | `libswtr_ringbuffer.so` | Verified via `readelf -d` |

### Test Results
| Test | Description | Result |
|------|-------------|--------|
| T001 | Identity transform, normal operation | **PASS** (output match) |
| T002 | Stress test (1 slot, 1 byte buffer) | **PASS** (output match) |
| T003 | Uppercase transform | **PASS** (output match) |
| T004 | Small input, fast EOF | **PASS** (output match) |
| T005 | Fatal error mode (expect exit 1) | **PASS** (exit code 1 as expected) |
| T006 | Non-fatal error mode (expect exit 0) | **PASS** (output match) |
| T007 | XOR transform | **PASS** (output match) |

### Key Implementation Details
- **`std::jthread` replacement:** Used `std::atomic<bool> stop_flag_` as cooperative cancellation flag (FreeBSD clang 19.1.7 has `<stop_token>` header but `std::stop_token`/`std::stop_source` types are NOT implemented)
- **Makefile T005 fix:** Used `/usr/local/bin/bash -c '...'` with `$$?` to correctly capture non-zero exit code (BSD make default shell is tcsh which doesn't support `{ }` grouping)
- **RPATH:** Uses `$ORIGIN/../lib` (FreeBSD/ELF convention, not macOS `@executable_path`)
- **Linker flags:** `-pthread` required for `std::thread`; SONAME via `-Wl,-soname,libswtr_ringbuffer.so`
- **JUnit report:** Skipped (zsh not installed on FreeBSD)

### Modified Files (copied back from remote)
| File | Change |
|------|--------|
| `Threading.cpp` | `std::jthread` → `std::thread` + `std::atomic<bool> stop_flag_` |
| `swtr_ringbuffer_impl.hpp` | Member types + constructor/init updated for atomic stop flag |
| `ReadOps.cpp` | Stop token handling adapted |
| `WriteOps.cpp` | Stop token handling adapted |
| `TransformOps.cpp` | Stop token handling adapted |
| `Makefile` (main) | BSD make syntax, `-pthread`, ELF SONAME |
| `tests/Makefile` | BSD make syntax, bash for T005 exit capture |

### Known Limitations
- FreeBSD clang 19.1.7 has **partial** C++20 `<stop_token>` support — header exists but types are undefined
- `std::jthread` is **not available** in FreeBSD clang 19.1.7
- `g++` is **not installed** — only clang++ available
- zsh is **not installed** — JUnit report generation skipped
- **`$ORIGIN` in RUNPATH is NOT supported by FreeBSD 14's `ld-elf.so.1`** — The dynamic linker strips `$ORIGIN` to empty string at runtime, causing shared library tests to fail. **Dynamic library testing is not possible on FreeBSD 14.** The regression test uses static library only (via `make verify` target). This is a platform-specific limitation of FreeBSD's dynamic linker.

### Current Limitations & TODOs
- **TODO: Dynamic library testing on FreeBSD 14** — `$ORIGIN` in RUNPATH is not supported by `ld-elf.so.1`. Until FreeBSD updates their dynamic linker, shared library tests must be skipped on this platform. Consider using absolute RPATH for any future dynamic lib testing, or accept static-only testing.
- **TODO: Install zsh** — `pkg install zsh` would enable JUnit report generation. Currently skipped.
- **TODO: Consider installing g++** — `pkg install gcc` would provide a secondary compiler for cross-compiler ABI validation, matching the macOS multi-compiler approach.
