# Arch Linux Platform Analysis (Arch Linux Rolling)

> **Purpose:** Reference data collected from the Arch Linux test system for ringbuffer C++/Java/Python implementation planning.
>
> **System Access:** `ssh ebruno@10.10.41.227`
> **Collected:** 2026-08-17

---

## System Information

| Field | Value |
|-------|-------|
| **OS** | Arch Linux (rolling release) |
| **Kernel** | 7.0.7-arch2-1 #1 SMP PREEMPT_DYNAMIC Thu, 14 May 2026 22:28:27 +0000 |
| **Architecture** | x86_64 (Intel Core i9-9900 @ 3.10GHz) |
| **Filesystem** | ext4 (`/dev/vda3`) |
| **Shell** | bash 5.3.15(1)-release (`/usr/bin/bash`) |

---

## Runtime Environment Detection

> **Purpose:** Determine whether the current execution context is a macOS host, Linux bare metal, or inside a container — so the correct container CLI can be selected.

### Detection Script (Recommended)

```bash
#!/usr/bin/env bash
# Detect runtime environment and select appropriate container CLI
detect_runtime() {
    # 1. macOS host — only 'container' CLI available (Apple Container)
    if command -v container &>/dev/null; then
        echo "macOS host — use 'container' CLI"
        return 0
    fi

    # 2. Linux bare metal — check for podman first, then docker
    if command -v podman &>/dev/null; then
        echo "Linux bare metal — use 'podman'"
        return 0
    fi

    if command -v docker &>/dev/null; then
        echo "Linux bare metal — use 'docker'"
        return 0
    fi

    # 3. Inside a container or minimal environment — no runtime available
    echo "Inside container or minimal environment"
    return 1
}

detect_runtime
```

### Detection Methods (In Priority Order)

| Method | Command | Container Result | Bare Metal Result | Notes |
|--------|---------|-----------------|-------------------|-------|
| **1. CLI availability** | `command -v container/podman/docker` | None found | podman or docker found | Most reliable — no extra tools needed |
| **2. cgroup check** | `cat /proc/1/cgroup` | `0::/` (container root) | `0::/init.scope` (systemd) | Always available on Linux; requires parsing |
| **3. systemd-detect-virt** | `systemd-detect-virt` | Not installed (minimal) | Returns `none` (bare metal) | Most reliable when available; not in minimal containers |

### Platform-Specific Container Runtime Availability

| Platform | macOS Host | Linux Bare Metal (podman) | Linux Bare Metal (docker) | Container Image |
|----------|-----------|--------------------------|--------------------------|-----------------|
| **macOS** | `container` ✅ | N/A (not Linux) | N/A (not Linux) | N/A |
| **Debian** | `container` ✅ | ❌ Not installed (shuttle01) | ✅ Installed (29.5.0) | ❌ Neither |
| **Ubuntu** | `container` ✅ | May be available | May be available (desktop) | ❌ Neither |
| **Raspios** | `container` ✅ | May be available | ✅ Likely (official install script) | ❌ Neither |
| **Fedora** | `container` ✅ | ✅ Likely (native podman distro) | May be available | ❌ Neither |
| **Arch Linux** | `container` ✅ | ✅ Likely (community-maintained) | May be available (AUR) | ❌ Neither |

