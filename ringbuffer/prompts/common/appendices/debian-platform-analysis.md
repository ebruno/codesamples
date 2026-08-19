# Debian Platform Analysis

> **Purpose:** Reference data for ringbuffer implementation on Debian.
>
> **System Access:** Container (`container` on macOS host, `podman` on Linux hosts)
> **Collected:** 2026-08-18

---

## System Information

| Field | Value |
|-------|-------|
| **OS** | Debian GNU/Linux 13 (trixie) |
| **Version** | 13.6 |
| **Architecture** | arm64 (aarch64) in containers |
| **Kernel** | 6.18.15 |
| **Default user shell** | Bash (GNU bash 5.2.37) |
| **System shell (`/bin/sh`)** | Dash (Debian Almquist Shell) |
| **libc** | GLIBC 2.41 |

---

## Shell Environment (Critical for Ringbuffer)

### Bash vs Dash — Debian's Dual-Shell Design

Debian uses two different shells depending on context:

| Context | Shell | Purpose |
|---------|-------|---------|
| **Interactive login** (user terminal) | Bash 5.2.37 | Default interactive shell for normal user accounts |
| **`/bin/sh`** (system scripts, Makefile recipes) | Dash | Default system shell — faster execution and strict POSIX compliance |

> **Why this matters:** When `make` runs recipes on Debian, it spawns `/bin/sh`, which is **Dash**, not Bash. Dash is a minimal POSIX-compliant shell — it does NOT support bashisms like `[[ ]]`, arrays, `${var,,}`, or process substitution `<()`.

### Reading Man Pages on Debian

To write a man page to a file without formatting (as plain text) on Debian, pipe the `man` output into the `col -b` command:

```bash
# Print clean output to screen
man <command> | col -b

# Save as a clean text file
man <command> | col -b > filename.txt

# Bypass the pager entirely (equivalent to cat)
man -P cat <command>
```

> **Why:** Debian man pages include formatting/control characters. `col -b` strips backspace-based formatting (bold, underline) to produce clean plain text output. Debian uses `man` 2.13.1 with groff/nroff (not mandoc).

### Dash vs Bash — Key Differences for Makefiles

| Feature | Dash (`/bin/sh` on Debian) | Bash (interactive 5.2) |
|---------|---------------------------|------------------------|
| **`[ ]` test** | Supported | Supported |
| **`[[ ]]` extended test** | ❌ Not supported | ✅ Supported |
| **`$(( ))` arithmetic** | Supported | Supported |
| **`(( ))` arithmetic** | ❌ Not supported | ✅ Supported |
| **Arrays** | ❌ Not supported | ✅ Supported |
| **Brace expansion `{a,b}`** | ❌ Not supported | ✅ Supported |
| **Process substitution `<()`** | ❌ Not supported | ✅ Supported |
| **`${var,,}` / `${var^^}`** | ❌ Not supported | ✅ Supported (Bash 4+) |
| **`2>&1` stderr redirect** | ✅ Supported | ✅ Supported |
| **`$?` exit code** | ✅ Supported | ✅ Supported |
| **Nested command substitution** | ✅ Works (simpler than Bash) | ✅ Works |

> **Critical for Makefiles:** Debian's `/bin/sh` is Dash, which is stricter than Bash. Use only POSIX constructs in Makefile recipes — no `[[ ]]`, no arrays, no `${var,,}`, no process substitution.

### Makefile Recipe Shell on Debian

```bash
# Check what /bin/sh points to on Debian
$ ls -la /bin/sh
lrwxrwxrwx 1 root root 4 Feb 4 2025 /bin/sh -> dash
```

> **Implication:** Makefile recipes on Debian run under Dash, NOT Bash. This is different from macOS (where `/bin/sh` is Bash 3.2 in POSIX mode) and FreeBSD (where `/bin/sh` is also ash/Dash).

---

## Host Environment (Container Target)

> **Date:** 2026-08-18
> **Purpose:** Container environment details for Debian — relevant for build configuration, resource allocation, and toolchain selection.

### Container Access from macOS Host

| Aspect | Value |
|--------|-------|
| **Container CLI** | `container` (Apple Container) — macOS native |
| **Docker** | ❌ Never used on macOS (golden rule) |
| **podman** | ❌ Never used on macOS (Linux hosts only) |

