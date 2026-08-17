# Python API Reference — SWTR Ringbuffer v1.0.0

## Module: `swtr_ringbuffer`

Pure Python implementation with ctypes FFI (cross-platform). Also available as pure Python (`swtr_ringbuffer_pure`) with no C++ dependency.

## Imports

```python
from swtr_ringbuffer import (
    SwtrRingBuffer, RingBuffer, BufferSlot,
    BufferStatus, ChecksumAlgorithm, LogLevel,
    MIN_NUMBER_SLOTS, DEFAULT_BUFFER_SIZE, MIN_BUFFER_SIZE,
    TransformFn, ErrorHandler
)
```

## Enumerations (int-based Enums)

### BufferStatus
Slot state machine values. Inherits from `int` for numeric comparison.

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

    def __str__(self): return self.name
```

### ChecksumAlgorithm
Per-slot checksum algorithm selection.

```python
class ChecksumAlgorithm(int, Enum):
    NONE = 0
    MD5 = 1
    SHA256 = 2
    SHA512 = 3

    def __str__(self): return self.name
```

### LogLevel
Logging verbosity levels.

```python
class LogLevel(int, Enum):
    TRACE = 0
    DEBUG = 1
    INFO = 2
    WARNING = 3
    ERROR = 4
    CRITICAL = 5

    def __str__(self): return self.name
```

## Type Aliases

```python
TransformFn = Callable[[bytearray, List[int]], None]
ErrorHandler = Callable[[int, BufferStatus], int]
```

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MIN_NUMBER_SLOTS` | 1 | Minimum number of buffer slots |
| `DEFAULT_BUFFER_SIZE` | 4096 | Default slot data buffer size in bytes |
| `MIN_BUFFER_SIZE` | 1 | Minimum buffer size per slot |

## BufferSlot Class

```python
class BufferSlot:
    def __init__(self, buffer_idx: int, max_data_buffer_size: int)

    # Atomic-equivalent getters (thread-safe via lock)
    def get_status(self) -> BufferStatus
    def set_status(self, status: BufferStatus) -> None
    def get_data_buffer_size(self) -> int
    def set_data_buffer_size(self, size: int) -> None
    def get_transformed_data_buffer_size(self) -> int
    def set_transformed_data_buffer_size(self, size: int) -> None
    def get_checksum_alg(self) -> ChecksumAlgorithm
    def set_checksum_alg(self, alg: ChecksumAlgorithm) -> None
    def get_checksum_val(self) -> int
    def set_checksum_val(self, val: int) -> None

    # Non-atomic getters
    def get_buffer_idx(self) -> int
    def get_max_data_buffer_size(self) -> int

    # Test methods
    def test_status(self, status: BufferStatus) -> bool
    def test_checksum_alg(self, alg: ChecksumAlgorithm) -> bool
    def test_checksum_val(self, val: int) -> bool

    # Utility
    def clear(self) -> None  # Clear slot data (used after write)
```

All getters/setters are protected by `threading.Lock` for thread safety.

## RingBuffer Abstract Interface

