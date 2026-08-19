# Python Testing — Ubuntu

**Note:** Python is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/python/functional.md` and `prompts/common/python/build.md` as the primary specification.
No platform-specific overrides are needed for Python on Ubuntu.

## Execution Notes
- **Container**: Use `container` (macOS host) or `podman` (Linux host) with image from `src/common/python/containers/ubuntu/build/Dockerfile`.
- **Makefile**: Use `src/common/python/Makefile.gnu` (GNU make on Ubuntu).
- **C++ shared library**: Python tests attempt to build the C++ shared library from `src/ubuntu/cpp/`. If that directory or its Makefile is missing, tests fall back to Pure Python only.
- **Python version**: Primary target is Python 3.14, with fallback to 3.12/3.13 as needed.
