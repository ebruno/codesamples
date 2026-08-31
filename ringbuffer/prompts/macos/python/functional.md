# Python Functional Spec — <OS>

**Note:** Python is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/python/functional.md` as the primary specification.
No platform-specific functional overrides are needed for Python on <OS>.

## Functional Notes
- **Dual implementation**: Concurrent (ctypes + C++ shared library) and Pure Python.
- **RPATH limitation**: FreeBSD 14's `ld-elf.so.1` does NOT support `$ORIGIN` in RUNPATH — dynamic library testing is not possible. Only Pure Python tests run on FreeBSD 14.
- **Test matrix**: T001-T007 applies to both implementations (Concurrent skipped on FreeBSD 14).