> **Important:** On macOS, always use `container` command. Never prepend `localhost/` to image names — the `container` CLI resolves images locally, and prepending `localhost/` forces a network lookup that times out.
> ```bash
> # CORRECT — resolves locally
> container run ringbuffer_debian_build:latest make all
> # WRONG — forces network lookup, times out
> container run localhost/ringbuffer_debian_build:latest make all
> ```

### Container Access from Linux Host

| Aspect | Value |
|--------|-------|
| **Container CLI** | `podman` (preferred) or Docker (Linux hosts only) |
| **Image names** | Standard — no `localhost/` prefix needed with podman either |

---

## Runtime Environment Detection

> **Purpose:** Determine whether the current execution context is a macOS host, Linux bare metal, or inside a container — so the correct container CLI can be selected.

### Detection Script (Recommended)

```bash
#!/bin/bash
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
| **Ubuntu** | `container` ✅ | May be available | May be available | ❌ Neither |
| **Raspios** | `container` ✅ | May be available | May be available | ❌ Neither |
| **Fedora** | `container` ✅ | ✅ Likely (native podman distro) | May be available | ❌ Neither |
| **Arch Linux** | `container` ✅ | ✅ Likely (native podman distro) | May be available | ❌ Neither |

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
## Toolchain (Debian Container — Actual Measured Values)

### C/C++ Compiler

| Aspect | Value |
|--------|-------|
| **GCC** | 14.2.0 (Debian 14.2.0-19) |
| **g++** | 14.2.0 (Debian 14.2.0-19) |
| **clang/clang++** | 19.1.7 (Debian clang 19.1.7, 3+b1) |
| **Thread model** | posix |
| **Standard library** | libstdc++ (GNU) — `/usr/lib/aarch64-linux-gnu/libstdc++.so.6.0.33` |
| **GLIBCXX version** | GLIBCXX_3.4.33 (highest) |
| **C++ headers** | `/usr/include/c++/14` |

> **Note:** Debian 13 (trixie) ships GCC 14.2 — much newer than the previously assumed Bookworm/GCC 12.

### GNU Make

| Aspect | Value |
|--------|-------|
| **Type** | GNU Make 4.4.1 |
| **Built for** | aarch64-unknown-linux-gnu |
| **Version query** | `make -v` ✅ works (unlike FreeBSD 14) |
| **Features** | Supports `$(shell ...)`, `ifeq/else`, `-jN` parallel jobs, etc. |

> **Note:** GNU Make 4.4.1 is significantly newer than macOS's GNU Make 3.81. All modern features are available.

### Package Manager

| Aspect | Value |
|--------|-------|
| **Tool** | `apt` / `apt-get` |
| **Update command** | `apt-get update` (refreshes package lists) |
| **Install command** | `apt-get install -y <package>` |

### Common Development Packages on Debian

| Package | Purpose |
|---------|---------|
| `build-essential` | GCC, g++, make, libc development headers |
| `clang` / `clang++` | LLVM/Clang C/C++ compiler (available via apt) |
| `python3` | Python 3.13.5 (Debian includes it by default) |
| `libstdc++-14-dev` | C++ standard library development files (installed) |

### Analysis Tools

| Tool | Location | Available? |
|------|----------|------------|
| `readelf` | `/usr/bin/readelf` | ✅ |
| `objdump` | `/usr/bin/objdump` | ✅ |
| `nm` | `/usr/bin/nm` | ✅ |
| `ar` | `/usr/bin/ar` | ✅ |
| `strip` | `/usr/bin/strip` | ✅ |
| `file` | `/usr/bin/file` | ✅ |

> **Note:** All standard ELF analysis tools are available on Debian. Unlike macOS, `readelf` works here (macOS uses `otool`).

---

## Platform-Specific Notes for Ringbuffer Implementation

### Shell & Makefile Compatibility (Debian Container)

| Aspect | Value |
|--------|-------|
| **Interactive shell** | Bash 5.2.37 (user login) |
| **Make recipe shell (`/bin/sh`)** | Dash — strict POSIX, no bashisms |
| **Make type** | GNU make 4.4.1 (supports `$(shell ...)`, `ifeq/else`) |

> **Critical:** Makefile recipes on Debian run under Dash (`/bin/sh` → `dash`). This is the most POSIX-compliant shell environment among all supported platforms. No bashisms of any kind — not even the limited ones that macOS's Bash 3.2 POSIX mode tolerates.

### Container Image Building (Debian)

```bash
# Build a Debian container image from macOS host
container build -t ringbuffer_debian_build:latest \
    --file src/debian/cpp/containers/Dockerfile.debian \
    .

