# Functional Requirements — Ringbuffer (Python)

**Cross-Platform Consistency Requirement:** This library is deployed across multiple platforms. To ensure maintainability, the source code MUST be identical across all platforms. Do not adapt the coding style or architecture to the specific platform; follow these specifications strictly.

**Cross-Platform Generation Mandate:** When generating source code for any platform, the agent MUST produce byte-identical `.py` files across all platforms. The only platform-specific artifacts are:
- How the shared library is loaded (path resolution differs between macOS and Linux)

All source code files (`*.py`) MUST be generated from the same canonical template. Generate each platform's source independently from this spec — do not copy files between platforms.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/python/functional.md`) conflict with common specs (`prompts/common/python/functional.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

## Language Standards
- **Primary Version**: Python 3.14
- **Fallback Versions** (in priority order): Python 3.13, Python 3.12, Python 3.11, Python 3.10
- **Minimum Supported**: Python 3.10 — all implementations MUST be compatible with this version
- **Encoding**: UTF-8

## Platform Classification
Python is a **platform-insensitive** language. The standard library provides unified abstractions across platforms:
- `threading` module abstracts platform threading (pthread on both macOS and Linux)
- `ctypes` provides cross-platform FFI to load shared libraries
- File descriptor I/O works the same way on both platforms via `os.read()`/`os.write()`

The common spec defines the complete implementation. Per-OS directories contain zero-length or minimal override files only (shared library path resolution).

## Shared Behavioral Contract (All Languages)
Every implementation must satisfy these requirements regardless of language:
- **Three-stage pipeline**: Independent read, transform, and write stages operating on a shared pool of buffer slots
- **Status-driven coordination**: Slots transition through states (`readyforread` → `readyfortransform` → `readyforwrite` → `readyforread`)
- **Cooperative cancellation**: Pipeline stages must support graceful shutdown via a stop signal / equivalent mechanism
- **Error handling**: An error handler callback that returns non-zero to trigger pipeline shutdown
- **EOF detection**: When read returns EOF (0 bytes), the pipeline must propagate `LAST_BUFFER_TO_TRANSFORM` → `LAST_BUFFER_TO_WRITE` through all stages, then terminate cleanly
- **Transform in-place**: The transform function receives the slot's data buffer and modifies it directly; `transformed_data_buffer_size` must be updated with the result size
- **Test compliance**: All implementations must pass the 7-test matrix (see below)

## Test Matrix (Ground Truth)
| Test | Config | Expected Exit | Output Match? |
|------|--------|---------------|---------------|
| T001 | Default (identity transform) | 0 | Yes — output == input |
| T002 | 1 slot, 1-byte buffer (stress) | 0 | Yes — output == input |
| T003 | Uppercase transform | 0 | Yes — output matches expected |
| T004 | Small input, fast EOF | 0 | Yes — output == input |
| T005 | Fatal error mode | **1** | Not checked (partial output) |
| T006 | Non-fatal error mode | 0 | Yes — output == input |
| T007 | XOR transform | 0 | Yes — output matches expected binary data |

## Implementation Approach: Pure Python with ctypes
This is a **pure Python** implementation. The ringbuffer pipeline logic (threading, status coordination, EOF handling) is implemented entirely in Python. The implementation uses `ctypes` to load the C library's shared object (`libswtr_ringbuffer.so` or `.dylib`) for any native operations, but the pipeline itself is pure Python.

**Key constraint**: No C-extension wrapping. The entire ringbuffer implementation (BufferSlot, SwtrRingBuffer, pipeline threads) is written in Python. `ctypes` is used only to load and call into the C library if native operations are needed.

## Status Enum Definitions
The following enums MUST be defined exactly as specified. Each enum value MUST have an explicit ordinal assignment matching the C specification.

### BufferStatus
```python
class BufferStatus(int, Enum):
    READYFORREAD = 0
    READYFORTRANSFORM = 1
    READYFORWRITE = 2
    PROCESSING_READ = 3
    PROCESSING_TRANSFORM = 4
    PROCESSING_WRITE = 5
    EMPTY = 6
    FULL = 7
    LAST_BUFFER_TO_TRANSFORM = 8
    LAST_BUFFER_TO_WRITE = 9
    PENDING_READ = 10
    PENDING_TRANSFORM = 11
    PENDING_WRITE = 12
    STATUS_ERROR = 13

    def __str__(self):
        return self.name
```

