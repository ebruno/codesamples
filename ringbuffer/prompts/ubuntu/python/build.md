# Python Build — <OS>

**Note:** Python is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/python/build.md` and `prompts/common/python/functional.md` as the primary specifications.
No platform-specific build overrides are needed for Python on <OS>.

## Build Notes
- **Makefile**: Use `src/common/python/Makefile.gnu` (GNU make on macOS and Linux).
- **BSD make**: FreeBSD 14+ uses BSD make syntax (`src/<os>/python/Makefile`) — no `$(shell)`, no `ifeq/else`.
- **C++ shared library**: The Python build depends on the C++ shared library from `src/<os>/cpp/`. If that directory or its Makefile is missing, the build falls back to Pure Python only.
- **Python version**: Primary target is Python 3.14, with fallback to 3.12/3.13 as needed.