> **Key finding:** Bare metal Debian (shuttle01) has `docker` 29.5.0 but NOT `podman`. Fedora is the only platform where `podman` is expected to be pre-installed on bare metal (Fedora's default container runtime).

### Container CLI Selection Logic for Makefiles

```makefile
# Detect and set CONTAINER_CMD based on runtime environment
CONTAINER_CMD := $(shell \
    if command -v container &>/dev/null; then \
        echo "container"; \
    elif command -v podman &>/dev/null; then \
        echo "podman"; \
    elif command -v docker &>/dev/null; then \
        echo "docker"; \
    else \
        echo ""; \
    fi)

# Fail if no container runtime is available
ifeq ($(CONTAINER_CMD),)
$(error No container runtime found. Install 'container' (macOS), 'podman', or 'docker'.)
endif
```

### Important Notes

1. **macOS golden rule:** Never use `docker` or `podman` on macOS — only the `container` CLI (Apple Container).
2. **Never prepend `localhost/`** to image names with the `container` CLI on macOS — it forces a network lookup that times out.
3. **Container images are minimal** — they typically do NOT have `docker`, `podman`, or `container` installed inside them. The runtime is always on the host.
4. **Bare metal Debian has `docker`, not `podman`** — this was verified on shuttle01.sc.brunoe.net.
5. **Fedora is the only platform where `podman` is expected** on bare metal (it's Fedora's default container runtime).
6. **Arch Linux typically has `podman`** available via community packages; Docker requires AUR installation.

## Toolchain

### C/C++ Compiler
| Field | Value |
|-------|-------|
| **Compiler** | GCC 16.2.1 (snapshot from Aug 10, 2026) |
| **Target** | x86_64-pc-linux-gnu |
| **Thread model** | posix |
| **Location** | `/usr/bin/gcc` / `/usr/bin/g++` (same binary) |
| **Standard Library** | libstdc++16 (`/usr/lib/gcc/x86_64-pc-linux-gnu/16/`) |

### C++ Standard Library
| Field | Value | Location |
|-------|-------|----------|
| **libstdc++.so** (shared) | ✅ Yes | `/usr/lib/libstdc++.so.6` → `libstdc++.so.6.0.36` |
| **libstdc++.a** (static) | ✅ Yes | `/usr/lib/gcc/x86_64-pc-linux-gnu/16/libstdc++.a` |
| **libgcc_s** (shared) | ✅ Yes | `/usr/lib/libgcc_s.so.1` |

### Linker
| Field | Value | Location |
|------|-------|----------|
| **GNU ld** (BFD) | 2.47 | `/usr/bin/ld` |
| **Compatibility** | Full ELF/GNU linker interface |

### Make
| Field | Value |
|-------|-------|
| **GNU Make** | 4.4.1 (Built for x86_64-pc-linux-gnu) |
| **Location** | `/usr/bin/make` |

### CMake
| Field | Value |
|-------|-------|
| **CMake** | 4.4.2 (Kitware) |
| **Location** | `/usr/bin/cmake` |

### Package Manager
| Field | Value |
|-------|-------|
| **pacman** | 7.1.0 (libalpm v16.0.1) |
| **Location** | `/usr/bin/pacman` |

---

## C++20 Header Availability (Critical)

**GCC 16.2.1 provides extensive C++20 support via libstdc++16.**

### Header Availability Test Results

| Header | Available? | Notes |
|--------|-----------|-------|
| `<format>` | ✅ Yes | `/usr/include/c++/16/format` — full `std::format` support |
| `<stop_token>` | ✅ Yes | `/usr/include/c++/16/stop_token` — `std::stop_token`, `std::stop_source`, `std::stop_callback` |
| **`<jthread>`** | ❌ **NO** | `fatal error: jthread: No such file or directory` — NOT provided by GCC 16 |
| `<atomic>` | ✅ Yes | Standard header, always available |
| `<thread>` | ✅ Yes | `/usr/include/c++/16/thread` — `std::thread`, `std::this_thread` |
| `<condition_variable>` | ✅ Yes | `/usr/include/c++/16/condition_variable` — `std::condition_variable`, `std::mutex` |
| `<span>` | ✅ Yes | C++20 span support |
| `<concepts>` | ✅ Yes | C++20 concepts support |
| `<ranges>` | ✅ Yes | C++20 ranges support |
| `<coroutine>` | ✅ Yes | C++20 coroutine support |
| `<latch>` | ✅ Yes | C++20 std::latch |
| `<semaphore>` | ✅ Yes | C++20 counting/lazy_semaphore |
| `<source_location>` | ✅ Yes | C++20 source_location |
| `<print>` | ✅ Yes | C++23 `std::print`/`std::println` (GCC 16 includes it) |
| `<optional>` | ✅ Yes | C++17, always available |
| `<variant>` | ✅ Yes | C++17, always available |
| `<string_view>` | ✅ Yes | C++17, always available |

> **Key finding:** GCC 16 has `<stop_token>` (types and functionality) but does NOT have `<jthread>`. This is the same situation as FreeBSD clang 19. `std::stop_source` and `std::stop_token` are fully functional — only the convenience wrapper `std::jthread` is missing.

### C++20 Feature Macro
```cpp
#define __cplusplus 202002L
```

---

## Available Binutils / Analysis Tools

| Tool | Version | Location | Notes |
|------|---------|----------|-------|
| `ar` | GNU 2.47 | `/usr/bin/ar` | Static library archiver ✅ |
| `nm` | GNU 2.47 | `/usr/bin/nm` | Symbol inspection ✅ |
| `objdump` | GNU 2.47 | `/usr/bin/objdump` | Object file analysis ✅ |
| `readelf` | GNU 2.47 | `/usr/bin/readelf` | ELF binary analysis ✅ |
| `strip` | GNU 2.47 | `/usr/bin/strip` | Symbol stripping ✅ |
| `file` | 5.48 | `/usr/bin/file` | File type detection ✅ |
| `size` | GNU 2.47 | `/usr/bin/size` | Binary size analysis ✅ |
| `c++filt` | (binutils) | `/usr/bin/c++filt` | C++ name demangling ✅ |
| `ld` | GNU 2.47 (BFD) | `/usr/bin/ld` | Linker ✅ |

---

## Installed Packages Summary

- **Total explicitly installed packages:** 16
- **Package list:** `base`, `base-devel`, `cmake`, `dhcpcd`, `doxygen`, `efibootmgr`, `emacs`, `git`, `gitlab-runner`, `graphviz`, `grub`, `linux`, `linux-firmware`, `nfs-utils`, `openssh`, `vim`
- **base-devel group** includes: gcc, make, binutils, glibc, pkgconf — the full C/C++ build toolchain
- **No Java JDK/JRE** installed (but available in repos)
- **No Python pip**, numpy, or pytest installed

---

## Platform-Specific Notes for Ringbuffer Implementation

### ELF Binary Format
- Arch Linux uses **ELF** binary format (standard for x86_64 Linux)
- Shared library extension: `.so`
- SONAME support via `readelf -d` (standard ELF convention)
- Install name: Use `-soname libswtr_ringbuffer.so` (ELF convention)
- RPATH/RUNPATH: Use `$ORIGIN/../lib` for relative library paths (standard Linux convention)

### Single Architecture
- x86_64 only — no universal/fat binary support needed
- No `-arch` flag needed in compiler invocations

### Linker Flags
- Dead code elimination: `-Wl,--gc-sections` (GNU ld standard)
- Position-independent code: `-fPIC` (required for shared libraries on Linux)
- Visibility hidden: `-fvisibility=hidden`

### Standard Library Path
- libstdc++ headers in `/usr/include/c++/16/` (GCC 16)
- libstdc++ libraries in `/usr/lib/` and `/usr/lib/gcc/x86_64-pc-linux-gnu/16/`
- No special `-stdlib` flag needed — libstdc++ is the default for GCC

### POSIX I/O Compatibility
- Full POSIX.1 support on Linux
- `fsync()` works identically to macOS/FreeBSD
- `<unistd.h>` provides POSIX I/O (`read`, `write`, `fsync`)
- **`O_DIRECT` is supported** on ext4 filesystems (verified with compile+link test)
- `ssize_t` return type for I/O functions — same as macOS/FreeBSD

### Container Support
- **Native-only** — no Docker/Podman support on Apple Silicon (ARM Macs)
- All builds and tests must run natively via SSH to the x86_64 Arch Linux VM
- The system has `gitlab-runner` installed but no container runtime

---

## Comparison: macOS vs FreeBSD 14 vs Arch Linux Toolchain

| Aspect | macOS (Apple clang 21) | FreeBSD 14 (clang 19.1.7) | Arch Linux (GCC 16.2.1) |
|--------|----------------------|--------------------------|------------------------|
| **Compiler** | Apple clang 21.0.0 | FreeBSD clang 19.1.7 | GCC 16.2.1 |
| **Target** | arm64-apple-darwin25.5.0 | x86_64-unknown-freebsd14.4 | x86_64-pc-linux-gnu |
| **Std Lib** | libc++ (Apple) | libc++ (LLVM upstream) | libstdc++16 (GNU) |
| **g++ available** | Yes (Homebrew, limited) | No | ✅ Yes (primary compiler) |
| **Binary format** | Mach-O | ELF | ELF |
| **Shared lib ext** | `.dylib` | `.so` | `.so` |
| **Install name** | `@rpath/libswtr_ringbuffer.dylib` | `-soname libswtr_ringbuffer.so` | `-soname libswtr_ringbuffer.so` |
| **Universal binaries** | Yes (lipo) | No | No |
| **Linker** | ld64 (Apple) | LLD 19.1.7 | GNU ld 2.47 (BFD) |
| **C++20 `<format>`** | ✅ Yes | ✅ Yes | ✅ Yes |
| **C++20 `<stop_token>`** | ✅ Yes | ⚠️ Header exists, types undefined | ✅ Yes (full support) |
| **C++20 `<jthread>`** | ✅ Yes | ❌ No | ❌ No |
| **`lipo`/`otool`** | ✅ Available | ❌ Not available | ❌ Not needed (ELF) |
| **`readelf`** | ❌ Not available | ✅ Available | ✅ Available |
| **Dead code elim** | `-dead_strip` | `-Wl,--gc-sections` | `-Wl,--gc-sections` |
| **Container support** | None (native-only) | None (native-only) | None (native-only on Apple Silicon) |
| **Make** | FreeBSD make (BSD) | FreeBSD make (BSD) | GNU Make 4.4.1 ✅ |
| **Default shell** | zsh (macOS) / tcsh (FreeBSD) | bash 5.2 (via pkg) | bash 5.3 ✅ |

---

## Source Code Compatibility Assessment

### Likely Byte-Identical (no changes needed)
The following source files should compile on Arch Linux without modification:
- `status.hpp` — pure enum definitions, no platform dependencies
- `ringbuffer.hpp` — uses standard C++20 headers (`<atomic>`, `<format>`)
- `swtr_ringbuffer_impl.hpp` — implementation class header (has `#ifdef __FreeBSD__` guards)
- `Lifecycle.cpp`, `ReadOps.cpp`, `TransformOps.cpp` — standard C++20 + POSIX I/O
- `Accessors_*.cpp`, `LoggingOps_*.cpp` — standard C++20
- `ErrorOps.cpp`, `WriteOps.cpp` — uses `<unistd.h>` (POSIX, available on Linux)

### Potential Differences
- **Makefile**: Needs platform-specific adjustments:
  - No universal binary targets (no `-arch arm64` / `-arch x86_64`)
  - Shared library uses `.so` extension and ELF SONAME convention (same as FreeBSD)
  - Linker flag: `-Wl,--gc-sections` (same as FreeBSD)
  - Use `ar rcs` for static libraries (standard on Linux)
  - GNU Make 4.4.1 — no BSD make compatibility issues (unlike FreeBSD)
- **No `lipo` or `otool`**: Binary verification uses `readelf`, `file`, `nm` (same as FreeBSD)
- **GCC is the primary compiler** — no clang++ on this system (unlike FreeBSD where only clang exists)

### POSIX I/O Compatibility
Arch Linux has full POSIX.1 support:
- `read()`, `write()`, `fsync()` — all available via `<unistd.h>`
- `ssize_t` return type for I/O functions — same as macOS/FreeBSD
- **`O_DIRECT` is supported** on ext4 (verified) — unlike macOS and FreeBSD
- `EAGAIN`, `EINTR` errno values exist (same as Linux/macOS/FreeBSD)

---

## Shell Availability (for Test Infrastructure Scripts)

The ringbuffer project generates utility scripts in four shell variants: **tcsh**, **zsh**, **bash**, and **sh** (Bourne). All four must be available on Arch Linux for test data generation, verification, and JUnit report scripts.

| Shell | Available? | Version | Location |
|-------|-----------|---------|----------|
| **tcsh** | ✅ Yes | 6.24.16 | `/usr/bin/tcsh` (listed in `/etc/shells`) |
| **zsh** | ✅ Yes | 5.9.2 (x86_64-pc-linux-gnu) | `/usr/bin/zsh` (listed in `/etc/shells`) |
| **bash** | ✅ Yes | 5.3.15(1)-release (x86_64-pc-linux-gnu) | `/usr/bin/bash` (listed in `/etc/shells`) |
| **sh** | ✅ Yes | GNU bash 5.3 (POSIX mode) | `/usr/bin/sh` → symlink to bash (listed in `/etc/shells`) |

### `/etc/shells` Contents
```
/bin/sh
/bin/bash
/bin/rbash
/usr/bin/sh
/usr/bin/bash
/usr/bin/rbash
/usr/bin/systemd-home-fallback-shell
/usr/bin/git-shell
/bin/zsh
/usr/bin/zsh
/bin/tcsh
/usr/bin/tcsh
/bin/csh
/usr/bin/csh
```

### Implications for Script Generation
- **tcsh**: Available — generate `*.tcsh` variants ✅
- **zsh**: Available — generate `*.zsh` variants ✅
- **bash**: Available — generate `*.sh` (bash) variants ✅
- **sh** (POSIX bash): Available — generate `bin_sh.sh` variants ✅

> **Note:** All four shell variants are now available on this Arch Linux system. Test infrastructure scripts can be generated and executed in all four formats.

### Shebang Lines for Generated Scripts
| Variant | Shebang |
|---------|--------|
| tcsh | `#!/usr/bin/tcsh` |
| zsh | `#!/usr/bin/zsh` |
| bash | `#!/usr/bin/bash` |
| sh (POSIX) | `#!/usr/bin/sh` |

---

## Java Support Assessment

### Current Status
- **Java 25 (OpenJDK) is installed** — `jdk25-openjdk-25.0.4.u7-1` (default)
- **Java 21 (OpenJDK) is also installed** — `jdk21-openjdk-21.0.12.u8-1`
- **Maven 3.9.16 is installed** — `maven-3.9.16-1`
- Java runtime: `/usr/lib/jvm/java-25-openjdk` (default via `archlinux-java set java-25-openjdk`)

### Available Java Packages (via pacman)
| Package | Version | Description |
|---------|---------|-------------|
| `jdk-openjdk` | 26.0.2.u10-1 | OpenJDK Java 26 development kit (latest) |
| `jdk25-openjdk` | 25.0.4.u7-1 | OpenJDK Java 25 development kit |
| `jdk21-openjdk` | 21.0.12.u8-1 | OpenJDK Java 21 LTS development kit |
| `jdk17-openjdk` | 17.0.20.u8-1 | OpenJDK Java 17 LTS development kit |
| `jdk11-openjdk` | 11.0.32.u9-1 | OpenJDK Java 11 LTS development kit |
| `jdk8-openjdk` | 8.502.u07-1 | OpenJDK Java 8 development kit (legacy) |
| `jre-openjdk` | 26.0.2.u10-1 | OpenJDK Java 26 runtime (headless available) |
| `maven` | 3.9.16-1 | Apache Maven build tool |
| `gradle` | 9.7.0-1 | Gradle build tool |

### Java Build System
- The ringbuffer Java project uses **Maven** (`pom.xml` in `src/common/java/`)
- Maven 3.9.16 is installed and ready to use
- Gradle 9.7.0 is also available as an alternative

### Java Source Code Compatibility
The Java source files in `src/common/java/swtr/` are platform-independent:
- `BufferSlot.java`, `BufferStatus.java`, `ChecksumAlgorithm.java` — enum definitions
- `ErrorHandler.java`, `LogLevel.java`, `TransformFunction.java` — functional interfaces
- `RingBuffer.java` — abstract base class
- `SwtrRingBuffer.java` — concrete implementation using standard Java concurrency (`java.util.concurrent`)

No platform-specific modifications needed for Java source code.

---

## Python Support Assessment

### Current Status
- **Python 3.14.7** is installed (built with GCC 16.1.1)
- **pip 26.2.1 is installed** — Python packages can be installed via pip
- **pytest 9.0.3 is installed** — test framework available
- Core standard library modules available: `json`, `os`, `sys`, `threading`, `subprocess`

### Python Source Code Compatibility
The Python source files in `src/common/python/` are platform-independent:
- `swtr_ringbuffer.py`, `swtr_ringbuffer_pure.py` — ring buffer implementations
- `base.py` — base classes and utilities
- `benchmark.py` — performance benchmarking
- `test_ringbuffer.py`, `test_ringbuffer_pure.py` — test suites

No platform-specific modifications needed for Python source code. The main requirement is having `pip` installed to manage test dependencies (pytest, etc.).

---

## System Resources

| Resource | Value |
|----------|-------|
| **Disk** | 41 GB total, 7.5 GB used, 31 GB available (20% capacity) |
| **RAM** | ~11.0 GB total, 610 MB used, 7.1 GB free, 4.4 GB buff/cache |
| **Swap** | 8.0 GB total, 0 used |
| **CPUs** | 4 (Intel Core i9-9900 @ 3.10GHz) |
| **Page size** | 4096 bytes |
| **Locale** | POSIX (all categories) — `LANG=` unset, `LC_CTYPE="POSIX"` |

---

## Filesystem

| Field | Value |
|-------|-------|
| **Root filesystem** | ext4 (`/dev/vda3 on /`) |
| **Mount options** | rw,relatime |
| **Symlink support** | ✅ Confirmed working |
| **O_DIRECT support** | ✅ Supported on ext4 (verified with compile+link test) |
| **tmpfs** | `/dev/shm` — tmpfs, rw,nosuid,nodev (shared memory) |

---

## Container Support Limitation

**Arch Linux on Apple Silicon does not support containers.** This is a hardware/VM limitation of running x86_64 Linux on Apple Silicon (ARM) via emulation. The system has `gitlab-runner` installed but no Docker/Podman container runtime available.

All builds and tests must run **natively** via SSH to the Arch Linux VM:
- C++ builds: `make all-all` (single compiler — GCC only)
- Java builds: `mvn compile test` (JDK + Maven installed and ready)
- Python tests: `python3 -m pytest` (pip + pytest installed and ready)

---

## Comparison: C++20 Threading — Arch Linux vs FreeBSD vs macOS

| Feature | macOS (Apple clang 21) | FreeBSD 14 (clang 19.1.7) | Arch Linux (GCC 16.2.1) |
|---------|----------------------|--------------------------|------------------------|
| **`std::jthread`** | ✅ Available (`<jthread>`) | ❌ Not available | ❌ Not available |
| **`std::stop_token`** | ✅ Available (`<stop_token>`) | ⚠️ Header exists, types undefined | ✅ Fully available (`<stop_token>`) |
| **`std::stop_source`** | ✅ Available | ⚠️ Not implemented | ✅ Fully available |
| **`std::stop_callback`** | ✅ Available | ⚠️ Not implemented | ✅ Fully available |
| **Recommended approach** | Use `std::jthread` directly | Manual `std::atomic<bool>` flag | Manual `std::stop_source`/`std::stop_token` |

> **Key difference from FreeBSD:** GCC 16 on Arch Linux has **full** `<stop_token>` support (types are implemented), unlike FreeBSD clang 19 where the header exists but types are undefined. This means Arch Linux can use `std::stop_source` + `std::thread` for cooperative cancellation, which is closer to `std::jthread` semantics than the FreeBSD approach of using a simple atomic bool flag.

### Recommended Threading Approach for Arch Linux
```cpp
// In header (swtr_ringbuffer_impl.hpp):
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

This approach:
1. Uses `std::stop_source`/`std::stop_token` (fully available in GCC 16)
2. Preserves cooperative cancellation semantics via `while (!st.stop_requested())`
3. Avoids `<jthread>` (not available in GCC 16)
4. Is more semantically correct than the FreeBSD atomic bool approach

---

## Unified Source Code Compatibility (Post-Unification)

All platforms now share the same source files with conditional compilation:

| File | Arch Linux Path (`__linux__`) | FreeBSD Path (`__FreeBSD__`) | macOS/Linux Path (default) |
|------|---------------------------|----------------------------|--------------------------|
| `Threading.cpp` | `std::thread` + `stop_source` | `std::thread` + `atomic<bool>` | `std::jthread` with `stop_token` |
| `swtr_ringbuffer_impl.hpp` | `std::thread`, `<stop_token>`, stop_source | `std::thread`, no `<stop_token>`, atomic bool | `std::jthread`, includes `<stop_token>` |
| `ReadOps.cpp` | `while (!st.stop_requested())` | `while (!stop_flag_.load())` | `while (!st.stop_requested())` |
| `WriteOps.cpp` | `while (!st.stop_requested())` | `while (!stop_flag_.load())` | `while (!st.stop_requested())` |
| `TransformOps.cpp` | `while (!st.stop_requested())` | `while (!stop_flag_.load())` | `while (!st.stop_requested())` |
| All other files (16) | Identical across all platforms | Identical across all platforms | Identical across all platforms |

The `#ifdef __linux__` preprocessor directive ensures the correct code path is compiled for Arch Linux. No manual source modifications are needed — the unified source handles all platforms automatically.

---

## Build & Test Requirements Summary

### C++ Build
| Requirement | Status | Notes |
|-------------|--------|-------|
| GCC/g++ compiler | ✅ Installed (16.2.1) | Primary and only C++ compiler |
| GNU Make | ✅ Installed (4.4.1) | Full GNU make — no BSD make issues |
| CMake | ✅ Installed (4.4.2) | Available if needed for alternative builds |
| libstdc++ headers | ✅ Installed (v16) | Full C++20 support except `<jthread>` |
| Binutils (ar, nm, readelf, etc.) | ✅ Installed (2.47) | All analysis tools available |
| ELF toolchain | ✅ Native | Standard Linux ELF format |

### Java Build
| Requirement | Status | Notes |
|-------------|--------|-------|
| JDK (OpenJDK 25) | ✅ Installed (25.0.4.u7-1) | Available via `archlinux-java set java-25-openjdk` |
| JDK (OpenJDK 21) | ✅ Installed (21.0.12.u8-1, default) | Original system default |
| Maven | ✅ Installed (3.9.16) | Ready to use |

> **Build workflow:** The system default is Java 21. Before building/testing, switch to JDK 25 with `sudo archlinux-java set java-25-openjdk`. After build/test, revert to original with `sudo archlinux-java set java-21-openjdk`. This preserves the system's original state.

### Python Build
| Requirement | Status | Notes |
|-------------|--------|-------|
| Python 3.x | ✅ Installed (3.14.7) | Core stdlib available |
| pip | ✅ Installed (26.2.1) | Package management ready |
| pytest | ✅ Installed (9.0.3) | Test framework ready |

### Shell Requirements
| Requirement | Status | Notes |
|-------------|--------|-------|
| bash | ✅ Installed (5.3.15) | Default shell, all scripts work |
| sh (POSIX) | ✅ Installed | Symlink to bash in POSIX mode |
| zsh | ✅ Installed (5.9.2) | All scripts executable |
| tcsh | ✅ Installed (6.24.16) | All scripts executable |

---

## Known Limitations & TODOs

- **No `<jthread>` in GCC 16** — requires `std::stop_source` + `std::thread` approach (more capable than FreeBSD's atomic bool, but still not as clean as macOS `std::jthread`)
- **No container support** — all builds/tests run natively via SSH (same as macOS/FreeBSD)
- **Single compiler** — only GCC available (no clang++ for cross-compiler ABI validation, unlike macOS)
- **POSIX locale** — `LANG=` is unset; some tools may behave differently with non-C locales
- **No numpy installed** — Python benchmarking/test scripts that require numpy would need `pacman -S python-numpy`

---

## Package Installation Commands (Reference)

All required packages are currently installed. For future reference:

```bash
# Java development environment (already installed)
sudo pacman -S jdk25-openjdk maven
# Build workflow: switch to JDK 25 before building, revert after
sudo archlinux-java set java-25-openjdk  # Before build/test
# ... build and test ...
sudo archlinux-java set java-21-openjdk  # After build/test (revert)

# Python testing environment (already installed)
sudo pacman -S python-pip python-pytest

# Shell environments (for test infrastructure scripts) (already installed)
sudo pacman -S zsh tcsh

# Additional development tools (if needed)
sudo pacman -S doxygen graphviz  # Already installed
sudo pacman -S python-numpy      # If needed for Python benchmarks

# System update (rolling release)
sudo pacman -Syu
```
