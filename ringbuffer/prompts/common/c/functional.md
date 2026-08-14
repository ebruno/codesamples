# Functional Requirements — Ringbuffer (C)

**Cross-Platform Consistency Requirement:** This library is deployed across multiple platforms. To ensure maintainability, the source code MUST be generated from this common spec with platform-specific overrides for threading primitives, I/O multiplexing, and build flags. The common spec defines the behavioral contract, API surface, and test matrix that all implementations must satisfy.

**Cross-Platform Generation Mandate:** When generating source code for any platform, the agent MUST produce `.c` and `.h` files from this common spec. Platform-specific differences (threading, I/O, build flags) are handled by per-OS override files in `prompts/<os>/c/`. Generate each platform's source independently from this spec — do not copy files between platforms.

**Cross-Platform Verification:** After generating all files independently, compare output against any other platform's source in `src/` if available. If a reference platform exists, verify byte-identical output for the common spec portions and log: `[timestamp] Cross-platform comparison passed — <target> matches <reference>.` If no reference platform exists, log: `[timestamp] Cross-platform comparison skipped — no other platform source available.`

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/c/functional.md`) conflict with common specs (`prompts/common/c/functional.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

> **Quick Reference:** For platform-specific toolchain details (otool, lipo on macOS; readelf on Linux), binary format comparison tables (ELF vs Mach-O), and shared library linking conventions, see `prompts/common/cpp/session_hints.md`.

## Language Standards
- **Primary Version**: C23 (ISO/IEC 9899:2024)
- **Fallback Versions** (in priority order): C17 (ISO/IEC 9899:2018), C11 (ISO/IEC 9899:2011)
- **Minimum Supported**: C11 — all implementations MUST be compatible with this version
- **Encoding**: UTF-8

## Platform Classification
C is a **platform-sensitive** language. Unlike platform-insensitive languages (Python, Java, Go, Rust), C requires per-OS overrides because:
- No unified concurrency model — pthreads on both platforms but different threading library availability and semantics
- I/O multiplexing differs (`epoll` on Linux, `kqueue` on macOS)
- Build flags differ (shared lib naming: `.so` vs `.dylib`, linker options, universal binary support on macOS)
- No standard library abstraction for cross-platform threading or async I/O

The common spec defines the behavioral contract and API surface. Per-OS override files define platform-specific threading primitives, I/O handling, and build configuration.

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

## Status Enum Definitions
The following enums MUST be defined exactly as specified. Each enum value MUST have an explicit integer assignment.

### BufferStatus
```c
typedef enum {
    BUFFER_STATUS_READYFORREAD      = 0,
    BUFFER_STATUS_READYFORTRANSFORM = 1,
    BUFFER_STATUS_READYFORWRITE     = 2,
    BUFFER_STATUS_PROCESSING_READ   = 3,
    BUFFER_STATUS_PROCESSING_TRANSFORM = 4,
    BUFFER_STATUS_PROCESSING_WRITE  = 5,
    BUFFER_STATUS_EMPTY             = 6,
    BUFFER_STATUS_FULL              = 7,
    BUFFER_STATUS_LAST_BUFFER_TO_TRANSFORM = 8,
    BUFFER_STATUS_LAST_BUFFER_TO_WRITE     = 9,
    BUFFER_STATUS_PENDING_READ      = 10,
    BUFFER_STATUS_PENDING_TRANSFORM = 11,
    BUFFER_STATUS_PENDING_WRITE     = 12,
    BUFFER_STATUS_ERROR             = 13
} BufferStatus;
```

### ChecksumAlgorithm
```c
typedef enum {
    CHECKSUM_NONE   = 0,
    CHECKSUM_MD5    = 1,
    CHECKSUM_SHA256 = 2,
    CHECKSUM_SHA512 = 3
} ChecksumAlgorithm;
```

### LogLevel
```c
typedef enum {
    LOG_LEVEL_TRACE   = 0,
    LOG_LEVEL_DEBUG   = 1,
    LOG_LEVEL_INFO    = 2,
    LOG_LEVEL_WARNING = 3,
    LOG_LEVEL_ERROR   = 4,
    LOG_LEVEL_CRITICAL= 5
} LogLevel;
```

## BufferSlot Structure
Each slot in the ring buffer pool MUST be defined as:

