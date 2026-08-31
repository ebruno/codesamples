# Fedora Platform Analysis

> **Purpose:** Reference data for ringbuffer implementation on Fedora — shell behavior, toolchain, and platform-specific considerations.
>
> **System Access:** Container (`container` on macOS host, `podman` on Linux hosts)
> **Collected:** 2026-08-18

---

## System Information

| Field | Value |
|-------|-------|
| **OS** | Fedora Linux 44 (Forty Four) — Container Image |
| **Version ID** | 44 |
| **Release Type** | stable |
| **Architecture** | aarch64 (ARM64) in containers |
| **Kernel** | 6.18.15 (container) |
| **Default user shell** | Bash (GNU bash 5.3.9) |
| **System shell (`/bin/sh`)** | Bash in POSIX mode — `/bin/sh -> bash` |
| **libc** | glibc (Fedora default) |

> **Key difference from Debian/Ubuntu/Raspios:** Fedora's `/bin/sh` is a symbolic link to `bash`, NOT `dash`. When Bash is invoked as `/bin/sh`, it enters POSIX mode, which disables many extended Bash features but still supports more than dash/ash.

---

## Shell Environment (Critical for Ringbuffer)

### Bash as /bin/sh — Fedora's Unique Approach

Fedora uses a different approach than Debian-based systems:

| Context | Shell | Purpose |
|---------|-------|---------|
| **Interactive login** (user terminal) | Bash 5.3.9 | Default interactive shell for normal user accounts |
| **`/bin/sh`** (system scripts, Makefile recipes) | Bash in POSIX mode — `/bin/sh -> bash` | Default system shell |

> **Why this matters:** When `make` runs recipes on Fedora, it spawns `/bin/sh`, which is **Bash in POSIX mode**, not Dash. Bash in POSIX mode disables many extended features but still supports more than dash/ash (e.g., `[[ ]]`, arrays, `${var,,}`).

> **Key detail:** On Fedora (including Fedora 44), `/bin/sh` is a symbolic link to `/bin/bash`. However, when Bash is invoked as `sh`, it enters POSIX mode. This disables many extended Bash features, restricting execution strictly to the POSIX shell standard.

### Reading Man Pages on Fedora

To output a formatted man page to a file in Fedora, use the `man` command combined with `col -bx` to strip control characters:

```bash
# Print clean output to screen
man <command> | col -bx

# Save as a clean text file
man <command> | col -bx > manpage.txt

# Alternative: PDF output
man -Tpdf <command> > manpage.pdf

# Alternative: PostScript output
man -t <command> > manpage.ps
```

> **Why:** Fedora man pages include formatting/control characters. `col -bx` strips backspace-based formatting (bold, underline) and handles trailing spaces to produce clean plain text output. Fedora uses `man-db` (not mandoc).

> **Note:** The container image is minimal — `man` and `col` are not installed by default. Install with: `dnf install -y man-db bsdmainutils`

### Bash POSIX Mode vs Dash — Key Differences for Makefiles

| Feature | `/bin/sh` on Fedora (Bash POSIX mode) | Dash (`/bin/sh` on Debian/Ubuntu/Raspios) |
|---------|--------------------------------------|------------------------------------------|
| **`[ ]` test** | Supported | Supported |
| **`[[ ]]` extended test** | ✅ **Supported** (bashism retained) | ❌ Not supported |
| **`$(( ))` arithmetic** | Supported | Supported |
| **`(( ))` arithmetic** | ✅ **Supported** (bashism retained) | ❌ Not supported |
| **Arrays** | ✅ **Supported** (bashism retained) | ❌ Not supported |
| **Brace expansion `{a,b}`** | ✅ **Supported** (bashism retained) | ❌ Not supported |
| **Process substitution `<()`** | ❌ Fails (Permission denied) | ❌ Not supported |
| **`${var,,}` / `${var^^}`** | ✅ **Supported** (bashism retained) | ❌ Not supported |
| **`${var:0:5}` substring** | ❌ Not available | ❌ Not supported |
| **`function` keyword** | ❌ Not supported (use `name() { }`) | ❌ Not supported |
| **`2>&1` stderr redirect** | ✅ Supported | ✅ Supported |
| **`$?` exit code** | ✅ Supported | ✅ Supported |

