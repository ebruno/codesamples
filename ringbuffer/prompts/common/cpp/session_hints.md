# C++ Session Hints — Ringbuffer Project

**When to read:** When working on C++ source code, Makefiles, or build configurations.
This file provides a quick-reference card with cross-links to detailed specs.

> **Read first:** `prompts/common/session_hints.md` for host OS detection, macOS/Linux versioning,
> container runtime, and memory calculation. This file covers C++-specific toolchain, binary formats,
> linking flags, and Makefile gotchas.

---

## Quick Reference Index

| Topic | Detailed Spec |
|-------|--------------|
| Source file organization, naming conventions, include discipline | `prompts/common/cpp/functional.md` |
| Build flags, Makefile targets, artifact naming, optimization goals | `prompts/common/cpp/build.md` |
| Test infrastructure, test matrix T001-T007, scripting mandate | `prompts/common/cpp/testing.md` |

---

## 1. Platform-Specific Toolchain Quick-Reference

### Linux Tools
| Tool | Purpose | Example |
|------|---------|---------|
| `g++` / `clang++` | Compiler | `g++ --version` |
| `ar` | Static library archive | `ar rcs lib.a obj.o` |
| `nm` | Symbol inspection | `nm -gU lib.so` |
| `readelf` | ELF binary analysis | `readelf -d lib.so` (SONAME) |
| `ld` / `lld` | Linker version | `ld -v` |
| `size` | Binary size analysis | `size lib.a lib.so` |

### Linux Package Managers (Per Distro)
| Distro | Package Manager | Install Command |
|--------|----------------|-----------------|
| Fedora | `dnf` | `sudo dnf install -y gcc-c++ clang make binutils` |
| Debian/Ubuntu | `apt-get` | `sudo apt-get install -y g++ clang make binutils` |
| Arch Linux | `pacman` | `sudo pacman -S --needed base-devel gcc clang binutils` |

### Arch Linux Notes (C++ Toolchain)
- **Package names** are the same as other distros (`gcc`, `clang`), but installed via `pacman`
- **`base-devel` group** is the Arch equivalent of Fedora's `gcc-c++` / Debian's `build-essential` — includes `make`, `binutils`, `gcc`, and related tools
- **Rolling release advantage**: Arch typically ships the latest compiler versions, so primary version detection (C++20) usually succeeds without fallback
- **No `VERSION_ID`**: When detecting Arch in scripts, use `ID=arch` from `/etc/os-release`; do not parse `VERSION_ID`
- **Container images**: Use datestamp tags (e.g., `archlinux:2026.08.01`) — see Section 4A of `prompts/common/session_hints.md`

### macOS Tools
| Tool | Purpose | Example |
|------|---------|---------|
| `clang++` | Compiler (default) | `clang++ --version` |
| `ar` | Static library archive | `ar rcs lib.a obj.o` |
| `nm` | Symbol inspection | `nm -gU lib.dylib` |
| `otool` | Mach-O binary analysis | `otool -L lib.dylib` (install name) |
| `lipo` | Universal binary inspection | `lipo -info lib.a` (arm64 + x86_64) |
| `ld` | Linker version | `ld -v` |
| `size -m` | Binary size (megabyte output) | `size -m lib.a` |

### Universal Binaries (macOS Only)
macOS builds MUST produce fat binaries with both `arm64` and `x86_64` slices:
```bash
lipo -info lib/libswtr_ringbuffer.dylib   # Should show both architectures
```

---

## 2. Binary Format Quick-Reference

| Aspect | Linux (ELF) | macOS (Mach-O) |
|--------|-------------|----------------|
| Shared lib extension | `.so` | `.dylib` |
| SONAME / Install Name | `SONAME [libswtr_ringbuffer.so]` (readelf) | `@rpath/libswtr_ringbuffer.dylib` (otool) |
| Architecture check | `file -L lib.so` → "ELF 64-bit" | `file -L lib.dylib` → "Mach-O" |
| Symbol visibility check | `nm -gjU lib.so` | `nm -gU lib.dylib` |
| Dead code elimination | `-Wl,--gc-sections` (linker flag) | `-dead_strip` (linker flag) |
| Universal binaries | N/A | `lipo -info` shows arm64 + x86_64 |

---

## 3. Shared Library Linking Quick-Reference

### Linux
- SONAME must be `libswtr_ringbuffer.so` (not versioned)
- RPATH should point to the `lib/` directory relative to the binary location
- Use `-Wl,-rpath,$ORIGIN/../lib` for test binaries

