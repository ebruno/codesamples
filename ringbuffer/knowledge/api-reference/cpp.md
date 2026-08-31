# C++ API Reference — SWTR Ringbuffer v1.0.0

## Namespace: `swtr`

All types and classes are in the `swtr` namespace.

## Headers

| Header | Contents |
|--------|----------|
| `ringbuffer.hpp` | Abstract `RingBuffer` interface, `BufferSlot` struct, type aliases |
| `status.hpp` | Enum definitions: `BufferStatus`, `ChecksumAlgorithm`, `LogLevel` |
| `swtr_ringbuffer_impl.hpp` | Concrete `SwtrRingBuffer` implementation class |

## Enumerations

### BufferStatus
Slot state machine values. Used for status checks, transitions, and error reporting.

```cpp
enum class BufferStatus : int {
    READYFORREAD = 0,
    READYFORTRANSFORM = 1,
    READYFORWRITE = 2,
    PROCESSING_READ = 3,
    PROCESSING_TRANSFORM = 4,
    PROCESSING_WRITE = 5,
    EMPTY = 6,
    FULL = 7,
    LAST_BUFFER_TO_TRANSFORM = 8,
    LAST_BUFFER_TO_WRITE = 9,
    PENDING_READ = 10,
    PENDING_TRANSFORM = 11,
    PENDING_WRITE = 12,
    STATUS_ERROR = 13
};
```

### ChecksumAlgorithm
Per-slot checksum algorithm selection.

```cpp
enum class ChecksumAlgorithm : int {
    NONE = 0,
    MD5 = 1,
    SHA256 = 2,
    SHA512 = 3
};
```

### LogLevel
Logging verbosity levels.

```cpp
enum class LogLevel : int {
    TRACE = 0,
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4,
    CRITICAL = 5
};
```

## Type Aliases

```cpp
using ErrorHandler = int (*)(size_t slot_idx, BufferStatus status);
using TransformFn  = std::function<void(std::vector<uint8_t>&, size_t&)>;
```

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MIN_NUMBER_SLOTS` | 1 | Minimum number of buffer slots |
| `DEFAULT_BUFFER_SIZE` | 4096 | Default slot data buffer size in bytes |

## BufferSlot Struct

```cpp
struct BufferSlot {
    alignas(64) size_t buffer_idx;                              // Slot index (non-atomic)
    alignas(64) std::atomic<BufferStatus> status;               // Current slot state
    alignas(64) size_t max_data_buffer_size;                    // Max capacity (non-atomic)
    alignas(64) std::atomic<size_t> data_buffer_size;           // Current bytes in buffer
    alignas(64) std::atomic<size_t> transformed_data_buffer_size; // Transformed bytes
    alignas(64) std::atomic<ChecksumAlgorithm> checksum_alg;    // Checksum algorithm
    alignas(64) std::atomic<uint32_t> checksum_val;             // Computed checksum
    std::vector<uint8_t> data;                                  // Data buffer

    BufferSlot(size_t idx, size_t max_size);
};
```

All counters are `alignas(64)` to prevent false sharing between threads.

## RingBuffer Abstract Interface

```cpp
class RingBuffer {
public:
    virtual ~RingBuffer() = default;

    // === Thread Control ===
    virtual void start() = 0;       // Start pipeline threads (non-blocking)
    virtual void stop() = 0;        // Stop pipeline, initiate cooperative cancellation
    virtual void wait() = 0;        // Block until all threads complete and join

    // === Configuration ===
    virtual void set_read_fd(int fd) = 0;     // Set input file descriptor
    virtual void set_write_fd(int fd) = 0;    // Set output file descriptor

    // === Logging (per-stage, independently configurable) ===
    virtual void set_logging_enabled(bool enabled) = 0;
    virtual bool get_logging_enabled() const = 0;
    virtual void set_output_stream(std::ostream& stream) = 0;
    virtual std::ostream* get_output_stream() const = 0;

    // Read stage logging
    virtual void set_read_logging_enabled(bool enabled) = 0;
    virtual bool get_read_logging_enabled() const = 0;
    virtual void set_read_verbosity(LogLevel level) = 0;
    virtual LogLevel get_read_verbosity() const = 0;

    // Transform stage logging
    virtual void set_transform_logging_enabled(bool enabled) = 0;
    virtual bool get_transform_logging_enabled() const = 0;
    virtual void set_transform_verbosity(LogLevel level) = 0;
    virtual LogLevel get_transform_verbosity() const = 0;