> **Critical for Makefiles:** Fedora's `/bin/sh` is Bash in POSIX mode, which is MORE permissive than Dash. While you should still write portable Makefiles, some bashisms like `[[ ]]`, arrays, and `${var,,}` will actually work on Fedora (unlike Debian/Ubuntu/Raspios where they fail).

### Limitations of /bin/sh (POSIX Mode) on Fedora Compared to Full Bash

When writing Makefiles, relying on `/bin/sh` means you cannot use standard Bash extensions. Key limitations include:

| Limitation | Example | Behavior in `/bin/sh` (Fedora) |
|------------|---------|-------------------------------|
| **No Process Substitution** | `<(sort file.txt)` | ❌ Fails with "Permission denied" or syntax error |
| **No Substring Extraction** | `${var:0:5}` | ❌ Fails — word treated as command |
| **No `function` Keyword** | `function myfunc() { }` | ❌ Syntax error — use `myfunc() { }` instead |
| **Stricter echo Behavior** | `echo -e "text"` | ⚠️ May output literal `-e` depending on POSIX mode |

> **Note:** Unlike Debian/Ubuntu/Raspios (where dash blocks `[[ ]]`, arrays, and `${var,,}`), Fedora's bash in POSIX mode RETAINS these features. However, for cross-platform portability, it is still recommended to use POSIX-compliant syntax in Makefiles.

### Makefile Recipe Shell on Fedora

```bash
# Check what /bin/sh points to on Fedora
$ ls -la /bin/sh
lrwxrwxrwx 1 root root 4 Jan 16 2026 /bin/sh -> bash

# Verify bash runs in POSIX mode when invoked as sh
$ /bin/sh -c 'echo $BASH_VERSION'
5.3.9(1)-release

# Test [[ ]] — works on Fedora (unlike Debian)
$ /bin/sh -c '[[ 1 -eq 1 ]] && echo works || echo fails'
works

# Test arrays — work on Fedora (unlike Debian)
$ /bin/sh -c 'arr=(a b c); echo ${arr[0]}'
a

# Test process substitution — FAILS on Fedora
$ /bin/sh -c '<(echo hello)' 2>&1 | head -3
/bin/sh: line 1: /dev/fd/63: Permission denied

# Test function keyword — FAILS on Fedora
$ /bin/sh -c 'function myfunc() { echo works; }' 2>&1 | head -3
/bin/sh: -c: line 1: syntax error near unexpected token `myfunc'