### macOS
- Install name must be `@rpath/libswtr_ringbuffer.dylib`
- Use `-install_name @rpath/libswtr_ringbuffer.dylib -current_version <VER> -compatibility_version <VER>`
- Test binaries need `-rpath @executable_path/../lib` or equivalent

---

## 4. Common C++ Pitfalls

1. **Include guard / `#pragma once`:** Every header MUST have include protection
2. **Missing `-fPIC` on Linux:** Shared libraries require position-independent code
3. **Wrong install name on macOS:** Must use `@rpath/`, not absolute paths
4. **Symbol visibility leaks:** With `-fvisibility=hidden`, only explicitly exported symbols are visible
5. **Stale symlinks:** After version changes, regenerate all `lib/` symlinks
6. **Missing `$(RM)` macro:** Use `$(RM)` not `rm -f` for portability in Makefiles

---

## 5. macOS Make Built-in Defaults Gotcha

macOS ships with GNU Make that has built-in defaults for `CXX = c++`. These are processed **before** your makefile is read, so:

- `CXX ?= clang++` **will NOT work** — Make sees CXX is already defined (from built-in defaults) and skips the assignment
- `CXX := clang++` **will work** — simple expansion always wins over built-in defaults
- Command-line override `make CXX=g++` **still works** — command-line variables have highest precedence of all

**Rule:** Always use `CXX := clang++` (or `g++`) in macOS Makefiles, never `?=`.

**Verification:** Run `make -p -f /dev/null | grep CXX` to see all built-in defaults.

> **Note:** This is specific to macOS Make. Linux Make does not have this built-in default, so `?=` works there. But for cross-platform consistency, always use the pattern below on macOS.

**Recommended Pattern:**
```makefile
CXX ?= clang++
ifeq ($(CXX),c++)
  CXX := clang++
endif
```
This lets command-line overrides (`make CXX=g++`) work while still defaulting to `clang++` on macOS.

---

## 6. Homebrew g++ on macOS — Universal Binary Limitation

**Problem:** Homebrew's `g++` (e.g., GCC 16.1.0) on Apple Silicon does not support the `-arch` flag. When compiling with `CXX=g++`, both arm64 and x86_64 object files end up as arm64, causing `lipo -create` to fail.

**Behavior:** The Makefile detects this and falls back gracefully:
- **clang++**: Produces universal binaries (arm64 + x86_64) ✅
- **g++**: Produces arm64-only binaries with a warning ⚠️

**Use case for g++ on macOS:** Validating that source code compiles with GNU toolchain. For production builds requiring universal binaries, use `clang++`.

**Report Flagging:** When g++ is used on macOS, the Makefile emits a `WARNING:` message during build. This warning MUST be captured in the build log and flagged as INFO (not ERROR) in the regression report. The report entry should state:
```
[INFO] Universal binary: arm64-only (Homebrew g++ does not support -arch x86_64 on Apple Silicon)
```
This is acceptable behavior — not a build failure.

---

## 7. Cross-Platform File Sync (fsync)

**Unified Approach:** The `platform_fsync()` wrapper that previously used `#if defined(__APPLE__)` to call `F_FULLFSYNC` on macOS and `fsync()` on Linux has been eliminated. All platforms now use the direct POSIX `fsync(fd)` call.

**Rationale:**
- macOS `fsync()` provides adequate durability for the library's use case
- Eliminates a source of platform-specific code divergence
- `fcntl(fd, F_FULLFSYNC)` is macOS-only and requires `<fcntl.h>` — adding platform-specific includes to source files
- The library's goal is byte-identical source across all platforms; minimal `#ifdef` guards are acceptable only for truly unavoidable OS syscalls
- Both clang++ and g++ handle `fsync()` identically — no compiler-specific behavior differences

**Implementation:** In `WriteOps.cpp`, the write loop calls `fsync(fd)` directly when processing `LAST_BUFFER_TO_WRITE`. No wrapper function, no conditional compilation.

---

## 8. Mermaid Diagram Compatibility Gotcha

**Problem:** Mermaid diagrams that render correctly on GitHub (Mermaid v10) may fail in Safari on GitLab 19+ (Mermaid v11), while still working in Chrome on both platforms.

**Root cause:** The `direction TB` (or any `direction`) keyword inside subgraphs creates a nested direction conflict when combined with the outer `flowchart LR` layout. Mermaid v10 handles this consistently across browsers. Mermaid v11 changed the SVG output for nested directions, and WebKit (Safari) is stricter about rendering the resulting SVG — it may produce overlapping elements, incorrect transform matrices, or a completely broken/invisible diagram. Blink (Chrome) is more forgiving and silently renders it correctly.

