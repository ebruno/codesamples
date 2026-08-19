# C Testing — FreeBSD 14

**Note:** C is a platform-sensitive language. Source code differs across platforms (threading, I/O, build flags).
Use `prompts/common/c/functional.md` and `prompts/common/c/build.md` as the primary specifications.
Per-OS overrides may be needed for platform-specific threading and I/O multiplexing tests.

## Execution Notes
- **Build System**: GNU Make (`Makefile`) with `include version.mk`.
  - FreeBSD 14 uses BSD make syntax — no `$(shell)`, no `ifeq/else`.
- **Compiler**: Primary target is C23 (C17/C11 fallback). Detect available compiler version.
- **RPATH limitation**: FreeBSD 14's `ld-elf.so.1` does NOT support `$ORIGIN` in RUNPATH — dynamic library testing is not possible.
  - Static library only (`make verify` target).
- **Test matrix**: T001-T007 applies to all implementations (static library only on FreeBSD 14).