# Test substring extraction — FAILS on Fedora
$ /bin/sh -c 'var=hello world; echo ${var:0:5}' 2>&1 | head -3
/bin/sh: line 1: world: command not found
```

> **Implication:** Makefile recipes on Fedora run under Bash in POSIX mode (`/bin/sh` → `bash`). This is MORE permissive than Debian/Ubuntu/Raspios (where `/bin/sh` → `dash`). Some bashisms work on Fedora that fail on Debian-based systems.

---

## Host Environment (Container Target)

> **Date:** 2026-08-18
> **Purpose:** Container environment details for Fedora — relevant for build configuration, resource allocation, and toolchain selection.

### Container Access from macOS Host

| Aspect | Value |
|--------|-------|
| **Container CLI** | `container` (Apple Container) — macOS native |
| **Docker** | ❌ Never used on macOS (golden rule) |
| **podman** | ❌ Never used on macOS (Linux hosts only) |

> **Important:** On macOS, always use `container` command. Never prepend `localhost/` to image names — the `container` CLI resolves images locally, and prepending `localhost/` forces a network lookup that times out.
> ```bash
> # CORRECT — resolves locally
> container run ringbuffer_fedora_build:latest make all
> # WRONG — forces network lookup, times out
> container run localhost/ringbuffer_fedora_build:latest make all
> ```

### Container Access from Linux Host

| Aspect | Value |
|--------|-------|
| **Container CLI** | `podman` (preferred) or Docker (Linux hosts only) |
| **Image names** | Standard — no `localhost/` prefix needed with podman either |

> **Note:** Fedora is the native host OS for `podman`. On Linux hosts, use `podman` directly (no `container` command needed).

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
6. **On Linux hosts, use `podman` directly** — no `container` command needed (Fedora's native container runtime).
## Toolchain (Fedora Container — Actual Measured Values)

### C/C++ Compiler

| Aspect | Value |
|--------|-------|
| **GCC** | 16.1.1 (Red Hat 16.1.1-2) |
| **g++** | 16.1.1 (Red Hat 16.1.1-2) |
| **clang/clang++** | 22.1.8 (Fedora 22.1.8-4.fc44) |
| **Thread model** | posix |
| **Standard library** | libstdc++ (GNU) — Fedora default |

> **Note:** Fedora 44 ships with very modern toolchain: GCC 16.1.1 (newer than Debian trixie's 14.2, Ubuntu's 13.3) and Clang 22.1.8 (newer than Debian's 19, Ubuntu's 18).

### GNU Make

| Aspect | Value |
|--------|-------|
| **Type** | GNU Make 4.4.1 |
| **Built for** | aarch64-redhat-linux-gnu |
| **Version query** | `make -v` ✅ works (unlike FreeBSD 14) |
| **Features** | Supports `$(shell ...)`, `ifeq/else`, `-jN` parallel jobs, etc. |

> **Note:** GNU Make 4.4.1 is the same as Debian trixie and Raspios. Supports all modern features needed for ringbuffer builds.

### Package Manager

| Aspect | Value |
|--------|-------|
| **Tool** | `dnf` (Fedora's package manager) |
| **Update command** | `dnf update` or `dnf makecache` (refreshes package metadata) |
| **Install command** | `dnf install -y <package>` |

### Common Development Packages on Fedora

| Package | Purpose |
|---------|---------|
| `gcc` / `gcc-c++` | GCC, g++, make, libc development headers |
| `clang` / `llvm` | LLVM/Clang C/C++ compiler (available via dnf) |
| `python3` | Python 3.14.6 (Fedora includes it by default) |
| `binutils` | readelf, nm, ar, strip, objdump (installed but may need PATH adjustment) |
| `file` | File type detection (installed at `/usr/bin/file`) |

> **Note:** The Fedora container is minimal — analysis tools (`readelf`, `nm`, `ar`, `strip`, `objdump`, `file`) are installed at `/usr/bin/` but may not be in PATH. Install with: `dnf install -y binutils file bsdmainutils`

### Analysis Tools

| Tool | Location | Available? |
|------|----------|------------|
| `readelf` | `/usr/bin/readelf` (may not be in PATH) | ✅ Installed (binutils 2.46.1) |
| `objdump` | `/usr/bin/objdump` (may not be in PATH) | ✅ Installed (binutils 2.46.1) |
| `nm` | `/usr/bin/nm` (may not be in PATH) | ✅ Installed (binutils 2.46.1) |
| `ar` | `/usr/bin/ar` (may not be in PATH) | ✅ Installed (binutils 2.46.1) |
| `strip` | `/usr/bin/strip` (may not be in PATH) | ✅ Installed (binutils 2.46.1) |
| `file` | `/usr/bin/file` (may not be in PATH) | ✅ Installed (file 5.46) |
| `which` | Not installed | ❌ Not available |

> **Note:** Unlike Debian/Ubuntu/Raspios, the Fedora container is minimal — `readelf`, `objdump`, `nm`, `ar`, `strip`, and `file` are installed but may not be discoverable via `which`. Use full paths (`/usr/bin/readelf`, etc.) or install with `dnf install -y binutils file`.

---

## Platform-Specific Notes for Ringbuffer Implementation

### Shell & Makefile Compatibility (Fedora Container)

| Aspect | Value |
|--------|-------|
| **Interactive shell** | Bash 5.3.9 (user login) |
| **Make recipe shell (`/bin/sh`)** | Bash in POSIX mode — `/bin/sh -> bash` |
| **Make type** | GNU make 4.4.1 (supports `$(shell ...)`, `ifeq/else`) |

> **Critical:** Makefile recipes on Fedora run under Bash in POSIX mode (`/bin/sh` → `bash`). This is MORE permissive than Debian/Ubuntu/Raspios (where `/bin/sh` → `dash`). Some bashisms like `[[ ]]`, arrays, and `${var,,}` will work on Fedora but fail on Debian-based systems.

> **Key difference:** On Fedora, `/bin/sh` is a symbolic link to `/bin/bash`. When Bash is invoked as `sh`, it enters POSIX mode. This disables many extended Bash features but still supports more than dash/ash.

### Container Image Building (Fedora)

```bash
# Build a Fedora container image from macOS host
container build -t ringbuffer_fedora_build:latest     --file fedora/containers/build/Dockerfile.fedora     .