    // Write stage logging
    virtual void set_write_logging_enabled(bool enabled) = 0;
    virtual bool get_write_logging_enabled() const = 0;
    virtual void set_write_verbosity(LogLevel level) = 0;
    virtual LogLevel get_write_verbosity() const = 0;

    // === Slot Accessors (~20 methods — intentional for consumer flexibility) ===
    virtual BufferStatus get_status(size_t slot_idx) const = 0;
    virtual void set_status(size_t slot_idx, BufferStatus status) = 0;
    virtual bool test_status(size_t slot_idx, BufferStatus status) const = 0;

    virtual ChecksumAlgorithm get_checksum_alg(size_t slot_idx) const = 0;
    virtual void set_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) = 0;
    virtual bool test_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) const = 0;

    virtual uint32_t get_checksum_val(size_t slot_idx) const = 0;
    virtual void set_checksum_val(size_t slot_idx, uint32_t val) = 0;
    virtual bool test_checksum_val(size_t slot_idx, uint32_t val) const = 0;

    virtual size_t get_max_size(size_t slot_idx) const = 0;
    virtual void set_max_size(size_t slot_idx, size_t size) = 0;

    virtual size_t get_data_size(size_t slot_idx) const = 0;
    virtual void set_data_size(size_t slot_idx, size_t size) = 0;

    virtual size_t get_transformed_size(size_t slot_idx) const = 0;
    virtual void set_transformed_size(size_t slot_idx, size_t size) = 0;

protected:
    virtual void do_log(LogLevel level, const std::string& message) = 0;
};
```

## SwtrRingBuffer Concrete Implementation

```cpp
class SwtrRingBuffer : public RingBuffer {
public:
    // Constructor — creates slots, initializes state machine
    SwtrRingBuffer(size_t num_slots, BufferStatus initial_status, size_t buffer_size,
                   ErrorHandler error_handler, TransformFn transform_fn);

    // Destructor — stops pipeline if running
    ~SwtrRingBuffer() override;

    // All RingBuffer virtual methods implemented here
};
```

### Constructor Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `num_slots` | `size_t` | Number of buffer slots (≥ 1) |
| `initial_status` | `BufferStatus` | Initial state for all slots (typically `readyforread`) |
| `buffer_size` | `size_t` | Data buffer size per slot in bytes (≥ 1) |
| `error_handler` | `ErrorHandler` | C function pointer for error callbacks; `nullptr` for default |
| `transform_fn` | `TransformFn` | User-supplied transform function; `nullptr` for identity (no-op) |

### Transform Function Signature

```cpp
void transform(std::vector<uint8_t>& data, size_t& size);
```

The function receives a mutable reference to the slot's data buffer and its current byte count. Modifications are in-place. Common patterns:
- `0` (identity/bypass): no-op, data passes through unchanged
- `1` (uppercase): converts lowercase ASCII to uppercase
- `2` (XOR 0xFF): XORs each byte with 0xFF

## Build Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Static library | `src/<os>/cpp/lib/libswtr_ringbuffer-<MAJOR>.<MINOR>.<SUBVERSION>-<BUILD_ID>.a` | Static archive |
| Shared library (macOS) | `src/<os>/cpp/lib/libswtr_ringbuffer-<MAJOR>.<MINOR>.<SUBVERSION>-<BUILD_ID>.dylib` | Dynamic library (Mach-O) |
| Shared library (Linux) | `src/<os>/cpp/lib/libswtr_ringbuffer-<MAJOR>.<MINOR>.<SUBVERSION>-<BUILD_ID>.so` | Dynamic library (ELF) |
| Unversioned symlink | `src/<os>/cpp/lib/libswtr_ringbuffer.a` / `.so` / `.dylib` | Convenience symlink |

### Compilation Example

```bash
clang++ -std=c++20 main.cpp \
    -I../src/macos/cpp \
    -L../src/macos/cpp/lib \
    -lswtr_ringbuffer \
    -o main
```

## Key Design Decisions

- **Library-First API**: The ~20 slot-level accessor methods are intentional design choices providing maximum flexibility to library consumers for debugging, monitoring, and testing.
- **Cache Alignment**: All slot fields are `alignas(64)` to prevent false sharing between the three pipeline threads.
- **Independent Atomic Indexes**: Each stage (read, transform, write) has its own `std::atomic<size_t>` index counter — no contention between threads.
- **Cooperative Cancellation**: `stop()` sets a flag and interrupts all threads; `wait()` joins them cleanly via `std::jthread`.
- **NVI Logging**: Non-Virtual Public Interface — logging methods are public, internal `do_log()` is protected. Per-stage verbosity is independently configurable at runtime.