```python
class RingBuffer(ABC):
    @abstractmethod
    def start(self) -> None: ...

    @abstractmethod
    def stop(self) -> None: ...

    @abstractmethod
    def wait(self) -> None: ...

    @abstractmethod
    def set_read_fd(self, fd: int) -> None: ...

    @abstractmethod
    def set_write_fd(self, fd: int) -> None: ...

    # Logging (per-stage, independently configurable)
    @abstractmethod
    def set_logging_enabled(self, enabled: bool) -> None: ...
    @abstractmethod
    def get_logging_enabled(self) -> bool: ...
    @abstractmethod
    def set_output_stream(self, stream: io.IOBase) -> None: ...
    @abstractmethod
    def get_output_stream(self) -> io.IOBase: ...

    # Read stage logging
    @abstractmethod
    def set_read_logging_enabled(self, enabled: bool) -> None: ...
    @abstractmethod
    def get_read_logging_enabled(self) -> bool: ...
    @abstractmethod
    def set_read_verbosity(self, level: LogLevel) -> None: ...
    @abstractmethod
    def get_read_verbosity(self) -> LogLevel: ...

    # Transform stage logging
    @abstractmethod
    def set_transform_logging_enabled(self, enabled: bool) -> None: ...
    @abstractmethod
    def get_transform_logging_enabled(self) -> bool: ...
    @abstractmethod
    def set_transform_verbosity(self, level: LogLevel) -> None: ...
    @abstractmethod
    def get_transform_verbosity(self) -> LogLevel: ...

    # Write stage logging
    @abstractmethod
    def set_write_logging_enabled(self, enabled: bool) -> None: ...
    @abstractmethod
    def get_write_logging_enabled(self) -> bool: ...
    @abstractmethod
    def set_write_verbosity(self, level: LogLevel) -> None: ...
    @abstractmethod
    def get_write_verbosity(self) -> LogLevel: ...

    # Slot Accessors (~20 methods — intentional for consumer flexibility)
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

## SwtrRingBuffer Concrete Implementation

### Constructor

```python
def __init__(self, num_slots: int, initial_status: BufferStatus = BufferStatus.READYFORREAD,
             buffer_size: int = DEFAULT_BUFFER_SIZE,
             error_handler: Optional[ErrorHandler] = None,
             transform_fn: Optional[TransformFn] = None)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `num_slots` | `int` | — | Number of buffer slots (≥ 1) |
| `initial_status` | `BufferStatus` | `READYFORREAD` | Initial state for all slots |
| `buffer_size` | `int` | 4096 | Data buffer size per slot in bytes (≥ 1) |
| `error_handler` | `ErrorHandler` | `None` | Error handler callback; `None` for default |
| `transform_fn` | `TransformFn` | `None` | Transform function; `None` for identity (no-op) |

**Raises:** `ValueError` if `num_slots < MIN_NUMBER_SLOTS` or `buffer_size < MIN_BUFFER_SIZE`

### Thread Management

- **Daemon threads**: All three pipeline threads are daemon threads (`thread.daemon = True`).
- **Thread names**: `ringbuffer-read`, `ringbuffer-transform`, `ringbuffer-write`
- **Double-start guard**: Calling `start()` twice without stopping first logs a warning and returns silently.
- **Synchronization**: Uses `threading.RLock` for the main sync lock and a separate `threading.Lock` for logging to avoid nested locking.
- **Condition variable**: `threading.Condition(sync_lock)` used to wake waiting threads on stop.

### Logging Implementation

The `_log()` method determines effective verbosity from the calling thread's name:
- `ringbuffer-read` → `self.read_verbosity`
- `ringbuffer-transform` → `self.transform_verbosity`
- `ringbuffer-write` → `self.write_verbosity`
- All other threads (e.g., main) → no verbosity filtering (`TRACE`)

### Status Transitions

```
readyforread → processing_read → readyfortransform → processing_transform
    → readyforwrite → processing_write → readyforread

EOF propagation: LAST_BUFFER_TO_TRANSFORM → LAST_BUFFER_TO_WRITE
```

### Installation

```bash
# Pure Python (no C++ dependency)
pip install .  # from src/common/python/

# Or use directly:
python -c "from swtr_ringbuffer import SwtrRingBuffer; print('OK')"
```

## Key Design Decisions

- **Library-First API**: The ~20 slot-level accessor methods are intentional design choices providing maximum flexibility to library consumers for debugging, monitoring, and testing.
- **Thread Safety**: All slot state mutations are protected by `threading.Lock`. The pure Python implementation uses a lock-based approach (vs. atomic operations in C++).
- **Binary Symmetry**: Source code is byte-identical across all platforms (macOS, Linux distributions).
- **Two Implementations**: `swtr_ringbuffer.py` (ctypes FFI to C++ library) and `swtr_ringbuffer_pure.py` (pure Python, no dependency).