# Run a build inside the container from macOS host
container run --rm -v $(pwd):/workspace ringbuffer_fedora_build:latest     make all

# Run tests inside the container from macOS host
container run --rm -v $(pwd):/workspace ringbuffer_fedora_build:latest     make test
```

> **Important:** Always omit `localhost/` prefix from image names when using the `container` CLI on macOS.

### LTO_FLAG — GCC Does NOT Support `-flto=thin`

> **Measured:** Both GCC 16.1 and Clang 22 on Fedora:
> - **GCC 16.1:** `echo "" | g++ -flto=thin -x c++ -` → error: unrecognized argument to '-flto=' option: 'thin'
>   - **GCC does NOT support `-flto=thin`** — use `-flto` only
> - **Clang 22:** `echo "" | clang++ -flto=thin -x c++ -` → compiles successfully (error only about missing main)
>   - **Clang DOES support `-flto=thin`**

> ```makefile
> # For GCC builds — use plain -flto (NOT -flto=thin)
> LTO_FLAG := -flto
> # For Clang builds — either works, but prefer -flto=thin for speed
> LTO_FLAG_CLANG := -flto=thin
> ```

### C++20 Header Availability — `<jthread>` NOT Available (Critical!)

| Header | GCC 16.1.1 | Clang 22.1.8 |
|--------|------------|--------------|
| `<format>` | ✅ OK | ✅ OK |
| `<stop_token>` | ✅ OK | ✅ OK |
| **`<jthread>`** | ❌ **NOT available** — `fatal error: jthread: No such file or directory` | ❌ **NOT available** — `'jthread' file not found` |

> **CRITICAL:** Fedora 44 with GCC 16.1.1 and Clang 22.1.8 does NOT provide `<jthread>`. This is the same limitation as Debian 13, Ubuntu 24.04, Raspios, and FreeBSD 14.
>
> **Implication for ringbuffer:** Use `std::thread` + `atomic<bool>` stop flag instead of `std::jthread`. The same approach used for FreeBSD 14, Debian, Ubuntu, and Raspios applies here.

### RPATH on Fedora (Linux)

Fedora uses the standard Linux `$ORIGIN` convention for RUNPATH:

```bash
# On Fedora — $ORIGIN works correctly in RUNPATH
$ readelf -d libswtr_ringbuffer.so | grep RUNPATH
  RUNPATH            0x... $ORIGIN/../lib