### ChecksumAlgorithm
```python
class ChecksumAlgorithm(int, Enum):
    NONE = 0
    MD5 = 1
    SHA256 = 2
    SHA512 = 3

    def __str__(self):
        return self.name
```

### LogLevel
```python
class LogLevel(int, Enum):
    TRACE = 0
    DEBUG = 1
    INFO = 2
    WARNING = 3
    ERROR = 4
    CRITICAL = 5

    def __str__(self):
        return self.name
```

## BufferSlot Structure
Each slot in the ring buffer pool MUST be defined as:

```python
from threading import Lock, Condition
from typing import Optional

class BufferSlot:
    """Ring buffer slot with atomic-equivalent thread-safe access."""

    def __init__(self, buffer_idx: int, max_data_buffer_size: int):
        # Non-atomic fields (set once during construction)
        self.buffer_idx: int = buffer_idx
        self.max_data_buffer_size: int = max_data_buffer_size
        self.data: bytearray = bytearray(max_data_buffer_size)

        # Atomic-equivalent fields (protected by lock)
        self._lock = Lock()
        self.status: BufferStatus = BufferStatus.READYFORREAD
        self.data_buffer_size: int = 0
        self.transformed_data_buffer_size: int = 0
        self.checksum_alg: ChecksumAlgorithm = ChecksumAlgorithm.NONE
        self.checksum_val: int = 0

    # Atomic-equivalent getters (thread-safe via lock)
    def get_status(self) -> BufferStatus:
        with self._lock:
            return self.status

    def set_status(self, status: BufferStatus) -> None:
        with self._lock:
            self.status = status

    def get_data_buffer_size(self) -> int:
        with self._lock:
            return self.data_buffer_size

    def set_data_buffer_size(self, size: int) -> None:
        with self._lock:
            self.data_buffer_size = size

    def get_transformed_data_buffer_size(self) -> int:
        with self._lock:
            return self.transformed_data_buffer_size

    def set_transformed_data_buffer_size(self, size: int) -> None:
        with self._lock:
            self.transformed_data_buffer_size = size

    def get_checksum_alg(self) -> ChecksumAlgorithm:
        with self._lock:
            return self.checksum_alg

    def set_checksum_alg(self, alg: ChecksumAlgorithm) -> None:
        with self._lock:
            self.checksum_alg = alg

    def get_checksum_val(self) -> int:
        with self._lock:
            return self.checksum_val

    def set_checksum_val(self, val: int) -> None:
        with self._lock:
            self.checksum_val = val

    # Non-atomic getters (no lock needed)
    def get_buffer_idx(self) -> int:
        return self.buffer_idx

    def get_max_data_buffer_size(self) -> int:
        return self.max_data_buffer_size

    def test_status(self, status: BufferStatus) -> bool:
        with self._lock:
            return self.status == status

    def test_checksum_alg(self, alg: ChecksumAlgorithm) -> bool:
        with self._lock:
            return self.checksum_alg == alg

    def test_checksum_val(self, val: int) -> bool:
        with self._lock:
            return self.checksum_val == val

    def clear(self) -> None:
        """Clear slot data (used after write)."""
        with self._lock:
            self.data = bytearray(self.max_data_buffer_size)
            self.data_buffer_size = 0
            self.transformed_data_buffer_size = 0
```

**Atomic-equivalent distinction**: Python does not have `std::atomic`. Use a `threading.Lock` to protect fields that are read/written by multiple pipeline threads. The `buffer_idx`, `max_data_buffer_size`, and `data` fields are set once during construction and never modified afterward, so they do not need lock protection.

## RingBuffer Interface
The public API MUST be defined as an abstract base class:

