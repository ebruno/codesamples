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

> **Note:** This is specific to macOS Make. Linux Make does not have this built-in default, so `?=` works there. But for cross-platform consistency, always use `:=` on macOS.

---

## 6. Mermaid Diagram Compatibility Gotcha

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

## 7. Cross-Reference Summary

> **Host OS detection, macOS versioning, Linux /etc/os-release, container runtime** → `prompts/common/session_hints.md`
> **Source organization, naming conventions, include discipline** → `prompts/common/cpp/functional.md`
> **Build flags, Makefile targets, artifact naming** → `prompts/common/cpp/build.md`
> **Test matrix T001-T007, scripting mandate** → `prompts/common/cpp/testing.md`
