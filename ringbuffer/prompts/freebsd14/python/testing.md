# Python Testing — FreeBSD 14

**Note:** Python is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/python/functional.md` and `prompts/common/python/build.md` as the primary specification.
No platform-specific overrides are needed for Python on FreeBSD 14.

## Execution Notes
- **Native only**: FreeBSD is native-only — no containers, Dockerfiles, or `container`/`podman` targets.
- **Makefile**: Use BSD make syntax (`src/freebsd14/python/Makefile`) — no `$(shell)`, no `ifeq/else`.
  - If per-OS BSD Makefile does not exist yet, fall back to `src/common/python/Makefile.gnu` (GNU make).
- **RPATH limitation**: FreeBSD 14's `ld-elf.so.1` does NOT support `$ORIGIN` in RUNPATH — dynamic library testing is not possible.
  - **Concurrent (ctypes) tests are SKIPPED** on FreeBSD 14.
  - **Pure Python tests run normally** — they have no C++ shared library dependency.
- **C++ shared library**: Python tests attempt to build the C++ shared library from `src/freebsd14/cpp/`. If that directory or its Makefile is missing, tests fall back to Pure Python only.
- **Python version**: Primary target is Python 3.14, with fallback to 3.12/3.13 as needed.
