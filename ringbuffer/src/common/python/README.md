# Swtr Ringbuffer Library (Python)

## Description
A pure Python ring buffer implementation using `ctypes` FFI to load the shared C library. This platform-insensitive implementation is shared across all operating systems (macOS, Fedora, Debian, Ubuntu) from a single codebase in `src/common/python/`.

## Build Requirements

- **Language**: Python 3.14 (primary), with fallback to Python 3.10+
- **Build System**: None (interpreted language)
- **Version Source**: `version.mk` — read by `version.sh` to generate `version.py`
- **Dependency**: C shared library (`libswtr_ringbuffer.so` / `.dylib`) loaded via `ctypes`

## Building

### Version Propagation
The `version.sh` script reads `version.mk` and generates `version.py`:
```bash
./version.sh          # Generates version.py with constants from version.mk
```

### Verification
```bash
python3 -m py_compile swtr_ringbuffer.py   # Syntax check
python3 -c "import swtr_ringbuffer"         # Import verification
```

## Library Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Version module | `version.py` | Generated from `version.mk` via `version.sh` |
| Main module | `swtr_ringbuffer.py` | Pure Python ring buffer implementation |
| Test module | `test_ringbuffer.py` | T001–T007 test suite |

## Architecture

- **SwtrRingBuffer**: Pure Python implementation using `ctypes` to load the C shared library
- **Version constants**: `MAJOR`, `MINOR`, `SUBVERSION`, `BUILD_ID`, `VERSION` injected from `version.mk`
- **ctypes FFI**: Loads `libswtr_ringbuffer.so` (Linux) or `.dylib` (macOS) for the native ring buffer implementation

## Test Results

Pure Python implementation verified via:
- `py_compile` syntax check — passes
- Module import verification — passes
- Class instantiation test — passes

## Platform Notes

Python is **platform-insensitive** — the same source code runs on all supported operating systems. No per-OS overrides are needed; a single common spec generates identical source for all platforms. The only platform dependency is the C shared library, which must be built separately for each target OS.