```

> **Key difference from FreeBSD 14:** Linux dynamic linker (`ld.so`) fully supports `$ORIGIN` in RUNPATH. This is why Concurrent tests work on Fedora but are SKIPPED on FreeBSD 14 (where `ld-elf.so.1` strips `$ORIGIN`).

### Binary Format

| Aspect | Value |
|--------|-------|
| **Format** | ELF (Executable and Linkable Format) |
| **Shared lib extension** | `.so` |
| **Static lib extension** | `.a` |
| **Analysis tool** | `readelf`, `objdump`, `nm` (may need full paths) |

### Container Resources (Measured)

| Resource | Value |
|----------|-------|
| **Memory** | 1.1 GB total (container limit) |
| **CPU cores** | 4 |
| **Disk** | 504 GB total, ~1.1 GB used (0.2%) |

> **Note:** Container has 1.1 GB RAM — sufficient for building but not generous. Set container memory limits accordingly from the macOS host.

> **Note:** Fedora container has 4 CPU cores (vs 5 on Debian/Ubuntu/Raspios containers).

---

## Comparison: Fedora vs Debian vs Ubuntu vs Raspios vs macOS vs FreeBSD 14 Toolchain

| Aspect | Fedora 44 (GCC 16.1) | Debian 13 (GCC 14.2) | Ubuntu 24.04 (GCC 13.3) | Raspios (GCC 14.2) | macOS (Apple clang 21) | FreeBSD 14 (clang 19.1.7) |
|--------|---------------------|----------------------|-------------------------|--------------------|----------------------|--------------------------|
| **Compiler** | GCC 16.1 (default) or clang 22.1.8 | GCC 14.2 (default) or clang 19.1.7 | GCC 13.3 (default) or clang 18.1.3 | GCC 14.2 (default) or clang 19.1.7 | Apple clang (LLVM-based) | FreeBSD clang 19.1.7 |
| **Target** | aarch64-redhat-linux-gnu | aarch64-linux-gnu | aarch64-linux-gnu | aarch64-linux-gnu | arm64-apple-darwin / x86_64-apple-darwin | x86_64-unknown-freebsd14.4 |
| **Std Lib** | libstdc++ (GNU) | libstdc++ (GNU) 6.0.33 | libstdc++ (GNU) | libstdc++ (GNU) 6.0.33 | libc++ (Apple) | libc++ (LLVM upstream) |
| **Binary format** | ELF | ELF | ELF | ELF | Mach-O | ELF |
| **Shared lib ext** | `.so` | `.so` | `.so` | `.so` | `.dylib` | `.so` |
| **Install name/RPATH** | `$ORIGIN/../lib/...` ✅ works | `$ORIGIN/../lib/...` ✅ works | `$ORIGIN/../lib/...` ✅ works | `$ORIGIN/../lib/...` ✅ works | `@executable_path/../lib/...` ✅ works | `$ORIGIN/../lib/...` ❌ stripped on FreeBSD 14 |
| **Make type** | GNU make 4.4.1 | GNU make 4.4.1 | GNU make 4.3 | GNU make 4.4.1 | GNU make 3.81 | BSD make (native only) |
| **Recipe shell** | `/bin/sh` → Bash POSIX mode | `/bin/sh` → Dash (strict POSIX) | `/bin/sh` → Dash (strict POSIX) | `/bin/sh` → Dash (strict POSIX) | `/bin/sh` → Bash 3.2 POSIX mode | `/bin/sh` → ash (strict POSIX) |
| **Container support** | Docker/podman (Linux host only) or `container` (macOS only) | Docker/podman (Linux host only) or `container` (macOS only) | Docker/podman (Linux host only) or `container` (macOS only) | Docker/podman (Linux host only) or `container` (macOS only) | `container` command (Apple Container) | None (native-only) |
| **Make version query** | `make -v` ✅ | `make -v` ✅ | `make -v` ✅ | `make -v` ✅ | `make -v` ✅ | `make -V VERSION` only ❌ no `-v` |
| **C++20 `<format>`** | ✅ Yes (GCC 16, Clang 22) | ✅ Yes (GCC 14, Clang 19) | ✅ Yes (GCC 13, Clang 18) | ✅ Yes (GCC 14, Clang 19) | ✅ Yes | ✅ Yes |
| **C++20 `<stop_token>`** | ✅ Yes (GCC 16, Clang 22) | ✅ Yes (GCC 14, Clang 19) | ✅ Yes (GCC 13, Clang 18) | ✅ Yes (GCC 14, Clang 19) | ✅ Yes | ✅ Yes (partial — types undefined) |
| **`std::jthread`** | ❌ **NOT available** (same as Debian/Ubuntu/Raspios/FreeBSD) | ❌ **NOT available** (same as Ubuntu/Raspios/FreeBSD) | ❌ **NOT available** (same as Debian/Raspios/FreeBSD) | ❌ **NOT available** (same as Debian/Ubuntu/FreeBSD) | ✅ Yes (full support) | ❌ **NOT available** |
| **LTO flag (GCC)** | `-flto` only (NOT `-flto=thin`) | `-flto` only (NOT `-flto=thin`) | `-flto` only (NOT `-flto=thin`) | `-flto` only (NOT `-flto=thin`) | N/A (Apple clang) | N/A |
| **LTO flag (Clang)** | `-flto=thin` ✅ supported | `-flto=thin` ✅ supported | Clang 18 has libstdc++ linking issues in container | `-flto=thin` ✅ supported | `-flto` or `-flto=thin` | `-flto` |
| **Dead code elim** | `-Wl,--gc-sections` | `-Wl,--gc-sections` | `-Wl,--gc-sections` | `-Wl,--gc-sections` | `-dead_strip` | `-Wl,--gc-sections` |
| **Analysis tools** | `readelf`, `objdump`, `nm` (may need full paths) | `readelf`, `objdump`, `nm` | `readelf`, `objdump`, `nm` | `readelf`, `objdump`, `nm` | `otool`, `lipo` | `readelf`, `objdump`, `nm` |
| **Python** | 3.14.6 | 3.13.5 | 3.12.3 | 3.13.5 | 3.14.6 (Homebrew) | N/A |
| **Bash version** | 5.3.9 (interactive) | 5.2.37 (interactive) | 5.2.21 (interactive) | 5.2.37 (interactive) | 3.2.57 (POSIX mode) | N/A |
| **Man page strip** | `col -bx` (recommended) | `col -b` | `col -b` | `col -bx` (recommended) | `col -bx` | `col -b` |
| **Package manager** | `dnf` | `apt-get` | `apt-get` | `apt-get` | N/A (Homebrew) | N/A |

> **Key difference Fedora vs Debian/Ubuntu/Raspios:** Fedora's `/bin/sh` is Bash in POSIX mode (not Dash), which is MORE permissive. Features like `[[ ]]`, arrays, and `${var,,}` work on Fedora but fail on Debian-based systems. However, for cross-platform portability, still use POSIX-compliant syntax in Makefiles.

---

## Build & Test Considerations for Fedora

### Makefile Recipe Patterns (Fedora/Bash POSIX mode)

```makefile
# WORKING pattern for Fedora — Bash POSIX mode compatible syntax
.PHONY: test build