# Run a build inside the container from macOS host
container run --rm -v $(pwd):/workspace ringbuffer_debian_build:latest \
    make all

# Run tests inside the container from macOS host
container run --rm -v $(pwd):/workspace ringbuffer_debian_build:latest \
    make test
```

> **Important:** Always omit `localhost/` prefix from image names when using the `container` CLI on macOS.

### LTO_FLAG — Both GCC and Clang Support `-flto=thin`

> **CORRECTION:** Unlike the previous assumption, both GCC 14.2 and Clang 19.1.7 on Debian support `-flto=thin`:
> - **GCC 14.2:** `echo "" | g++ -flto=thin -x c++ -` → error: unrecognized argument to '-flto=' option: 'thin'
>   - **GCC does NOT support `-flto=thin`** — use `-flto` only
> - **Clang 19.1.7:** `echo "" | clang++ -flto=thin -x c++ -` → compiles successfully (error only about missing main)
>   - **Clang DOES support `-flto=thin`**
>
> ```makefile
> # For GCC builds — use plain -flto (NOT -flto=thin)
> LTO_FLAG := -flto
> # For Clang builds — either works, but prefer -flto=thin for speed
> LTO_FLAG_CLANG := -flto=thin
> ```

### C++20 Header Availability — `<jthread>` NOT Available (Critical!)

| Header | GCC 14.2 | Clang 19.1.7 |
|--------|----------|---------------|
| `<format>` | ✅ OK | ✅ OK |
| `<stop_token>` | ✅ OK | ✅ OK |
| **`<jthread>`** | ❌ **NOT available** — `fatal error: jthread: No such file or directory` | ❌ **NOT available** — `'jthread' file not found` |

> **CRITICAL CORRECTION:** Debian 13 (trixie) with GCC 14.2 and Clang 19.1.7 does NOT provide `<jthread>`. This is the same limitation as FreeBSD 14.
>
> - `libstdc++-14-dev` is installed but does not include `<jthread>` header
> - `find / -name jthread` returns nothing — the header is not installed anywhere in the container
> - `dpkg -S jthread` returns nothing — no package provides it
>
> **Implication for ringbuffer:** Use `std::thread` + `atomic<bool>` stop flag instead of `std::jthread`. The same approach used for FreeBSD 14 applies here.

### RPATH on Debian (Linux)

Debian uses the standard Linux `$ORIGIN` convention for RUNPATH:

```bash
# On Debian — $ORIGIN works correctly in RUNPATH
$ readelf -d libswtr_ringbuffer.so | grep RUNPATH
  RUNPATH            0x... $ORIGIN/../lib