```python
from abc import ABC, abstractmethod
import io

class RingBuffer(ABC):
    """Abstract ring buffer interface."""

    @abstractmethod
    def start(self) -> None:
        """Start the three-stage pipeline threads."""
        ...

    @abstractmethod
    def stop(self) -> None:
        """Stop the pipeline and wait for threads to terminate."""
        ...

    @abstractmethod
    def wait(self) -> None:
        """Wait for all pipeline threads to complete (non-blocking)."""
        ...

    @abstractmethod
    def set_read_fd(self, fd: int) -> None:
        """Set the file descriptor for read input."""
        ...

    @abstractmethod
    def set_write_fd(self, fd: int) -> None:
        """Set the file descriptor for write output."""
        ...

    # Logging configuration
    @abstractmethod
    def set_logging_enabled(self, enabled: bool) -> None: ...
    @abstractmethod
    def get_logging_enabled(self) -> bool: ...
    @abstractmethod
    def set_output_stream(self, stream: io.IOBase) -> None: ...
    @abstractmethod
    def get_output_stream(self) -> io.IOBase: ...
    @abstractmethod
    def set_read_logging_enabled(self, enabled: bool) -> None: ...
    @abstractmethod
    def get_read_logging_enabled(self) -> bool: ...
    @abstractmethod
    def set_read_verbosity(self, level: LogLevel) -> None: ...
    @abstractmethod
    def get_read_verbosity(self) -> LogLevel: ...
    @abstractmethod
    def set_transform_logging_enabled(self, enabled: bool) -> None: ...
    @abstractmethod
    def get_transform_logging_enabled(self) -> bool: ...
    @abstractmethod
    def set_transform_verbosity(self, level: LogLevel) -> None: ...
    @abstractmethod
    def get_transform_verbosity(self) -> LogLevel: ...
    @abstractmethod
    def set_write_logging_enabled(self, enabled: bool) -> None: ...
    @abstractmethod
    def get_write_logging_enabled(self) -> bool: ...
    @abstractmethod
    def set_write_verbosity(self, level: LogLevel) -> None: ...
    @abstractmethod
    def get_write_verbosity(self) -> LogLevel: ...

    # Accessors
    @abstractmethod
    def get_status(self, slot_idx: int) -> BufferStatus: ...
    @abstractmethod
    def set_status(self, slot_idx: int, status: BufferStatus) -> None: ...
    @abstractmethod
    def test_status(self, slot_idx: int, status: BufferStatus) -> bool: ...
    @abstractmethod
    def get_checksum_alg(self, slot_idx: int) -> ChecksumAlgorithm: ...
    @abstractmethod
    def set_checksum_alg(self, slot_idx: int, alg: ChecksumAlgorithm) -> None: ...
    @abstractmethod
    def test_checksum_alg(self, slot_idx: int, alg: ChecksumAlgorithm) -> bool: ...
    @abstractmethod
    def get_checksum_val(self, slot_idx: int) -> int: ...
    @abstractmethod
    def set_checksum_val(self, slot_idx: int, val: int) -> None: ...
    @abstractmethod
    def test_checksum_val(self, slot_idx: int, val: int) -> bool: ...
    @abstractmethod
    def get_max_size(self, slot_idx: int) -> int: ...
    @abstractmethod
    def set_max_size(self, slot_idx: int, size: int) -> None: ...
    @abstractmethod
    def get_data_size(self, slot_idx: int) -> int: ...
    @abstractmethod
    def set_data_size(self, slot_idx: int, size: int) -> None: ...
    @abstractmethod
    def get_transformed_size(self, slot_idx: int) -> int: ...
    @abstractmethod
    def set_transformed_size(self, slot_idx: int, size: int) -> None: ...
```

## Transform Function Type
```python
from typing import Callable, List

TransformFn = Callable[[bytearray, List[int]], None]
```

The transform function receives the slot's data buffer and a single-element list as a size holder. It modifies `data` in-place and updates `size_holder[0]` with the new size. The list is used because Python does not support pass-by-reference for primitives.

## Error Handler Type
```python
ErrorHandler = Callable[[int, BufferStatus], int]
```

Returning non-zero triggers cooperative cancellation (pipeline shutdown).

## Constants
```python
MIN_NUMBER_SLOTS = 1
DEFAULT_BUFFER_SIZE = 4096
MIN_BUFFER_SIZE = 1
```

