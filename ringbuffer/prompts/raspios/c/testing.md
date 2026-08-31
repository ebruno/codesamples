# C Testing — Raspberry Pi OS

**Note:** C is a platform-sensitive language. Source code differs across platforms (threading, I/O, build flags).
Use `prompts/common/c/functional.md` and `prompts/common/c/build.md` as the primary specifications.
Per-OS overrides may be needed for platform-specific threading and I/O multiplexing tests.

## Execution Notes
- **Build System**: GNU Make (`Makefile`) with `include version.mk`.
- **Compiler**: Primary target is C23 (C17/C11 fallback). Detect available compiler version.
- **Platform differences**: Shared library naming (`.so` on Linux), linker options, arm64 architecture.
- **Test matrix**: T001-T007 applies to all implementations.
