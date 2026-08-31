# Rust Build — FreeBSD 14

**Note:** Rust is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/rust/build.md` and `prompts/common/rust/functional.md` as the primary specifications.
No platform-specific build overrides are needed for Rust on FreeBSD 14.

## Build Notes
- **Build System**: Cargo (`Cargo.toml`) with `build.rs` for version injection.
  - If per-OS BSD Makefile does not exist yet, fall back to `src/common/rust/Makefile.gnu` (GNU make).
- **RPATH limitation**: FreeBSD 14's `ld-elf.so.1` does NOT support `$ORIGIN` in RUNPATH — dynamic library testing is not possible.
  - Static library only (`make verify` target).
- **C++ shared library dependency**: Rust build depends on the C++ shared library from `src/freebsd14/cpp/`. If that directory or its Makefile is missing, the build falls back to pure Rust only.
- **Rust version**: Primary target is Rust 1.84.0, with fallback to Rust 1.56.0 as needed.
