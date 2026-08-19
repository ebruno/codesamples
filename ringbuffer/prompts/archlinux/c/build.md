# C Build — <OS>

**Note:** C is a platform-sensitive language. Source code differs across platforms (threading, I/O, build flags).
Use `prompts/common/c/build.md` and `prompts/common/c/functional.md` as the primary specifications.
Per-OS overrides may be needed for platform-specific build flags (shared lib naming, linker options).

## Build Notes
- **Build System**: GNU Make (`Makefile`) with `include version.mk`.
- **Compiler**: Primary target is C23 (C17/C11 fallback). Detect available compiler version.
- **Platform differences**: Shared library naming (`.so` on Linux, `.dylib` on macOS), linker options, universal binary support on macOS.
- **C++ shared library dependency**: None — C is a standalone implementation.
