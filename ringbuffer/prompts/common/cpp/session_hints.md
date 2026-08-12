# C++ Session Hints — Ringbuffer Project

**When to read:** When working on C++ source code, Makefiles, or build configurations.
This file provides a quick-reference card with cross-links to detailed specs.

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

## 5. Container Runtime Quick-Reference (Linux Builds from macOS Host)

When building Linux targets from macOS:
- **Runtime:** `container` command (Apple Container) — NOT Docker, NOT podman
- **Service must be running:** `container system status` → if not running, `container system start`
- **Key subcommands:** `container run`, `container build`, `container images`
- **Memory limit:** Calculate from `vm_stat` on macOS host, cap at 3 GB

When building Linux targets from Linux:
- **Runtime:** `podman` — NOT Docker
- **No service start needed** (podman is stateless)

---

## 6. Cross-Reference Summary

> **Source organization, naming conventions, include discipline** → `prompts/common/cpp/functional.md`
> **Build flags, Makefile targets, artifact naming** → `prompts/common/cpp/build.md`
> **Test matrix T001-T007, scripting mandate** → `prompts/common/cpp/testing.md`
