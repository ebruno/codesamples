# C++ Build — FreeBSD 14

**Note:** This is a placeholder pointing to the authoritative FreeBSD C++ build spec.
For actual implementation details, see `prompts/freebsd/cpp/build.md` (generic FreeBSD 14.x/15.x spec) and `prompts/common/cpp/build.md` (common requirements).

## Build Notes
- **Compiler**: FreeBSD clang++ (only compiler available — no g++)
- **Build System**: GNU Make (`Makefile`) with `include version.mk`.
  - FreeBSD uses BSD make syntax — no `$(shell)`, no `ifeq/else`.
- **RPATH limitation**: FreeBSD 14's `ld-elf.so.1` does NOT support `$ORIGIN` in RUNPATH — dynamic library testing is not possible.
  - Static library only (`make verify` target).
- **C++ Standard**: C++20 primary, C++17 fallback.