```c
#include <stdatomic.h>
#include <stdint.h>
#include <stddef.h>

typedef struct {
    size_t buffer_idx;                                    // non-atomic: slot index (set once)
    _Atomic BufferStatus status;                          // atomic: current buffer state
    size_t max_data_buffer_size;                          // non-atomic: maximum capacity (set once)
    _Atomic size_t data_buffer_size;                      // atomic: current bytes in data buffer
    _Atomic size_t transformed_data_buffer_size;          // atomic: current bytes in transformed buffer
    _Atomic ChecksumAlgorithm checksum_alg;               // atomic: algorithm used for checksum
    _Atomic uint32_t checksum_val;                        // atomic: computed checksum value
    uint8_t *data;                                        // non-atomic: internal data buffer (raw bytes, heap allocated)
} BufferSlot;

// Constructor / destructor
BufferSlot *buffer_slot_create(size_t idx, size_t max_size);
void buffer_slot_destroy(BufferSlot *slot);
```

**Atomic vs Non-atomic distinction**:
- `buffer_idx`, `max_data_buffer_size`, and `data` are **non-atomic** — set once during construction, never modified.
- `status`, `data_buffer_size`, `transformed_data_buffer_size`, `checksum_alg`, and `checksum_val` are **atomic** — modified by pipeline threads, accessed via `_Atomic` operations (`atomic_load`, `atomic_store`).

## API Header (`ringbuffer.h`)
The primary header file MUST be self-sufficient and contain:

```c
#pragma once

#include <stdatomic.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include "status.h"

#ifdef __cplusplus
extern "C" {
#endif

// Type aliases for callbacks
typedef int (*ErrorHandler)(size_t slot_idx, BufferStatus status);
typedef void (*TransformFn)(uint8_t *data, size_t *size);

// Constants
#define MIN_NUMBER_SLOTS 1
#define DEFAULT_BUFFER_SIZE 4096
#define MIN_BUFFER_SIZE 1

// RingBuffer abstract interface (opaque handle)
typedef struct RingBuffer RingBuffer;

// Thread control
void ringbuffer_start(RingBuffer *rb);
void ringbuffer_stop(RingBuffer *rb);
void ringbuffer_wait(RingBuffer *rb);

// Configuration
void ringbuffer_set_read_fd(RingBuffer *rb, int fd);
void ringbuffer_set_write_fd(RingBuffer *rb, int fd);

// Logging
void ringbuffer_set_logging_enabled(RingBuffer *rb, bool enabled);
bool ringbuffer_get_logging_enabled(const RingBuffer *rb);
void ringbuffer_set_output_stream(RingBuffer *rb, void *stream);  // FILE* or similar
void *ringbuffer_get_output_stream(const RingBuffer *rb);
void ringbuffer_set_read_logging_enabled(RingBuffer *rb, bool enabled);
bool ringbuffer_get_read_logging_enabled(const RingBuffer *rb);
void ringbuffer_set_read_verbosity(RingBuffer *rb, LogLevel level);
LogLevel ringbuffer_get_read_verbosity(const RingBuffer *rb);
void ringbuffer_set_transform_logging_enabled(RingBuffer *rb, bool enabled);
bool ringbuffer_get_transform_logging_enabled(const RingBuffer *rb);
void ringbuffer_set_transform_verbosity(RingBuffer *rb, LogLevel level);
LogLevel ringbuffer_get_transform_verbosity(const RingBuffer *rb);
void ringbuffer_set_write_logging_enabled(RingBuffer *rb, bool enabled);
bool ringbuffer_get_write_logging_enabled(const RingBuffer *rb);
void ringbuffer_set_write_verbosity(RingBuffer *rb, LogLevel level);
LogLevel ringbuffer_get_write_verbosity(const RingBuffer *rb);

// Accessors
BufferStatus ringbuffer_get_status(const RingBuffer *rb, size_t slot_idx);
void ringbuffer_set_status(RingBuffer *rb, size_t slot_idx, BufferStatus status);
bool ringbuffer_test_status(const RingBuffer *rb, size_t slot_idx, BufferStatus status);
ChecksumAlgorithm ringbuffer_get_checksum_alg(const RingBuffer *rb, size_t slot_idx);
void ringbuffer_set_checksum_alg(RingBuffer *rb, size_t slot_idx, ChecksumAlgorithm alg);
bool ringbuffer_test_checksum_alg(const RingBuffer *rb, size_t slot_idx, ChecksumAlgorithm alg);
uint32_t ringbuffer_get_checksum_val(const RingBuffer *rb, size_t slot_idx);
void ringbuffer_set_checksum_val(RingBuffer *rb, size_t slot_idx, uint32_t val);
bool ringbuffer_test_checksum_val(const RingBuffer *rb, size_t slot_idx, uint32_t val);
size_t ringbuffer_get_max_size(const RingBuffer *rb, size_t slot_idx);
void ringbuffer_set_max_size(RingBuffer *rb, size_t slot_idx, size_t size);
size_t ringbuffer_get_data_size(const RingBuffer *rb, size_t slot_idx);
void ringbuffer_set_data_size(RingBuffer *rb, size_t slot_idx, size_t size);
size_t ringbuffer_get_transformed_size(const RingBuffer *rb, size_t slot_idx);
void ringbuffer_set_transformed_size(RingBuffer *rb, size_t slot_idx, size_t size);

// Factory
RingBuffer *ringbuffer_create(size_t num_slots, BufferStatus initial_status, size_t buffer_size,
                               ErrorHandler error_handler, TransformFn transform_fn);
void ringbuffer_destroy(RingBuffer *rb);

#ifdef __cplusplus
}
#endif
```