test:
	@echo "=== Running tests ==="
	PASS=0; FAIL=0; 	for t in 1 2 3 4 5 6 7; do 		RESULT=$$(echo 'test input' | python3 test.py $$t 2>&1); 		EXIT=$$?; 		echo "  T00$$t: $$RESULT"; 		if [ $$EXIT -ne 0 ]; then FAIL=$$((FAIL+1)); else PASS=$$((PASS+1)); fi; 	done; 	echo "Results: $$PASS passed, $$FAIL failed"; 	echo "`date '+%Y-%m-%d %H:%M:%S'` Tests: $$PASS/7 passed" >> logs/build.log
```

> **Bash POSIX mode notes (Fedora):**
> - `[[ ]]` works on Fedora (unlike Debian/Ubuntu/Raspios) — but use `[ ]` for portability
> - Arrays work on Fedora (unlike Debian/Ubuntu/Raspios) — but use `for t in 1 2 3` for portability
> - `${var,,}` works on Fedora (unlike Debian/Ubuntu/Raspios) — but use `tr '[:upper:]' '[:lower:]'` for portability
> - No process substitution `<()` — use pipes or temp files instead (same as all platforms)
> - No `function` keyword — use `name() { }` format (same as all platforms)
> - No `${var:0:5}` substring extraction — use `cut` or `expr` instead

### Container Memory Limits (from macOS Host)

When running Fedora containers from the macOS host, calculate memory limits:

```bash
# Get available memory for container allocation (run on macOS host)
vm_stat  # Shows page statistics
# Set container -m to 50% of available, capped at 3 GB
```

With **64 GB RAM** on the M4 Mac Mini, container memory limits can be generous (up to the 3 GB cap per container).

> **Note:** Fedora container has 4 CPU cores (vs 5 on Debian/Ubuntu/Raspios containers).

---

## Summary: Platform-Specific Gotchas for Agents

### Fedora (Container Target)
1. **`/bin/sh` is Bash in POSIX mode** — MORE permissive than Dash (supports `[[ ]]`, arrays, `${var,,}`) but still has limitations
2. **GNU make 4.4.1** — `make -v` works, supports all standard features (same as Debian/Raspios)
3. **Use `readelf`** — Fedora uses ELF format (same as Debian/Linux, different from macOS Mach-O)
4. **RPATH `$ORIGIN` works** — fully supported by Linux dynamic linker (unlike FreeBSD 14)
5. **GCC: LTO_FLAG is `-flto`** — NOT `-flto=thin` (Fedora GCC 16.1 does not support `--thin`)
6. **Clang: LTO_FLAG is `-flto=thin`** — Clang 22 supports `--thin`
7. **`<jthread>` NOT available** — use `std::thread` + `atomic<bool>` stop flag (same as Debian/Ubuntu/Raspios/FreeBSD)
8. **Container CLI** — use `container` on macOS host, `podman` on Linux hosts
9. **Never prepend `localhost/`** to image names with the `container` CLI on macOS
10. **Man pages** — use `col -bx` to strip formatting on Fedora (man and col not installed by default in container)
11. **Default compiler** — GCC 16.1 (`g++`), not clang (though Clang 22 is available via dnf)
12. **Analysis tools may not be in PATH** — `readelf`, `nm`, `ar`, `strip`, `objdump` are at `/usr/bin/` but may need full paths
13. **Package manager is `dnf`** — not `apt-get` (Fedora uses dnf, Debian/Ubuntu/Raspios use apt)
14. **`which` not installed** — use `find /usr -name <tool>` or full paths instead

### Debian (Reference for Comparison)
1. `/bin/sh` is Dash — strict POSIX, no bashisms (LESS permissive than Fedora)
2. GNU make 4.4.1 — same version as Fedora
3. GCC 14.2, Clang 19.1.7 — older than Fedora's GCC 16.1 / Clang 22
4. Python 3.13.5 — older than Fedora's 3.14.6
5. Same `<jthread>` limitation as Fedora

### Ubuntu (Reference for Comparison)
1. `/bin/sh` is Dash — strict POSIX, no bashisms (LESS permissive than Fedora)
2. GNU make 4.3 — slightly older than Fedora's 4.4.1
3. GCC 13.3, Clang 18 — older than Fedora's GCC 16.1 / Clang 22
4. Python 3.12.3 — older than Fedora's 3.14.6
5. Same `<jthread>` limitation as Fedora

### Raspios (Reference for Comparison)
1. `/bin/sh` is Dash — strict POSIX, no bashisms (LESS permissive than Fedora)
2. GNU make 4.4.1 — same version as Fedora
3. GCC 14.2, Clang 19.1.7 — older than Fedora's GCC 16.1 / Clang 22
4. Python 3.13.5 — older than Fedora's 3.14.6
5. Same `<jthread>` limitation as Fedora

### macOS (Reference for Comparison)
1. `/bin/sh` is Bash 3.2 in POSIX mode — limited bashisms tolerated
2. GNU make 3.81 — functional but older (no `$(realpath ...)`)
3. Use `otool` not `readelf` — Mach-O format
4. RPATH uses `@executable_path` — fully supported
5. **`std::jthread` available** — full C++20 support (unlike Fedora/Debian/Ubuntu/Raspios/FreeBSD)

### FreeBSD 14 (Reference for Comparison)
1. `/bin/sh` is ash — strict POSIX, no bashisms (LESS permissive than Fedora)
2. BSD make only — `gmake` NOT allowed
3. Use `readelf` not `otool` — ELF format
4. RPATH `$ORIGIN` stripped by `ld-elf.so.1` — dynamic library testing NOT possible
5. No container support, no `std::jthread` (same as Fedora/Debian/Ubuntu/Raspios)

---

## Source Code Compatibility Assessment for Fedora

### Byte-Identical (same as Debian, Ubuntu, Raspios, and other Linux distros)
The following source files should be identical across all Linux distributions:
- `status.hpp` — pure enum definitions, no platform dependencies
- `ringbuffer.hpp` — uses standard C++20 headers (`<atomic>`, `<format>`, `<stop_token>`)
- `swtr_ringbuffer_impl.hpp` — implementation class header (with `#ifdef __FreeBSD__` guards)
- `Lifecycle.cpp`, `ReadOps.cpp`, `TransformOps.cpp` — standard C++20 + POSIX I/O
- `Accessors_*.cpp`, `LoggingOps_*.cpp` — standard C++20
- `ErrorOps.cpp`, `WriteOps.cpp` — uses `<unistd.h>` (POSIX, available on all platforms)
- `Makefile` — GNU make syntax, `$ORIGIN` RPATH, `-Wl,--gc-sections`, `.so` extension