## SwtrRingBuffer Implementation Class
The concrete implementation class MUST be named `SwtrRingBuffer` and implement the `RingBuffer` abstract base class.

### Member Variables
```python
import threading
from typing import Optional

class SwtrRingBuffer(RingBuffer):
    def __init__(self, num_slots: int, initial_status: BufferStatus, buffer_size: int,
                 error_handler: Optional[ErrorHandler] = None,
                 transform_fn: Optional[TransformFn] = None):
        # Slot storage
        self.slots: List[BufferSlot] = [
            BufferSlot(i, buffer_size) for i in range(num_slots)
        ]
        self.num_slots: int = num_slots

        # Index tracking — one independent counter per pipeline stage
        self.read_index: int = 0
        self.transform_index: int = 0
        self.write_index: int = 0

        # File descriptors
        self.read_fd: int = -1
        self.write_fd: int = -1

        # Buffer size per slot
        self.buffer_size: int = buffer_size

        # Pipeline functions (set once at construction)
        self.error_handler: Optional[ErrorHandler] = error_handler
        self.transform_fn: Optional[TransformFn] = transform_fn

        # Thread management
        self.read_thread: Optional[threading.Thread] = None
        self.transform_thread: Optional[threading.Thread] = None
        self.write_thread: Optional[threading.Thread] = None

        # Synchronization primitives
        self.sync_lock: threading.Lock = threading.Lock()
        self.cond_var: threading.Condition = threading.Condition(self.sync_lock)
        self.running: bool = False

        # Logging configuration
        self.logging_enabled: bool = False
        self.read_logging_enabled: bool = False
        self.transform_logging_enabled: bool = False
        self.write_logging_enabled: bool = False
        self.read_verbosity: LogLevel = LogLevel.INFO
        self.transform_verbosity: LogLevel = LogLevel.INFO
        self.write_verbosity: LogLevel = LogLevel.INFO

        # Output stream
        self.output_stream: io.IOBase = sys.stderr

        # Log lock (separate from sync_lock to avoid nested locking)
        self.log_lock: threading.Lock = threading.Lock()

        # Guard against double-start
        self._started: bool = False
```

**Initialization rules**:
- `read_index`, `transform_index`, and `write_index` MUST all be initialized to `0`.
- `read_fd` and `write_fd` MUST be initialized to `-1`.
- All logging booleans MUST default to `False`.
- All log verbosity levels MUST default to `LogLevel.INFO` (value 2).
- `output_stream` MUST default to `sys.stderr`.

### Constructor
```python
def __init__(self, num_slots: int, initial_status: BufferStatus = BufferStatus.READYFORREAD,
             buffer_size: int = DEFAULT_BUFFER_SIZE,
             error_handler: Optional[ErrorHandler] = None,
             transform_fn: Optional[TransformFn] = None):
```

- MUST raise `ValueError` if `num_slots < MIN_NUMBER_SLOTS` or `buffer_size < MIN_BUFFER_SIZE`.
- MUST NOT start threads automatically.

### Pipeline Logic

**Read Loop**: Read from `read_fd` using Python's `os.read(fd, size)`. Mark slot `READYFORTRANSFORM` after fill. Set `data_buffer_size` to bytes read. On EOF (0 bytes returned), mark slot as `LAST_BUFFER_TO_TRANSFORM`, advance index, notify all waiting threads (via condition variable), and break the loop. On error (-1 or exception), set status to `STATUS_ERROR`, call error handler — if non-zero, stop the pipeline.

**Transform Loop**: Pass `slot.data` directly to the transform function (in-place modification). The transform modifies `data` and updates `size_holder[0]`. Store the result size in `transformed_data_buffer_size`. Mark slot as `READYFORWRITE`, advance index, notify all. If no transform function is set, copy data size to transformed size and mark ready for write. On `LAST_BUFFER_TO_TRANSFORM`, mark slot as `LAST_BUFFER_TO_WRITE`, advance index, notify all, and break.

