# C Functional Spec — FreeBSD 14

**Note:** C is a platform-sensitive language. Source code differs across platforms (threading, I/O, build flags).
Use `prompts/common/c/functional.md` as the primary specification.
Per-OS overrides may be needed for platform-specific threading (pthread) and I/O multiplexing.

## Functional Notes
- **Three-stage pipeline**: Independent read, transform, and write stages operating on a shared pool of buffer slots.
- **Status-driven coordination**: Slots transition through states (`readyforread` → `readyfortransform` → `readyforwrite` → `readyforread`).
- **Cooperative cancellation**: Pipeline stages support graceful shutdown via a stop signal.
- **RPATH limitation**: FreeBSD 14's `ld-elf.so.1` does NOT support `$ORIGIN` in RUNPATH — dynamic library testing is not possible.
  - Static library only (`make verify` target).
- **Test matrix**: T001-T007 applies to all implementations (static library only on FreeBSD 14).