### Platform-Specific Differences (vs FreeBSD 14)
| File | Fedora/Debian/Ubuntu/Raspios/Linux | FreeBSD 14 |
|------|-----------------------------------|------------|
| `Threading.cpp` | `std::thread` + `atomic<bool>` stop flag (no `<jthread>`) | `std::thread` + `atomic<bool>` stop flag |
| `swtr_ringbuffer_impl.hpp` | No `<jthread>`, atomic stop flag | No `<jthread>`, atomic stop flag |
| `Makefile` | GNU make, `-Wl,--gc-sections`, `.so`, `$ORIGIN` RPATH | BSD make, `-Wl,--gc-sections`, `.so`, `$ORIGIN` stripped |
| `tests/Makefile` | GNU make syntax, `readelf` for verification | BSD make syntax, `readelf` for verification |

> **CORRECTION:** Fedora does NOT have `<jthread>` — same as Debian, Ubuntu, Raspios, and FreeBSD 14. All five use `std::thread` + atomic bool stop flag.

> **Cross-platform symmetry:** Fedora source code should be byte-identical to Debian, Ubuntu, Raspios, and other Linux distributions (platform-insensitive for C/C++ source). Only Makefile-level differences are expected (container image name, working directory path, distro detection check).

> **Fedora vs Debian-based:** Fedora uses `dnf` package manager (not `apt-get`) and has Bash as `/bin/sh` in POSIX mode (not Dash). Fedora's toolchain is newer (GCC 16.1 vs Debian's 14.2, Clang 22 vs Debian's 19). Fedora container has 4 CPU cores (vs 5 on Debian/Ubuntu/Raspios containers).
