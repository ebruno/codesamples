# Swtr Ringbuffer Library (Python)

## Description
A dual-version Python ring buffer implementation with auto-selection between two implementations:

1. **Concurrent** (ctypes + C++ shared library) — high-throughput, thread-safe concurrent I/O
2. **Pure Python** (no dependencies) — full feature parity, no external requirements

Both implementations are platform-insensitive and shared across all operating systems (macOS, Fedora, Debian, Ubuntu) from a single codebase in `src/common/python/`.

## Dual-Version Architecture

### Concurrent (ctypes)
- Uses `ctypes` FFI to load the C++ shared library (`libswtr_ringbuffer.so` / `.dylib`)
- Provides thread-safe concurrent readers/writers via the C++ implementation
- Best for: small inputs (< 1KB), stress tests, concurrent workloads
- Entry point: `from swtr_ringbuffer import SwtrRingBuffer` (auto-selects when available)

### Pure Python
- No external dependencies — pure Python implementation
- Full feature parity with Concurrent version (all 38 ABC methods implemented)
- Best for: large files (> 100KB), environments without C++ library, fallback
- Entry point: `from swtr_ringbuffer_pure import SwtrRingBufferPure`

### Auto-Selection
The package `swtr_ringbuffer/` automatically selects the best available implementation:

```python
from swtr_ringbuffer import SwtrRingBuffer  # Concurrent if available, Pure Python fallback

# Check which version is active
print(SwtrRingBuffer._version)  # "Concurrent" or "Pure Python"
```

## Build Requirements

- **Language**: Python 3.14 (primary), with fallback to Python 3.10+
- **Build System**: GNU Make (`Makefile.macos` / `Makefile.linux`) — platform-specific
- **Version Source**: `version.mk` — read by `version.sh` to generate `version.py`
- **Dependency (Concurrent only)**: C++ shared library (`libswtr_ringbuffer.so` / `.dylib`) loaded via `ctypes`

## Building

### Using Make (Recommended)
The directory contains platform-specific Makefiles:
- **macOS**: `Makefile.macos` (uses BSD make syntax)
- **Linux**: `Makefile.linux` (uses GNU make syntax)

```bash
# macOS
make -f Makefile.macos all    # Verify build and run tests
make -f Makefile.macos clean  # Remove artifacts

# Linux
make -f Makefile.linux all    # Verify build and run tests
make -f Makefile.linux clean  # Remove artifacts
```

### Version Propagation
The `version.sh` script reads `version.mk` and generates `version.py`:
```bash
./version.sh          # Generates version.py with constants from version.mk
```

### Verification
```bash
python3 -m py_compile swtr_ringbuffer.py   # Syntax check (Concurrent)
python3 -m py_compile swtr_ringbuffer_pure.py  # Syntax check (Pure Python)
python3 -c "import swtr_ringbuffer"         # Import verification
```

## Library Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Version module | `version.py` | Generated from `version.mk` via `version.sh` |
| Concurrent module | `swtr_ringbuffer/swtr_ringbuffer_concurrent.py` | ctypes binding to C++ shared library |
| Pure Python module | `swtr_ringbuffer_pure.py` | Standalone pure Python implementation |
| Auto-select entry point | `swtr_ringbuffer/__init__.py` | Tries Concurrent first, falls back to Pure Python |
| Backward-compat shim | `swtr_ringbuffer.py` | Re-exports from package for legacy imports |
| ABC interface | `base.py` | RingBuffer abstract base class (38 methods) |
| Test module (Concurrent) | `test_ringbuffer.py` | T001–T007 test suite for Concurrent version |
| Test module (Pure Python) | `test_ringbuffer_pure.py` | T001–T007 test suite for Pure Python version |
| Benchmark script | `benchmark.py` | Performance comparison between Concurrent and Pure Python |

## Architecture

```
src/common/python/
├── base.py                          # RingBufferABC (38 abstract methods)
├── swtr_ringbuffer/                 # Package with auto-selection
│   ├── __init__.py                  # Auto-select: Concurrent → Pure Python
│   └── swtr_ringbuffer_concurrent.py  # Concurrent implementation (ctypes)
├── swtr_ringbuffer_pure.py          # Pure Python implementation
├── swtr_ringbuffer.py               # Backward-compat shim (re-exports from package)
├── version.py                       # Library version constants
└── test_ringbuffer*.py              # Test harnesses (Concurrent + Pure Python)
```

- **RingBufferABC** (`base.py`): Abstract base class defining 38 methods all implementations must satisfy
- **SwtrRingBufferConcurrent** (`swtr_ringbuffer/swtr_ringbuffer_concurrent.py`): Concurrent implementation using ctypes FFI to C++ shared library
- **SwtrRingBufferPure** (`swtr_ringbuffer_pure.py`): Pure Python implementation with full ABC parity
- **Auto-selection** (`swtr_ringbuffer/__init__.py`): Tries Concurrent first, falls back to Pure Python with warning

## Test Results

Both implementations verified via:
- `py_compile` syntax check — passes for all `.py` files
- Module import verification — passes for both versions
- Class instantiation test — passes for both versions
- Full 7-test matrix (T001–T007) — passes for both versions

## Performance Comparison

| Scenario | Faster Implementation | Reason |
|----------|----------------------|--------|
| Small inputs (< 1KB) | Concurrent (ctypes) | Lower per-operation overhead, ~1.4x faster avg |
| Large files (> 100KB) | Pure Python | No subprocess/FFI overhead, up to ~1.5x faster with transforms |
| Stress test (1-byte buffer) | Concurrent (ctypes) | ~2.6x faster, tight loop optimization in C++ |

**Crossover point:** Pure Python is faster at all tested file sizes. Run `python3 benchmark.py` to compare on your system. (293K+). The crossover where Concurrent becomes faster is below 1KB for identity transforms.

## Platform Notes

Python is **platform-insensitive** — the same source code runs on all supported operating systems. No per-OS overrides are needed; a single common spec generates identical source for all platforms. The only platform dependency is the C++ shared library (Concurrent version), which must be built separately for each target OS. Pure Python has no platform dependencies.