**Symptoms:**
- Diagram works on GitHub (any browser) ✅
- Diagram works in Chrome on GitLab ✅
- Diagram broken or invisible in Safari on GitLab ❌

**Fix:** Remove `direction` declarations from inside subgraphs. The outer `flowchart LR` direction still governs the overall layout:

```mermaid
# ❌ Broken in Safari + GitLab (Mermaid v11)
flowchart LR
    subgraph ReadThread ["Read Thread"]
        direction TB          ← REMOVE THIS
        R1 --> R2
    end
```

```mermaid
# ✅ Works everywhere
flowchart LR
    subgraph ReadThread ["Read Thread"]
        R1 --> R2
    end
```

**Rule:** Never use `direction` inside subgraphs. Use it only at the top level of a flowchart.

---

## 9. Conditional Compilation Rule

When a platform lacks a C++ feature available on other platforms, use `#ifdef` blocks to provide an alternative implementation for that OS **only**. Never modify the common code path or "down-rev" features for all other platforms.

- **Full rule**: [prompts/common/conditional_compilation_rule.md](../conditional_compilation_rule.md)
- **Golden Rule reference**: `prompts/common/generate_toplevel_readme.md` — Part A.1
- **Key principle**: The non-conditional code path remains byte-identical across all platforms. Conditional blocks are the exception, not the rule.

---

## 10. Ubuntu 24.04 Clang++ Unsupported

**Problem:** On Ubuntu 24.04, `clang++` (LLVM 18) fails to compile C++20 code with errors like `'atomic' file not found`.

**Root cause:** Ubuntu 24.04 ships `gcc-14-base` and `libgcc-14-dev` but only `g++-13` (C++ headers in `/usr/include/c++/13`). Clang 18 was built against GCC 14 and looks for headers in `/usr/include/c++/14`, which does not exist.

**Symptoms:**
- `clang++ -std=c++20 -c test.cpp` fails with `'atomic' file not found`
- `g++` compiles successfully (uses `/usr/include/c++/13`)
- `make all-clang++` fails while `make all-g++` succeeds

**Resolution:** **clang++ is unsupported on Ubuntu.** Use `g++` as the compiler for all build and test operations. The Dockerfiles include clang packages for reference but only g++ is used in practice.

---

## 12. Cross-Compiler ABI Compatibility (clang++ ↔ g++)

For detailed compatibility analysis, standard library behavior across platforms, and C++ version caveats, see [appendices/cpp-cross-compiler-compatibility.md](../appendices/cpp-cross-compiler-compatibility.md).

**Quick rule:** On macOS, clang++ is the primary supported compiler. g++ support is best-effort — see the appendix for details.

## 14. FreeBSD 14 RPATH Limitation

**Problem:** FreeBSD 14's `ld-elf.so.1` dynamic linker does **not** support `$ORIGIN` in RUNPATH/RPATH entries.

**Root cause:** When a binary has `$ORIGIN/../lib` in its RUNPATH, FreeBSD's dynamic linker strips `$ORIGIN` to an empty string at runtime. This causes the shared library lookup to fail because the path becomes `/../lib` which is invalid.

**Impact:**
- **Dynamic library testing is NOT possible on FreeBSD 14.** The test binary cannot find `libswtr_ringbuffer.so` at runtime.
- **Static library testing works fine.** The `make verify` target (which uses static libraries) passes all 7 tests.
- **Shared library can still be built** — it just cannot be tested at runtime on this platform.

**Workaround:** Use static library only for regression testing on FreeBSD 14. The `tests/Makefile` has a `verify` target that builds and runs tests against the static library (`libswtr_ringbuffer.a`).

**Verification:** Run `readelf -d <binary>` to check RPATH/RUNPATH entries. On FreeBSD 14, `$ORIGIN` will appear in the binary but will be stripped at runtime.

**Reference:** See [freebsd-platform-analysis.md](../appendices/freebsd-platform-analysis.md) for full analysis and TODO items.

## 15. Cross-Reference Summary

> **Host OS detection, macOS versioning, Linux /etc/os-release, container runtime** → `prompts/common/session_hints.md`
> **Source organization, naming conventions, include discipline** → `prompts/common/cpp/functional.md`
> **Build flags, Makefile targets, artifact naming** → `prompts/common/cpp/build.md`
> **Test matrix T001-T007, scripting mandate** → `prompts/common/cpp/testing.md`
> **Conditional compilation rule** → `prompts/common/conditional_compilation_rule.md`
