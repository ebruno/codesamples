# C Build — FreeBSD 14

**Note:** C is a platform-sensitive language. Source code differs across platforms (threading, I/O, build flags).
Use `prompts/common/c/build.md` and `prompts/common/c/functional.md` as the primary specifications.
Per-OS overrides may be needed for platform-specific build flags (shared lib naming, linker options).

## Build Notes
- **Build System**: GNU Make (`Makefile`) with `include version.mk`.
  - FreeBSD 14 uses BSD make syntax — no `$(shell)`, no `ifeq/else`.
  - If per-OS BSD Makefile does not exist yet, fall back to `src/common/c/Makefile.gnu` (GNU make).
- **Compiler**: Primary target is C23 (C17/C11 fallback). Detect available compiler version.
- **RPATH limitation**: FreeBSD 14's `ld-elf.so.1` does NOT support `$ORIGIN` in RUNPATH — dynamic library testing is not possible.
  - Static library only (`make verify` target).
- **C++ shared library dependency**: None — C is a standalone implementation.