## Status Header (`status.h`)
The file `status.h` MUST contain exactly the three enum definitions (in this order):

```c
#pragma once
#include <stdint.h>

typedef enum {
    BUFFER_STATUS_READYFORREAD      = 0,
    BUFFER_STATUS_READYFORTRANSFORM = 1,
    BUFFER_STATUS_READYFORWRITE     = 2,
    BUFFER_STATUS_PROCESSING_READ   = 3,
    BUFFER_STATUS_PROCESSING_TRANSFORM = 4,
    BUFFER_STATUS_PROCESSING_WRITE  = 5,
    BUFFER_STATUS_EMPTY             = 6,
    BUFFER_STATUS_FULL              = 7,
    BUFFER_STATUS_LAST_BUFFER_TO_TRANSFORM = 8,
    BUFFER_STATUS_LAST_BUFFER_TO_WRITE     = 9,
    BUFFER_STATUS_PENDING_READ      = 10,
    BUFFER_STATUS_PENDING_TRANSFORM = 11,
    BUFFER_STATUS_PENDING_WRITE     = 12,
    BUFFER_STATUS_ERROR             = 13
} BufferStatus;

typedef enum {
    CHECKSUM_NONE   = 0,
    CHECKSUM_MD5    = 1,
    CHECKSUM_SHA256 = 2,
    CHECKSUM_SHA512 = 3
} ChecksumAlgorithm;

typedef enum {
    LOG_LEVEL_TRACE   = 0,
    LOG_LEVEL_DEBUG   = 1,
    LOG_LEVEL_INFO    = 2,
    LOG_LEVEL_WARNING = 3,
    LOG_LEVEL_ERROR   = 4,
    LOG_LEVEL_CRITICAL= 5
} LogLevel;
```

**Enum Value Completeness Rule**: Every enum value in every enum MUST have an explicit `= N` assignment. No implicit incrementing is allowed anywhere.

**Global Namespace Rule for Enums**: All enums in `status.h` are at **global scope**. They are NOT inside any namespace wrapper.

- `status.h` MUST be self-sufficient with only `<stdint.h>` as a standard include.
- `status.h` MUST use `#pragma once` for include guards.