```

> **Key difference from FreeBSD 14:** Linux dynamic linker (`ld.so`) fully supports `$ORIGIN` in RUNPATH. This is why Concurrent tests work on Debian but are SKIPPED on FreeBSD 14 (where `ld-elf.so.1` strips `$ORIGIN`).

### Binary Format

| Aspect | Value |
|--------|-------|
| **Format** | ELF (Executable and Linkable Format) |
| **Shared lib extension** | `.so` |
| **Static lib extension** | `.a` |
| **Analysis tool** | `readelf`, `objdump`, `nm` |

### Container Resources (Measured)

| Resource | Value |
|----------|-------|
| **Memory** | 1.1 GB total (container limit) |
| **CPU cores** | 5 |
| **Disk** | 504 GB total, ~1.3 GB used (0.3%) |

> **Note:** Container has 1.1 GB RAM — sufficient for building but not generous. Set container memory limits accordingly from the macOS host.

---

## Comparison: Debian vs macOS vs FreeBSD 14 Toolchain

| Aspect | Debian (GCC 14.2) | macOS (Apple clang 21) | FreeBSD 14 (clang 19.1.7) |
|--------|-------------------|----------------------|--------------------------|
| **Compiler** | GCC 14.2 (default) or clang 19.1.7 | Apple clang (LLVM-based) | FreeBSD clang 19.1.7 |
| **Target** | aarch64-linux-gnu | arm64-apple-darwin / x86_64-apple-darwin | x86_64-unknown-freebsd14.4 |
| **Std Lib** | libstdc++ (GNU) 6.0.33 | libc++ (Apple) | libc++ (LLVM upstream) |
| **Binary format** | ELF | Mach-O | ELF |
| **Shared lib ext** | `.so` | `.dylib` | `.so` |
| **Install name/RPATH** | `$ORIGIN/../lib/...` ✅ works | `@executable_path/../lib/...` ✅ works | `$ORIGIN/../lib/...` ❌ stripped on FreeBSD 14 |
| **Make type** | GNU make 4.4.1 | GNU make 3.81 | BSD make (native only) |
| **Recipe shell** | `/bin/sh` → Dash (strict POSIX) | `/bin/sh` → Bash 3.2 POSIX mode | `/bin/sh` → ash (strict POSIX) |
| **Container support** | Docker/podman (Linux host only) or `container` (macOS only) | `container` command (Apple Container) | None (native-only) |
| **Make version query** | `make -v` ✅ | `make -v` ✅ | `make -V VERSION` only ❌ no `-v` |
| **C++20 `<format>`** | ✅ Yes (GCC 14, Clang 19) | ✅ Yes | ✅ Yes |
| **C++20 `<stop_token>`** | ✅ Yes (GCC 14, Clang 19) | ✅ Yes | ✅ Yes (partial — types undefined) |
| **`std::jthread`** | ❌ **NOT available** (same as FreeBSD 14) | ✅ Yes (full support) | ❌ **NOT available** |
| **LTO flag (GCC)** | `-flto` only (NOT `-flto=thin`) | N/A (Apple clang) | N/A |
| **LTO flag (Clang)** | `-flto=thin` ✅ supported | `-flto` or `-flto=thin` | `-flto` |
| **Dead code elim** | `-Wl,--gc-sections` | `-dead_strip` | `-Wl,--gc-sections` |
| **Analysis tools** | `readelf`, `objdump`, `nm` | `otool`, `lipo` | `readelf`, `objdump`, `nm` |
| **Python** | 3.13.5 | 3.14.6 (Homebrew) | N/A |

---

## Build & Test Considerations for Debian

### Makefile Recipe Patterns (Debian/Dash)

```makefile
# WORKING pattern for Debian — Dash-compatible POSIX shell syntax
.PHONY: test build

test:
	@echo "=== Running tests ==="
	PASS=0; FAIL=0; \
	for t in 1 2 3 4 5 6 7; do \
		RESULT=$$(echo 'test input' | python3 test.py $$t 2>&1); \
		EXIT=$$?; \
		echo "  T00$$t: $$RESULT"; \
		if [ $$EXIT -ne 0 ]; then FAIL=$$((FAIL+1)); else PASS=$$((PASS+1)); fi; \
	done; \
	echo "Results: $$PASS passed, $$FAIL failed"; \
	echo "`date '+%Y-%m-%d %H:%M:%S'` Tests: $$PASS/7 passed" >> logs/build.log
