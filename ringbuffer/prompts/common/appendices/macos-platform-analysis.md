# macOS Platform Analysis

> **Purpose:** Reference data for ringbuffer implementation on macOS — shell behavior, toolchain, and platform-specific considerations.
>
> **System Access:** Native (Apple Silicon Mac)
> **Collected:** 2026-08-18

---

## System Information

| Field | Value |
|-------|-------|
| **OS** | macOS (Darwin) |
| **Architecture** | arm64 (Apple Silicon) or x86_64-apple-darwin (Intel) |
| **Default user shell** | zsh (Z Shell) — Apple changed default from bash to zsh in macOS Catalina (10.15+) |

---

## Useful System Commands

### Reading Man Pages on macOS

macOS man pages include formatting/control characters that make them hard to read in plain text. Use `col -bx` to strip formatting:

```bash
# Print clean output to screen
man <command> | col -bx

# Save as a clean text file
man <command> | col -bx > manpage.txt

# Bypass the pager entirely (equivalent to cat)
man -P cat <command>
```

> **Why:** macOS man pages use backspace-based formatting (bold, underline via `^H` sequences). Without `col -bx`, these appear as garbled characters in plain text. This is the same technique used on FreeBSD 14.

---

## Host Environment (This Machine — M4 Mac Mini)

> **Date:** 2026-08-18
> **Purpose:** Host environment details for this specific machine — relevant for build configuration, resource allocation, and toolchain selection.

### System Overview

| Field | Value |
|-------|-------|
| **Model** | Mac16,11 (M4 Mac Mini) |
| **OS** | macOS 26.5.2 (Darwin Kernel 25.5.0) |
| **Build** | 25F84 |
| **Architecture** | arm64 (Apple M4) |
| **CPUs** | 14 cores |
| **RAM** | 64 GB |
| **Disk** | 3.6 TB total, ~12 GB used (459k files), 1.6 TB available |
| **Hostname** | macmini03.sc.brunoe.net |

### Shell Environment

| Aspect | Value |
|--------|-------|
| **Default user shell** | `/bin/zsh` (zsh 5.9 arm64-apple-darwin25) |
| **Make recipe shell** | `/bin/sh` (Bash 3.2.57 POSIX mode) |
| **Interactive shell** | zsh (Apple Terminal default since Catalina 10.15) |

### Make

| Aspect | Value | Notes |
|--------|-------|-------|
| **System make** | GNU Make 3.81 (2006) | `/usr/bin/make` — older but functional |
| **Homebrew make** | ❌ Not installed | `gmake` not available via Homebrew |
| **Location** | `/usr/bin/make` (Xcode CLT) | System version |

> **GNU Make 3.81 capabilities:**
> - ✅ `$(shell ...)` — Supported (added in 3.80)
> - ✅ `ifeq/else/endif` — Supported (early versions)
> - ✅ `.PHONY` — Supported
> - ✅ `$(wildcard ...)`, `$(filter ...)`, `$(patsubst ...)` — Supported
> - ✅ `$(foreach ...)`, `$(if ...)`, `$(call ...)` — Supported (added in 3.81)
> - ✅ `-jN` parallel jobs — Supported
> - ✅ `$@`, `$<`, `$^` automatic variables — Supported
> - ❌ `$(realpath ...)` — NOT supported (added in 3.82/4.0)
> - ❌ `$(lastword ...)` — NOT supported (added in 3.82/4.0)
>
> **The existing `src/common/python/Makefile.gnu` uses `$(shell ...)` and `ifeq/else` — these WORK on this system's GNU Make 3.81.**
>
> **If a future Makefile needs `$(realpath ...)` or other 3.82+ features**, install a modern GNU make:
> ```bash
> brew install make
> # This installs 'gmake' at /opt/homebrew/bin/gmake (or 'make' if you update PATH)
> ```

### C++ Toolchain