## Performance & Binary Optimization
- **Dead Code Elimination**: The library must be compatible with dead code elimination (e.g., using `-ffunction-sections` and `-fdata-sections`) to ensure the "small binary" goal is verifiable during testing.
- **Memory Alignment**: Buffer slots and index counters should be aligned to cache line boundaries (e.g., using `alignas(64)` or `__attribute__((aligned(64))))` to prevent false sharing between threads.
- **Naming Convention**: All private member variables MUST follow the trailing underscore naming convention (e.g., `member_variable_`).
- `read_fd` and `write_fd` MUST be `_Atomic int`.
- **Slot Storage**: The ring buffer must store slots using a dynamically allocated array of `BufferSlot *` pointers.
- **Atomic Operations**: All `_Atomic` members MUST be accessed using `atomic_load()` and `atomic_store()` functions rather than direct assignment.

## SwtrRingBuffer Implementation
The concrete implementation MUST be named `SwtrRingBuffer` and implement the opaque `RingBuffer` interface.

### Member Variables
```c
struct RingBuffer {
    // Slot storage
    BufferSlot **slots;
    size_t num_slots;

    // Index tracking — one independent counter per pipeline stage (atomic for thread safety)
    _Atomic size_t read_index;
    _Atomic size_t transform_index;
    _Atomic size_t write_index;

    // File descriptors (atomic for cross-thread access)
    _Atomic int read_fd;
    _Atomic int write_fd;

    // Buffer size per slot
    size_t buffer_size;

    // Pipeline functions (set once at construction)
    ErrorHandler error_handler;
    TransformFn transform_fn;

    // Thread management (platform-specific: pthread_t on Linux/macOS)
    void *read_thread;      // pthread_t or platform equivalent
    void *transform_thread; // pthread_t or platform equivalent
    void *write_thread;     // pthread_t or platform equivalent

    // Synchronization primitives (platform-specific: pthread_mutex_t, pthread_cond_t)
    void *sync_lock;        // mutex or platform equivalent
    void *cond_var;         // condition variable or platform equivalent
    bool running;

    // Logging configuration (atomic for runtime reconfiguration)
    _Atomic bool logging_enabled;
    _Atomic bool read_logging_enabled;
    _Atomic bool transform_logging_enabled;
    _Atomic bool write_logging_enabled;
    LogLevel read_verbosity;
    LogLevel transform_verbosity;
    LogLevel write_verbosity;

    // Output stream (pointer to FILE* or platform equivalent)
    void *output_stream;

    // Log lock (separate from sync_lock to avoid nested locking)
    void *log_lock;         // mutex or platform equivalent
};
```

**Initialization rules**:
- `read_index`, `transform_index`, and `write_index` MUST all be initialized to `0`.
- `read_fd` and `write_fd` MUST be initialized to `-1`.
- All logging booleans MUST default to `false`.
- All log verbosity levels MUST default to `LOG_LEVEL_INFO` (value 2).
- `output_stream` MUST default to `stderr`.

### Constructor / Factory Function
```c
RingBuffer *ringbuffer_create(size_t num_slots, BufferStatus initial_status, size_t buffer_size,
                               ErrorHandler error_handler, TransformFn transform_fn);
```

- MUST return `NULL` if `num_slots < MIN_NUMBER_SLOTS` or `buffer_size < MIN_BUFFER_SIZE`.
- MUST NOT start threads automatically.

### Pipeline Logic

**Read Loop**: Read from `read_fd` using platform-specific I/O (e.g., `read()` on POSIX). Mark slot `BUFFER_STATUS_READYFORTRANSFORM` after fill. Set `data_buffer_size` to bytes read. On EOF (0 bytes returned), mark slot as `BUFFER_STATUS_LAST_BUFFER_TO_TRANSFORM`, advance index, signal condition variable, and break the loop. On error (-1), set status to `BUFFER_STATUS_ERROR`, call error handler — if non-zero, stop the pipeline.

**Transform Loop**: Pass `slot->data` directly to the transform function (in-place modification). The transform modifies `data` and updates `*size`. Store the result size in `transformed_data_buffer_size`. Mark slot as `BUFFER_STATUS_READYFORWRITE`, advance index, signal condition variable. If no transform function is set, copy data size to transformed size and mark ready for write. On `BUFFER_STATUS_LAST_BUFFER_TO_TRANSFORM`, mark slot as `BUFFER_STATUS_LAST_BUFFER_TO_WRITE`, advance index, signal condition variable, and break.

**Write Loop**: Write `slot->data[0..transformed_data_buffer_size]` to `write_fd` using platform-specific I/O (e.g., `write()` on POSIX). On success, clear slot data using `memset(slot->data, 0, max_size)`, reset sizes, mark slot as `BUFFER_STATUS_READYFORREAD`, advance index, signal condition variable. On `BUFFER_STATUS_LAST_BUFFER_TO_WRITE`, flush the output stream/file descriptor, mark slot as `BUFFER_STATUS_READYFORREAD`, advance index, signal condition variable, and break. On error, set status to `BUFFER_STATUS_ERROR`, call error handler — if non-zero, stop the pipeline.

### Thread Management
- `ringbuffer_start()`: Create and start all three threads if not already running. Use a guard to prevent double-start.
- `ringbuffer_stop()`: Set `running` flag, join all threads, signal the condition variable.
- `ringbuffer_wait()`: Join all three threads (blocking).

### Logging Architecture
Use a logging function that checks `logging_enabled` before formatting and outputting. Log messages MUST be thread-safe using the `log_lock`. Format: `[LEVEL] message`.

### Accessor Implementation Rules
- `get_*` methods MUST use `atomic_load()` on atomic members and direct read on non-atomic members.
- `set_*` methods MUST use `atomic_store()` on atomic members and direct assignment on non-atomic members.
- `test_*` methods MUST perform an equality check using `atomic_load()` on the atomic member and compare against the argument.
- Every accessor MUST validate `slot_idx < num_slots` before accessing `slots[slot_idx]`.
- Out-of-bounds: `get_*` returns safe defaults (`BUFFER_STATUS_ERROR`, `CHECKSUM_NONE`, or `0`), `test_*` returns `false`, non-const `set_*` silently returns.

### Slot Wrapping Strategy
Each pipeline stage uses its own independent index counter with modulo wrapping:
```c
// Read loop uses read_index
slot_idx = atomic_load(&rb->read_index) % rb->num_slots;

// Transform loop uses transform_index
slot_idx = atomic_load(&rb->transform_index) % rb->num_slots;

// Write loop uses write_index
slot_idx = atomic_load(&rb->write_index) % rb->num_slots;
```

### Naming Convention
- Header files: `snake_case.h` (e.g., `ringbuffer.h`, `status.h`)
- Source files: `snake_case.c` (e.g., `ringbuffer.c`, `swtr_ringbuffer_impl.c`)
- Function names: `snake_case` with prefix (e.g., `ringbuffer_create`, `buffer_slot_destroy`)
- Enum values: `UPPER_CASE` with prefix (e.g., `BUFFER_STATUS_READYFORREAD`)
- Member variables: trailing underscore convention (e.g., `member_variable_`)

### File Organization
All C source files MUST be placed in the following directory structure:

```
src/<os>/c/
├── status.h                     // Enum definitions (shared across all source)
├── ringbuffer.h                 // Public API header
├── ringbuffer.c                 // Core implementation (BufferSlot, factory)
├── swtr_ringbuffer_impl.c       // SwtrRingBuffer pipeline implementation (platform-specific)
├── Makefile                     // Build configuration
└── version.mk                   // Library version (NOT OS version)
```

**File responsibilities**:
- `status.h`: Enum definitions only. Self-sufficient, no dependencies.
- `ringbuffer.h`: Public API declarations. Includes `status.h`. Opaque handle pattern for `RingBuffer`.
- `ringbuffer.c`: BufferSlot creation/destruction, factory function. Platform-independent common code.
- `swtr_ringbuffer_impl.c`: Pipeline thread implementation (read/transform/write loops). **Platform-specific** — threading primitives, I/O calls differ per OS.

### Platform-Specific Implementation Notes
The `swtr_ringbuffer_impl.c` file MUST be generated from per-OS override files. Key platform differences:

| Aspect | Linux | macOS |
|--------|-------|-------|
| Threading | `pthread_create`, `pthread_join` | `pthread_create`, `pthread_join` (same API, different implementation) |
| Mutex/CondVar | `pthread_mutex_t`, `pthread_cond_t` | `pthread_mutex_t`, `pthread_cond_t` (same API) |
| I/O | POSIX `read()`/`write()` | POSIX `read()`/`write()` (same API) |
| Shared lib extension | `.so` | `.dylib` |
| Universal binary | N/A | `lipo` for arm64 + x86_64 fat binary |
| Linker flags | `-Wl,--gc-sections` | `-dead_strip` |

> **Note**: While pthread API is the same on Linux and macOS, per-OS override files are still required because:
> 1. Build flags differ (shared lib naming, linker options)
> 2. macOS requires universal binary support (`-arch arm64 -arch x86_64`)
> 3. Dead code elimination flags differ (`--gc-sections` vs `-dead_strip`)
> 4. Future platform additions (Windows, FreeBSD) would require different threading/I/O

### Test Binary
Each implementation MUST include a test binary written in C. The test binary exercises the 7-test matrix (T001-T007) and serves as an implementation example. The test binary MUST:
- Be compiled alongside the library from `src/<os>/c/tests/`
- Read input from stdin, write output to stdout
- Support configuration via command-line arguments (number of slots, buffer size, transform type)
- Exit with code 0 on success, 1 on fatal error

---

**IMPORTANT: This spec defines the functional requirements only. Build configuration (Makefile, compiler flags) is defined in `prompts/common/c/build.md`.**
