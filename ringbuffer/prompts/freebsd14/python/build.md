# Python Build — FreeBSD 14

**Note:** Python is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/python/build.md` and `prompts/common/python/functional.md` as the primary specifications.
No platform-specific build overrides are needed for Python on FreeBSD 14.

## Build Notes
- **Makefile**: Use BSD make syntax (`src/freebsd14/python/Makefile`) — no `$(shell)`, no `ifeq/else`.
  - If per-OS BSD Makefile does not exist yet, fall back to `src/common/python/Makefile.gnu` (GNU make).
- **RPATH limitation**: FreeBSD 14's `ld-elf.so.1` does NOT support `$ORIGIN` in RUNPATH — dynamic library testing is not possible.
  - Concurrent (ctypes) tests are SKIPPED on FreeBSD 14.
  - Pure Python tests run normally — they have no C++ shared library dependency.
- **C++ shared library**: The Python build depends on the C++ shared library from `src/freebsd14/cpp/`. If that directory or its Makefile is missing, the build falls back to Pure Python only.
- **Python version**: Primary target is Python 3.14, with fallback to 3.12/3.13 as needed.