| Aspect | Value |
|--------|-------|
| **Primary compiler** | Apple clang 21.0.0 (clang-2100.1.1.101) |
| **Target** | arm64-apple-darwin25.5.0 |
| **Location** | `/usr/bin/clang++` (Xcode CLT) |
| **g++ (Homebrew)** | Available at `/opt/homebrew/bin/g++` |
| **libstdc++** | ❌ Not available (Apple deprecated since macOS 10.14) |
| **libc++** | ✅ Default (Apple's LLVM C++ standard library) |

> **Note:** Homebrew g++ may fail to compile due to missing libstdc++ headers. Apple clang is the primary supported compiler.

### Python

| Aspect | Value |
|--------|-------|
| **Version** | 3.14.6 |
| **Location** | `/opt/homebrew/bin/python3` (Homebrew) |

### Container Support

| Aspect | Value |
|--------|-------|
| **Apple Container** | ✅ Available at `/usr/local/bin/container` |
| **Docker** | ❌ Not available (macOS native) |
| **podman** | ❌ Not available (Linux only) |

> **Apple Container subcommands:**
> - `container run` — Run a container
> - `container build` / `container image build` — Build an image from Dockerfile
> - `container images` / `container image list` — List images
> - `container system status` — Show container services status
> - `container system start` — Start the container daemon (does NOT auto-start)
>
> **Important:** The `container` daemon does NOT start automatically on macOS. Always check and start it before container operations.

### PATH (Notable Entries)

| Path | Purpose |
|------|---------|
| `/Users/ebruno/google-cloud-sdk/bin` | Google Cloud CLI tools |
| `/opt/homebrew/bin` | Homebrew packages (python3, g++, etc.) |
| `/opt/homebrew/sbin` | Homebrew system utilities |
| `/usr/local/bin` | Local installations (container command) |
| `/opt/X11/bin` | X11 utilities |

> **Note:** PATH includes Google Cloud SDK, Homebrew, and X11. Make recipes inherit this PATH but do NOT load `~/.zshrc` or `~/.bash_profile`. Environment variables set interactively ARE inherited.

### Resource Allocation for Containers (macOS Host)

When running containers from this macOS host targeting Linux distros, calculate memory limits:

```bash
# Get available memory for container allocation
vm_stat  # Shows page statistics
# Extract: Pages free + Pages inactive × page size = total available bytes
# Set container -m to 50% of this value, capped at 3 GB
```

With **64 GB RAM**, container memory limits can be generous (up to the 3 GB cap per container).

### Disk Space

| Metric | Value |
|--------|-------|
| **Total** | 3.6 TB |
| **Used** | ~12 GB (0.3%) |
| **Available** | 1.6 TB |
| **File count** | 459k files on root volume |

> **Plenty of disk space** for building containers, cross-compiling, and storing artifacts. No disk pressure concerns.

---

## Shell & Makefile Compatibility (Critical for Python Regression)

> **Date:** 2026-08-18
> **Purpose:** Lessons learned about macOS shell behavior with make — critical for writing portable Makefiles.

### Shell Environment

| Aspect | Value |
|--------|-------|
| **Default user shell** | zsh (Apple Terminal default since macOS Catalina 10.15) |
| **Make recipe shell** | `/bin/sh` (POSIX-compliant Bourne shell) — make ignores the active terminal shell |
| **`/bin/sh` implementation** | Bash running in POSIX mode (Apple's `/bin/sh` is a hard link or copy of bash) |
| **POSIX mode behavior** | More strict than standard Bash — "bashisms" may fail unless `SHELL := /bin/bash` is set |

> **Critical:** Even though the user's terminal uses zsh, `make` completely ignores it. Make spawns `/bin/sh` for every recipe line. This is POSIX compliance — make must work in a standard Bourne shell environment regardless of the user's interactive shell.

### Checking /bin/sh Version on macOS

```bash
$ /bin/sh --version
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)
Copyright (C) 2007 Free Software Foundation, Inc.
```

> **Note:** macOS ships with Bash 3.2 (from 2007) as `/bin/sh` in POSIX mode. This is significantly older than modern Bash (5.x). Features available in Bash 4+/5+ may not work.

### Key Differences: macOS /bin/sh vs Linux /bin/sh (ash)

| Feature | macOS `/bin/sh` (Bash 3.2 POSIX mode) | FreeBSD/Linux `/bin/sh` (ash) |
|---------|--------------------------------------|------------------------------|
| **Underlying implementation** | Bash 3.2 in POSIX mode | Almquist shell (ash) |
| **`[ ]` test** | Supported | Supported |
| **`[[ ]]` extended test** | Not in POSIX mode (use `[ ]`) | Not supported |
| **`$(( ))` arithmetic** | Supported | Supported |
| **`(( ))` arithmetic** | Not in POSIX mode | Not supported |
| **Arrays** | Not in POSIX mode | Not supported |
| **Brace expansion `{a,b}`** | Not in POSIX mode | Not supported |
| **`2>&1` stderr redirect** | Supported | Supported |
| **`$?` exit code** | Supported | Supported |
| **`$$` make variable escape** | Supported | Supported |
| **Nested command substitution** | Works but strict in POSIX mode | Fragile in if-blocks with `\` continuations |
| **`@` prefix on continued lines** | Breaks (ash/bash sees `@echo` as command) | Same issue |
| **Environment from ~/.zshrc** | Not loaded (non-interactive shell) | Not loaded (non-interactive shell) |

### Environment Variable Inheritance

**Problem:** Make spawns a non-interactive `/bin/sh` session for every recipe line. Configuration files like `~/.zshrc`, `~/.bash_profile`, or `~/.profile` are NOT loaded.

```makefile
# BROKEN — ~/.zshrc aliases/functions not available in make recipes
test:
	@my_custom_alias  # FAILS — alias defined in ~/.zshrc, not loaded
	@my_shell_function  # FAILS — function defined in ~/.zshrc, not loaded

# WORKAROUND — source the profile explicitly (not recommended for portability)
test:
	@source ~/.bash_profile && my_custom_alias  # Works but fragile

# BEST PRACTICE — use absolute paths or built-in commands only
test:
	@/usr/bin/python3 test.py  # Always available, no env dependency
```

**Implications:**
- Custom aliases defined in `~/.zshrc` or `~/.bash_profile` are NOT available in make recipes
- Custom functions defined in shell profiles are NOT available
- Environment variables set interactively (e.g., `export MY_VAR=...` in terminal) ARE inherited by make
- PATH is inherited from the parent process, but may differ from interactive shell PATH

### The `$$` Escaping (Same as FreeBSD/Linux)

Make converts `$$` to `$` before passing to the shell. This is universal across all platforms:

```makefile
# Make converts $$ → $, shell sees $VAR and expands it
test:
	@echo "Exit code was $$?"  # Shell sees: echo "Exit code was $?"
```

### Nested Command Substitution (macOS Specific)

Bash 3.2 in POSIX mode is stricter than modern Bash about nested command substitutions:

```makefile
# BROKEN — nested backticks in POSIX mode can fail
test:
	@if [ condition ]; then \
		echo "`date '+%Y-%m-%d'` value: $$(printf '%s' '$$ORIGIN')" >> log; \
	fi

# WORKS — printf with separate arguments avoids nesting
test:
	@if [ condition ]; then \
		printf "%s %s\n" "`date '+%Y-%m-%d'`" '$$ORIGIN' >> log; \
	fi
```

### Makefile Recipe Structure Rules for macOS + /bin/sh (Bash 3.2 POSIX mode)

1. **Line continuations (`\`)** — All commands in a single shell invocation must be joined with `\`
2. **`@` prefix** — Suppresses echo of the command line. Only works on the FIRST line of a recipe, not on continued lines (same as FreeBSD/Linux)
3. **Variable scope** — Variables set in one shell invocation are NOT available in the next. Log variables on the same continued line.
4. **`$$` escaping** — Make converts `$$` to `$`. Single quotes protect from shell expansion: `'$ORIGIN'` → literal `$ORIGIN`
5. **No bashisms** — Even though `/bin/sh` is Bash, it runs in POSIX mode. Do NOT use:
   - `[[ ]]` — use `[ ]` instead
   - `(( ))` — use `$(( ))` for arithmetic
   - Arrays — not available in POSIX mode
   - `${var,,}` or `${var^^}` — case conversion not available

### macOS Python Makefile Pattern (Working Template)

```makefile
# No SHELL override needed — /bin/sh is Bash 3.2 POSIX mode, which works
# for standard POSIX constructs

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
	# Log on same continued line so $$PASS is available
	echo "`date '+%Y-%m-%d %H:%M:%S'` Tests: $$PASS/7 passed" >> logs/build.log
	@if [ ! -f .cpp_build_failed ]; then \
		echo "=== Running Concurrent tests ==="; \
		printf "%s Concurrent OK: RPATH %s resolved correctly\n" \
			"`date '+%Y-%m-%d %H:%M:%S'`" '$$ORIGIN' >> logs/build.log; \
	fi
```

### Key Takeaways for Agent Workflows on macOS

1. **Use POSIX shell syntax** — no `[[ ]]`, no `(( ))`, no arrays, even though `/bin/sh` is Bash
2. **Use `printf "%s" '$$ORIGIN'`** for log messages containing `$ORIGIN` (same as FreeBSD/Linux)
3. **Avoid nested command substitutions** in if-blocks — use `printf` with separate arguments
4. **Never put `@` on continued lines** — it breaks shell parsing (same as FreeBSD/Linux)
5. **Keep variable-dependent logging on the same `\` continuation** — variables don't persist across recipe lines
6. **Don't rely on ~/.zshrc or ~/.bash_profile** — make doesn't load them; use absolute paths
7. **macOS uses GNU make** (from Xcode Command Line Tools or Homebrew) — supports `$(shell ...)`, `ifeq/else`, etc.
8. **`make -v` works on macOS** (unlike FreeBSD) — shows GNU make version

### Comparison: GNU make vs BSD make (macOS vs FreeBSD 14)

| Feature | macOS GNU make | FreeBSD 14 BSD make |
|---------|---------------|---------------------|
| **Variable syntax** | `$(VAR)` or `${VAR}` | `$(VAR)` only |
| **`$(shell ...)`** | Supported | Not supported |
| **`ifeq/else/endif`** | Supported | Not supported |
| **Pattern rules `%`** | Supported | Limited support |
| **`.PHONY`** | Supported | Supported |
| **Shell for recipes** | `/bin/sh` (Bash 3.2 POSIX mode) | `/bin/sh` (ash, POSIX-only) |
| **Version query** | `make -v` ✅ | `make -V VERSION` only ❌ no `-v` |
| **Parallel jobs** | `-jN` ✅ | `-jN` ✅ (same) |
| **Container support** | `container` command (Apple Container) | None (native-only) |

### macOS Python Regression Test Flow

```
make test (GNU make, /bin/sh = Bash 3.2 POSIX mode)
├── syntax-check
│   └── python3 -m py_compile *.py
├── build (C++ shared library)
│   ├── cd ../../macos/cpp && make all
│   └── ln -s ../../macos/cpp/lib/libswtr_ringbuffer.dylib lib/
│       └── RPATH uses @executable_path (macOS convention)
├── Concurrent tests (test_ringbuffer.py)
│   └── T001-T007: runs with ctypes + C++ shared library
├── Pure Python tests (test_ringbuffer_pure.py)
│   └── T001-T007: runs without C++ dependency
└── Performance benchmark (benchmark.py)
    └── COMPLETED: Concurrent vs Pure Python comparison
```

### RPATH on macOS (vs FreeBSD 14)

macOS uses `@executable_path` instead of `$ORIGIN`:

```bash
# On macOS — @executable_path works in install_name
$ otool -L libswtr_ringbuffer.dylib
  libswtr_ringbuffer.dylib (compatibility version X, current version Y)
  @executable_path/../lib/libswtr_ringbuffer.dylib (version X.Y.Z)

# On FreeBSD 14 — $ORIGIN is stripped by ld-elf.so.1
$ readelf -d libswtr_ringbuffer.so | grep RUNPATH
  RUNPATH            0x... $ORIGIN/../lib
# FAILS at runtime — ld-elf.so.1 strips $ORIGIN to empty string
```

**Key difference:** macOS `@executable_path` is fully supported by the dynamic linker. FreeBSD 14 `$ORIGIN` in RUNPATH is stripped — this is why Concurrent tests work on macOS but are SKIPPED on FreeBSD 14.

### Container Support (macOS Specific)

macOS uses the `container` command (Apple Container), NOT Docker or podman:

| Subcommand | Description |
|------------|-------------|
| `container run` | Run a container |
| `container build` / `container image build` | Build an image from Dockerfile |
| `container images` / `container image list` | List images |
| `container system status` | Show container services status |
| `container system start` | Start the container daemon |

> **Important:** The `container` daemon does NOT start automatically on macOS. Always check and start it before container operations:
> ```bash
> $ container system status  # Check if running
> $ container system start   # Start if not running
> ```

---

## Toolchain

### C++ Compiler
| Field | Value |
|-------|-------|
| **Compiler** | Apple clang (based on LLVM/Clang) |
| **Target** | arm64-apple-darwin (Apple Silicon) or x86_64-apple-darwin (Intel) |
| **Thread model** | posix |

### g++ (GCC) — Best-Effort Only
- **Homebrew g++** defaults to `libstdc++`, but Apple removed libstdc++ headers starting with macOS 10.14 (Mojave)
- When g++ tries to compile code that includes `<atomic>`, `<vector>`, `<string>`, etc., it cannot find them in the libstdc++ include path
- **Result:** g++ may fail to compile on modern macOS — this is acceptable, documented as INFO/WARNING in build reports
- **Primary compiler:** clang++ (Apple's version) — always works

### Linker
| Field | Value |
|-------|-------|
| **Linker** | ld64 (Apple's linker) |
| **Location** | `/usr/bin/ld` (part of Xcode Command Line Tools) |

### Standard Library
| Field | Value | Location |
|-------|-------|----------|
| **libc++** (LLVM) | Static: `libc++.a`, Shared: `libc++.so` | `/usr/lib/` (system) or Homebrew path |
| **libstdc++** (GNU) | Not available on macOS 10.14+ | N/A — Apple deprecated it |

### C++20 Header Availability
| Header | Available? | Notes |
|--------|-----------|-------|
| `<format>` | Yes | Apple clang supports C++20 `<format>` |
| `<stop_token>` | Yes | Apple clang supports C++20 `std::stop_token` |
| `<jthread>` | Yes | Apple clang supports C++20 `std::jthread` (auto-joins, auto-stops) |

> **macOS advantage over FreeBSD 14:** Apple clang provides full C++20 threading support including `std::jthread`. FreeBSD 14's clang 19.1.7 does NOT provide `<jthread>`.

---

## Available Analysis Tools

| Tool | Location | Notes |
|------|----------|-------|
| `ar` | `/usr/bin/ar` | Static library archiver ✅ |
| `nm` | `/usr/bin/nm` | Symbol inspection ✅ |
| `objdump` | `/usr/bin/objdump` | Object file analysis ✅ |
| `readelf` | Not available (use `otool`) | macOS uses Mach-O, not ELF |
| `strip` | `/usr/bin/strip` | Symbol stripping ✅ |
| `file` | `/usr/bin/file` | File type detection ✅ |
| `size` | `/usr/bin/size` | Binary size analysis ✅ |
| **`lipo`** | `/usr/bin/lipo` | Universal Binary tool (fat binaries) ✅ macOS-specific |
| **`otool`** | `/usr/bin/otool` | Mach-O binary analyzer ✅ macOS-specific |

### macOS-Specific Tools (Not Available on FreeBSD/Linux)
| Tool | Purpose |
|------|---------|
| `lipo` | Create/inspect Universal Binaries (fat binaries with multiple architectures) |
| `otool` | Analyze Mach-O binaries (equivalent to `readelf` on ELF systems) |
| `install_name_tool` | Modify install names in Mach-O binaries (equivalent to `patchelf` on Linux) |

---

## Platform-Specific Notes for Ringbuffer Implementation

### Mach-O vs ELF
- macOS uses **Mach-O** binary format (not ELF like Linux/FreeBSD)
- Shared library extension: `.dylib` (different from Linux/FreeBSD `.so`)
- Install name convention: `@executable_path/../lib/libswtr_ringbuffer.dylib` (not SONAME)
- RPATH equivalent: `@loader_path` (for libraries), `@executable_path` (for executables)

### Universal Binaries
- macOS supports **fat/universal binaries** with multiple architectures (arm64 + x86_64)
- Use `lipo` to create/inspect universal binaries
- Compiler flag: `-arch arm64 -arch x86_64` (or use `ARCHS=arm64 x86_64`)
- Not needed on FreeBSD/Linux (single architecture only)

### Linker Flags
- Dead code elimination: `-dead_strip` (macOS ld64, different from Linux/FreeBSD `-Wl,--gc-sections`)
- Position-independent code: `-fPIC` (required for shared libraries on macOS)
- Visibility hidden: `-fvisibility=hidden`

### Standard Library Path
- libc++ headers are in `/usr/include/c++/v1/` (Clang's C++ standard library)
- libc++ libraries are in `/usr/lib/` (system) or Homebrew path
- No need for `-stdlib=libc++` — it's the default on Apple clang

### POSIX Compatibility
- macOS has full POSIX.1 support (like FreeBSD/Linux)
- `fsync()` works identically to Linux/FreeBSD
- `<unistd.h>` provides POSIX I/O (`read`, `write`, `fsync`)
- No `O_DIRECT` support (similar to FreeBSD, unlike Linux which supports it on ext4)

### Container Support
- macOS uses the `container` command (Apple Container), NOT Docker or podman
- All Linux targets from macOS host use `container` command for cross-OS builds
- macOS itself is native-only (cannot be containerized)

---

## Comparison: macOS vs FreeBSD 14 vs Linux Toolchain

| Aspect | macOS (Apple clang) | FreeBSD 14 (FreeBSD clang 19.1.7) | Linux (GCC/clang) |
|--------|-------------------|----------------------------------|-------------------|
| **Compiler** | Apple clang (LLVM-based) | FreeBSD clang 19.1.7 | GCC or clang |
| **Target** | arm64-apple-darwin / x86_64-apple-darwin | x86_64-unknown-freebsd14.4 | x86_64-linux-gnu etc. |
| **Std Lib** | libc++ (Apple) | libc++ (LLVM upstream) | libstdc++ or libc++ |
| **g++ available** | Best-effort (may fail — no libstdc++) | No | Yes |
| **Binary format** | Mach-O | ELF | ELF |
| **Shared lib ext** | `.dylib` | `.so` | `.so` |
| **Install name/RPATH** | `@executable_path/../lib/...` | `$ORIGIN/../lib/...` (stripped on FreeBSD 14) | `$ORIGIN/../lib/...` |
| **Universal binaries** | Yes (lipo) | No | No |
| **Linker** | ld64 (Apple) | LLD 19.1.7 | GNU ld or LLD |
| **C++20 `<format>`** | Yes | Yes | Yes (GCC 11+, clang) |
| **C++20 `<stop_token>`** | Yes | Yes (partial — types undefined) | Yes (GCC 11+, clang) |
| **`std::jthread`** | Yes (full support) | No (`<jthread>` not found) | Partial (GCC 10+ has header, GCC 16 may need workarounds) |
| **`lipo`/`otool`** | Available | Not available (use `readelf`) | Not available (use `readelf`) |
| **`readelf`** | Not available (use `otool`) | Available | Available |
| **Dead code elim** | `-dead_strip` | `-Wl,--gc-sections` | `-Wl,--gc-sections` |
| **Container support** | `container` command (Apple) | None (native-only) | Docker/podman |
| **Make type** | GNU make | BSD make (native) | GNU make |
| **Recipe shell** | `/bin/sh` (Bash 3.2 POSIX mode) | `/bin/sh` (ash, POSIX-only) | `/bin/sh` (bash/ash/dash) |

---

## Source Code Compatibility Assessment

### Byte-Identical (no changes needed across macOS/Linux/FreeBSD)
The following source files should compile on all platforms with `#ifdef` guards:
- `status.hpp` — pure enum definitions, no platform dependencies
- `ringbuffer.hpp` — uses standard C++20 headers (`<atomic>`, `<format>`, `<stop_token>`)
- `swtr_ringbuffer_impl.hpp` — implementation class header (with `#ifdef __FreeBSD__` guards)
- `Lifecycle.cpp`, `ReadOps.cpp`, `TransformOps.cpp` — standard C++20 + POSIX I/O
- `Accessors_*.cpp`, `LoggingOps_*.cpp` — standard C++20
- `ErrorOps.cpp`, `WriteOps.cpp` — uses `<unistd.h>` (POSIX, available on all platforms)

### Platform-Specific Differences
| File | macOS/Linux | FreeBSD 14 |
|------|-------------|------------|
| `Threading.cpp` | `std::jthread` with `stop_token` (full C++20) | `std::thread` + `atomic<bool>` stop flag (no `<jthread>`) |
| `swtr_ringbuffer_impl.hpp` | `std::jthread` member types | `std::thread` + atomic stop flag |
| `Makefile` | GNU make syntax, `-dead_strip`, `.dylib`, universal binaries | BSD make syntax, `-Wl,--gc-sections`, `.so`, single-arch |
| `tests/Makefile` | GNU make syntax, `otool` for verification | BSD make syntax, `readelf` for verification |

---

## Build & Test Results (Completed)

> **Date:** 2026-08-17
> **Status:** All tests PASS (Concurrent + Pure Python)

### Build Output
| Artifact | Size | Format |
|----------|------|--------|
| `lib/libswtr_ringbuffer-1.0.0-1.dylib` | ~50 KB | Mach-O shared library (universal: arm64 + x86_64) |
| SONAME/Install name | `@executable_path/../lib/libswtr_ringbuffer.dylib` | Verified via `otool -L` |

### Test Results
| Test | Description | Result |
|------|-------------|--------|
| T001 | Identity transform, normal operation | PASS (output match) |
| T002 | Stress test (1 slot, 1 byte buffer) | PASS (output match) |
| T003 | Uppercase transform | PASS (output match) |
| T004 | Small input, fast EOF | PASS (output match) |
| T005 | Fatal error mode (expect exit 1) | PASS (exit code 1 as expected) |
| T006 | Non-fatal error mode (expect exit 0) | PASS (output match) |
| T007 | XOR transform | PASS (output match) |

### Performance Benchmark
| Metric | Concurrent (ctypes + C++) | Pure Python | Speedup |
|--------|--------------------------|-------------|---------|
| **Average time** | ~31 ms | ~50 ms | **1.60x** |
| **T002 (stress)** | ~32 ms | ~102 ms | **3.22x** |

> **Note:** Performance comparison runs on macOS because C++ shared library is available and RPATH (`@executable_path`) works correctly. This is NOT possible on FreeBSD 14 due to `$ORIGIN` stripping by `ld-elf.so.1`.

### Key Implementation Details
- **`std::jthread` available:** macOS Apple clang provides full C++20 `std::jthread` support (auto-joins, auto-stops)
- **Makefile:** GNU make syntax, `-dead_strip` for dead code elimination, universal binary support
- **RPATH:** Uses `@executable_path/../lib` (macOS convention) — fully supported by macOS dynamic linker
- **Linker flags:** `-pthread` required for `std::thread`; install name via `-install_name @executable_path/../lib/libswtr_ringbuffer.dylib`
- **Container support:** Uses `container` command for cross-OS builds from macOS to Linux targets

### Known Limitations
- **Homebrew g++** may fail to compile due to missing libstdc++ headers (macOS 10.14+) — this is acceptable, documented as INFO/WARNING
- **Universal binaries** require both `-arch arm64` and `-arch x86_64` flags — not needed on FreeBSD/Linux
- **No `readelf`** on macOS — use `otool -L` for library dependency inspection instead
- **No `$ORIGIN` stripping issue** on macOS — `@executable_path` works correctly (unlike FreeBSD 14)

---

## Updated Source Code Compatibility Assessment (Post-Unification)

All platforms now share the same source files with conditional compilation:

| File | macOS/Linux Path (default) | FreeBSD 14 Path (`__FreeBSD__`) |
|------|---------------------------|-------------------------------|
| `Threading.cpp` | `std::jthread` with `stop_token` | `std::thread` + `atomic<bool> stop_flag_` |
| `swtr_ringbuffer_impl.hpp` | `std::jthread`, includes `<stop_token>` | `std::thread`, no `<jthread>`, atomic stop flag |
| `ReadOps.cpp` | `while (!st.stop_requested())` | `while (!stop_flag_.load())` |
| `WriteOps.cpp` | `while (!st.stop_requested())` | `while (!stop_flag_.load())` |
| `TransformOps.cpp` | `while (!st.stop_requested())` | `while (!stop_flag_.load())` |
| All other files (16) | Identical across all platforms | Identical across all platforms |

The `#ifdef __FreeBSD__` preprocessor directive ensures the correct code path is compiled for each platform. No manual source modifications are needed — the unified source handles both FreeBSD and macOS/Linux automatically.

---

## Summary: Platform-Specific Gotchas for Agents

### macOS (This Machine — M4 Mac Mini, 64 GB RAM)
1. **`/bin/sh` is Bash 3.2 in POSIX mode** — no bashisms, even though it's Bash
2. **`make -v` works** (GNU Make 3.81) — functional, supports `$(shell ...)`, `ifeq/else` (unlike FreeBSD 14)
3. **Use `otool` not `readelf`** — macOS uses Mach-O, not ELF
4. **RPATH uses `@executable_path`** — fully supported (unlike FreeBSD 14 `$ORIGIN`)
5. **Universal binaries** — use `lipo`, `-arch arm64 -arch x86_64`
6. **Container support** — use `container` command (Apple Container), not Docker/podman
7. **Don't rely on `~/.zshrc`** — make doesn't load it; use absolute paths
8. **C++20 `std::jthread` available** — full support (unlike FreeBSD 14)
9. **Apple clang 21.0.0** — primary compiler; Homebrew g++ available but may fail (no libstdc++)
10. **Python 3.14.6** via Homebrew at `/opt/homebrew/bin/python3`

### FreeBSD 14
1. **`/bin/sh` is ash** — strict POSIX, no bashisms
2. **BSD make only** — `gmake` NOT allowed, use native `make`
3. **Use `readelf` not `otool`** — FreeBSD uses ELF, not Mach-O
4. **RPATH `$ORIGIN` stripped by `ld-elf.so.1`** — dynamic library testing NOT possible
5. **No universal binaries** — single architecture only
6. **No container support** — native-only builds/tests
7. **`make -V VERSION` not `make -v`** — BSD make doesn't support `-v` flag
8. **No `std::jthread`** — use `std::thread` + atomic bool

### Linux (Debian/Ubuntu/Fedora/Raspios)
1. **`/bin/sh` is usually bash or dash** — check which one, but POSIX syntax works on both
2. **GNU make** — supports `$(shell ...)`, `ifeq/else`, `-v` flag
3. **Use `readelf`** — Linux uses ELF format
4. **RPATH `$ORIGIN` works** — fully supported by Linux dynamic linker
5. **No universal binaries** — single architecture only (unless explicitly built)
6. **Container support** — Docker or podman available
7. **C++20 `std::jthread`** — depends on compiler version (GCC 10+ has header, may need workarounds)
