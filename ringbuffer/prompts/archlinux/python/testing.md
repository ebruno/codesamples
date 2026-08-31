# Python Testing — Arch Linux

**Note:** Python is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/python/functional.md` and `prompts/common/python/build.md` as the primary specification.
No platform-specific overrides are needed for Python on Arch Linux.

## Execution Notes
- **Linux-hosts-only**: Arch Linux has no container images for Apple Silicon. On macOS hosts, skip with a logged message.
- **Native on Linux**: Run natively on Arch Linux hosts using `src/common/python/Makefile.gnu`.
- **C++ shared library**: Python tests attempt to build the C++ shared library from `src/archlinux/cpp/`. If that directory or its Makefile is missing, tests fall back to Pure Python only.
- **Python version**: Primary target is Python 3.14, with fallback to 3.12/3.13 as needed.
