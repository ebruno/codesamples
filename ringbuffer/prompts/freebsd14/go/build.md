# Go Build — FreeBSD 14

**Note:** Go is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/go/build.md` and `prompts/common/go/functional.md` as the primary specifications.
No platform-specific build overrides are needed for Go on FreeBSD 14.

## Build Notes
- **Build System**: Go Modules (`go.mod`) — no per-OS Makefile needed.
  - If per-OS BSD Makefile does not exist yet, fall back to `src/common/go/Makefile.gnu` (GNU make).
- **RPATH limitation**: FreeBSD 14's `ld-elf.so.1` does NOT support `$ORIGIN` in RUNPATH — dynamic library testing is not possible.
  - Static library only (`make verify` target).
- **C++ shared library dependency**: Go build depends on the C++ shared library from `src/freebsd14/cpp/`. If that directory or its Makefile is missing, the build falls back to pure Go only.
- **Go version**: Primary target is Go 1.24, with fallback to Go 1.23/1.22 as needed.