**Write Loop**: Write `slot.data[0:transformed_data_buffer_size]` to `write_fd` using Python's `os.write(fd, data)`. On success, clear slot data using `bytearray(self.buffer_size)`, reset sizes, mark slot as `READYFORREAD`, advance index, notify all. On `LAST_BUFFER_TO_WRITE`, flush the output stream/file descriptor, mark slot as `READYFORREAD`, advance index, notify all, and break. On error, set status to `STATUS_ERROR`, call error handler — if non-zero, stop the pipeline.

### Thread Management
- `start()`: Create and start all three threads if not already running. Use a guard (`_started` flag) to prevent double-start.
- `stop()`: Set `running` flag to `False`, set all thread references, notify the condition variable.
- `wait()`: Join all three threads (blocking).

### Logging Architecture
Use a logging method that checks `logging_enabled` before formatting and outputting. Log messages MUST be thread-safe using the `log_lock`. Format: `[LEVEL] message`.

### Accessor Implementation Rules
- `get_*` methods MUST acquire the slot's lock before reading.
- `set_*` methods MUST acquire the slot's lock before writing.
- `test_*` methods MUST acquire the slot's lock and perform an equality check.
- Every accessor MUST validate `slot_idx < num_slots` before accessing `slots[slot_idx]`.
- Out-of-bounds: `get_*` returns safe defaults (`STATUS_ERROR`, `NONE`, or `0`), `test_*` returns `False`, non-const `set_*` silently returns.

### Slot Wrapping Strategy
Each pipeline stage uses its own independent index counter with modulo wrapping:
```python
# Read loop uses read_index
slot_idx = self.read_index % self.num_slots

# Transform loop uses transform_index
slot_idx = self.transform_index % self.num_slots

# Write loop uses write_index
slot_idx = self.write_index % self.num_slots
```

### Naming Convention
- Class names: `PascalCase` (e.g., `SwtrRingBuffer`, `BufferSlot`)
- Method names: `snake_case` (e.g., `set_read_fd`, `get_transformed_size`)
- Field names: `snake_case` (e.g., `read_index`, `transform_fn`)
- Constants: `UPPER_SNAKE_CASE` (e.g., `MIN_NUMBER_SLOTS`)
- Enum values: `UPPER_SNAKE_CASE` (e.g., `READYFORREAD`)

### File Organization
All Python source files MUST be placed under the following directory structure:

```
src/<os>/python/
├── swtr_ringbuffer.py       # Complete implementation (BufferSlot, SwtrRingBuffer)
├── __init__.py              # Package init (exports public API)
└── version.py               # Library version constants
```

**Single-file Python convention**: Unlike C++ and Java, the core ringbuffer implementation is placed in a single `swtr_ringbuffer.py` file for simplicity. The file contains:
- Enum definitions (`BufferStatus`, `ChecksumAlgorithm`, `LogLevel`)
- `BufferSlot` class
- `RingBuffer` abstract base class
- Type aliases (`TransformFn`, `ErrorHandler`)
- Constants
- `SwtrRingBuffer` concrete implementation

### Shared Library Loading (ctypes)
The Python implementation may use `ctypes` to load the C library's shared object for native operations. The shared library path is platform-specific:

```python
import ctypes
import os
import sys

def load_ringbuffer_library():
    """Load the ringbuffer shared library using ctypes."""
    lib_dir = os.path.join(os.path.dirname(__file__), '..', 'lib')

    if sys.platform == 'darwin':
        lib_path = os.path.join(lib_dir, 'libswtr_ringbuffer.dylib')
    else:
        lib_path = os.path.join(lib_dir, 'libswtr_ringbuffer.so')

    return ctypes.CDLL(lib_path)
```

### Test Binary
Each implementation MUST include a test binary written in Python. The test binary exercises the 7-test matrix (T001-T007) and serves as an implementation example. The test binary MUST:
- Be a standalone Python script at `src/<os>/python/test_ringbuffer.py`
- Read input from stdin, write output to stdout
- Support configuration via command-line arguments (number of slots, buffer size, transform type)
- Exit with code 0 on success, 1 on fatal error

---

**IMPORTANT: This spec defines the functional requirements only. Build configuration is defined in `prompts/common/python/build.md`.**