```

> **Dash-specific notes:**
> - No `[[ ]]` — use `[ ]` for all tests
> - No arrays — iterate with `for t in 1 2 3` instead of array indexing
> - No `${var,,}` — use `tr '[:upper:]' '[:lower:]'` for case conversion
> - No process substitution — use pipes or temp files instead

### Container Memory Limits (from macOS Host)

When running Debian containers from the macOS host, calculate memory limits:

```bash
# Get available memory for container allocation (run on macOS host)
vm_stat  # Shows page statistics
# Set container -m to 50% of available, capped at 3 GB
```

With **64 GB RAM** on the M4 Mac Mini, container memory limits can be generous (up to the 3 GB cap per container).

---

## Summary: Platform-Specific Gotchas for Agents

### Debian (Container Target)
1. **`/bin/sh` is Dash** — strict POSIX, no bashisms whatsoever (more restrictive than macOS's Bash 3.2 POSIX mode)
2. **GNU make 4.4.1** — `make -v` works, supports all standard features (unlike FreeBSD 14)
3. **Use `readelf`** — Debian uses ELF format (same as Linux, different from macOS Mach-O)
4. **RPATH `$ORIGIN` works** — fully supported by Linux dynamic linker (unlike FreeBSD 14)
5. **GCC: LTO_FLAG is `-flto`** — NOT `-flto=thin` (Debian GCC 14 does not support `--thin`)
6. **Clang: LTO_FLAG is `-flto=thin`** — Clang 19 supports `--thin`
7. **`<jthread>` NOT available** — use `std::thread` + `atomic<bool>` stop flag (same as FreeBSD 14)
8. **Container CLI** — use `container` on macOS host, `podman` on Linux hosts
9. **Never prepend `localhost/`** to image names with the `container` CLI on macOS
10. **Distinguish Debian from Raspberry Pi OS** — check for `/etc/rpi-issue`
11. **Man pages** — use `col -b` to strip formatting on Debian
12. **Default compiler** — GCC 14.2 (`g++`), not clang (though Clang 19 is available via apt)

### macOS (Reference for Comparison)
1. `/bin/sh` is Bash 3.2 in POSIX mode — limited bashisms tolerated
2. GNU make 3.81 — functional but older (no `$(realpath ...)`) — Debian has 4.4.1
3. Use `otool` not `readelf` — Mach-O format
4. RPATH uses `@executable_path` — fully supported
5. **`std::jthread` available** — full C++20 support (unlike Debian/FreeBSD)

### FreeBSD 14 (Reference for Comparison)
1. `/bin/sh` is ash — strict POSIX, no bashisms
2. BSD make only — `gmake` NOT allowed
3. Use `readelf` not `otool` — ELF format
4. RPATH `$ORIGIN` stripped by `ld-elf.so.1` — dynamic library testing NOT possible
5. No container support, no `std::jthread`
6. **Same `<jthread>` limitation as Debian** — both need `std::thread` + atomic bool

---

## Source Code Compatibility Assessment for Debian

### Byte-Identical (same as other Linux distros)
The following source files should be identical across all Linux distributions:
- `status.hpp` — pure enum definitions, no platform dependencies
- `ringbuffer.hpp` — uses standard C++20 headers (`<atomic>`, `<format>`, `<stop_token>`)
- `swtr_ringbuffer_impl.hpp` — implementation class header (with `#ifdef __FreeBSD__` guards)
- `Lifecycle.cpp`, `ReadOps.cpp`, `TransformOps.cpp` — standard C++20 + POSIX I/O
- `Accessors_*.cpp`, `LoggingOps_*.cpp` — standard C++20
- `ErrorOps.cpp`, `WriteOps.cpp` — uses `<unistd.h>` (POSIX, available on all platforms)
- `Makefile` — GNU make syntax, `$ORIGIN` RPATH, `-Wl,--gc-sections`, `.so` extension

### Platform-Specific Differences (vs FreeBSD 14)
| File | Debian/Linux | FreeBSD 14 |
|------|-------------|------------|
| `Threading.cpp` | `std::thread` + `atomic<bool>` stop flag (no `<jthread>`) | `std::thread` + `atomic<bool>` stop flag |
| `swtr_ringbuffer_impl.hpp` | No `<jthread>`, atomic stop flag | No `<jthread>`, atomic stop flag |
| `Makefile` | GNU make, `-Wl,--gc-sections`, `.so`, `$ORIGIN` RPATH | BSD make, `-Wl,--gc-sections`, `.so`, `$ORIGIN` stripped |
| `tests/Makefile` | GNU make syntax, `readelf` for verification | BSD make syntax, `readelf` for verification |

> **CORRECTION:** Debian does NOT have `<jthread>` — same as FreeBSD 14. Both use `std::thread` + atomic bool stop flag.

> **Cross-platform symmetry:** Debian source code should be byte-identical to Fedora, Ubuntu, and other Linux distributions (platform-insensitive for C/C++ source). Only Makefile-level differences are expected (container image name, working directory path, distro detection check).
