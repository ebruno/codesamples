# Functional Requirements — Ringbuffer (Rust)

**Cross-Platform Consistency Requirement:** This library is deployed across multiple platforms. To ensure maintainability, the source code MUST be identical across all platforms. Do not adapt the coding style or architecture to the specific platform; follow these specifications strictly.

**Cross-Platform Generation Mandate:** When generating source code for any platform, the agent MUST produce byte-identical `.rs` files across all platforms. The only platform-specific artifacts are:
- `Cargo.toml` (if platform-specific build constraints or CGO settings are needed)

All source code files (`*.rs`) MUST be generated from the same canonical template. Generate each platform's source independently from this spec — do not copy files between platforms.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/rust/functional.md`) conflict with common specs (`prompts/common/rust/functional.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

## Language Standards
- **Primary Version**: Rust 1.84.0
- **Fallback Versions** (in priority order): Rust 1.56.0
- **Minimum Supported**: Rust 1.56.0 — all implementations MUST be compatible with this version
- **Encoding**: UTF-8

## Platform Classification
Rust is a **platform-insensitive** language. The standard library provides unified abstractions across platforms:
- `std::sync::atomic` provides cross-platform atomic operations (works on both macOS and Linux)
- `std::thread` abstracts platform threading (pthread on both macOS and Linux)
- `libc` crate provides cross-platform FFI for file descriptor I/O (`read()`/`write()`)
- Cargo (`Cargo.toml`) is identical across platforms — no per-platform build config changes needed

The common spec defines the complete implementation. Per-OS directories contain zero-length or minimal override files only.

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
The following enums MUST be defined exactly as specified. Each enum value MUST have an explicit integer assignment matching the C specification.

### BufferStatus
```rust
#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BufferStatus {
    ReadyForRead = 0,
    ReadyForTransform = 1,
    ReadyForWrite = 2,
    ProcessingRead = 3,
    ProcessingTransform = 4,
    ProcessingWrite = 5,
    Empty = 6,
    Full = 7,
    LastBufferToTransform = 8,
    LastBufferToWrite = 9,
    PendingRead = 10,
    PendingTransform = 11,
    PendingWrite = 12,
    StatusError = 13,
}

impl std::fmt::Display for BufferStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BufferStatus::ReadyForRead => write!(f, "READYFORREAD"),
            BufferStatus::ReadyForTransform => write!(f, "READYFORTRANSFORM"),
            BufferStatus::ReadyForWrite => write!(f, "READYFORWRITE"),
            BufferStatus::ProcessingRead => write!(f, "PROCESSING_READ"),
            BufferStatus::ProcessingTransform => write!(f, "PROCESSING_TRANSFORM"),
            BufferStatus::ProcessingWrite => write!(f, "PROCESSING_WRITE"),
            BufferStatus::Empty => write!(f, "EMPTY"),
            BufferStatus::Full => write!(f, "FULL"),
            BufferStatus::LastBufferToTransform => write!(f, "LAST_BUFFER_TO_TRANSFORM"),
            BufferStatus::LastBufferToWrite => write!(f, "LAST_BUFFER_TO_WRITE"),
            BufferStatus::PendingRead => write!(f, "PENDING_READ"),
            BufferStatus::PendingTransform => write!(f, "PENDING_TRANSFORM"),
            BufferStatus::PendingWrite => write!(f, "PENDING_WRITE"),
            BufferStatus::StatusError => write!(f, "STATUS_ERROR"),
        }
    }
}
```

### ChecksumAlgorithm
```rust
#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChecksumAlgorithm {
    None = 0,
    Md5 = 1,
    Sha256 = 2,
    Sha512 = 3,
}

impl std::fmt::Display for ChecksumAlgorithm {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ChecksumAlgorithm::None => write!(f, "NONE"),
            ChecksumAlgorithm::Md5 => write!(f, "MD5"),
            ChecksumAlgorithm::Sha256 => write!(f, "SHA256"),
            ChecksumAlgorithm::Sha512 => write!(f, "SHA512"),
        }
    }
}
```

### LogLevel
```rust
#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LogLevel {
    Trace = 0,
    Debug = 1,
    Info = 2,
    Warning = 3,
    Error = 4,
    Critical = 5,
}

impl std::fmt::Display for LogLevel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            LogLevel::Trace => write!(f, "[TRACE]"),
            LogLevel::Debug => write!(f, "[DEBUG]"),
            LogLevel::Info => write!(f, "[INFO]"),
            LogLevel::Warning => write!(f, "[WARNING]"),
            LogLevel::Error => write!(f, "[ERROR]"),
            LogLevel::Critical => write!(f, "[CRITICAL]"),
        }
    }
}
```

## BufferSlot Structure
Each slot in the ring buffer pool MUST be defined as:

```rust
use std::sync::atomic::{AtomicI32, AtomicU32, AtomicUsize, Ordering};
use std::sync::{Arc, Mutex};

pub struct BufferSlot {
    // Non-atomic fields (set once during construction)
    buffer_idx: usize,
    max_data_buffer_size: usize,
    data: Vec<u8>,

    // Atomic fields (modified by pipeline threads)
    status: AtomicI32,           // stores BufferStatus as i32
    data_buffer_size: AtomicUsize,
    transformed_data_buffer_size: AtomicUsize,
    checksum_alg: AtomicI32,     // stores ChecksumAlgorithm as i32
    checksum_val: AtomicU32,

    // Lock for non-atomic field access (data buffer mutations)
    data_lock: Mutex<()>,
}

impl BufferSlot {
    pub fn new(buffer_idx: usize, max_data_buffer_size: usize) -> Self {
        BufferSlot {
            buffer_idx,
            max_data_buffer_size,
            data: vec![0u8; max_data_buffer_size],
            status: AtomicI32::new(BufferStatus::ReadyForRead as i32),
            data_buffer_size: AtomicUsize::new(0),
            transformed_data_buffer_size: AtomicUsize::new(0),
            checksum_alg: AtomicI32::new(ChecksumAlgorithm::None as i32),
            checksum_val: AtomicU32::new(0),
            data_lock: Mutex::new(()),
        }
    }

    // Atomic getters/setters
    pub fn get_status(&self) -> BufferStatus {
        BufferStatus::from_i32(self.status.load(Ordering::SeqCst))
    }

    pub fn set_status(&self, status: BufferStatus) {
        self.status.store(status as i32, Ordering::SeqCst);
    }

    pub fn get_data_buffer_size(&self) -> usize {
        self.data_buffer_size.load(Ordering::SeqCst)
    }

    pub fn set_data_buffer_size(&self, size: usize) {
        self.data_buffer_size.store(size, Ordering::SeqCst);
    }

    pub fn get_transformed_data_buffer_size(&self) -> usize {
        self.transformed_data_buffer_size.load(Ordering::SeqCst)
    }

    pub fn set_transformed_data_buffer_size(&self, size: usize) {
        self.transformed_data_buffer_size.store(size, Ordering::SeqCst);
    }

    pub fn get_checksum_alg(&self) -> ChecksumAlgorithm {
        ChecksumAlgorithm::from_i32(self.checksum_alg.load(Ordering::SeqCst))
    }

    pub fn set_checksum_alg(&self, alg: ChecksumAlgorithm) {
        self.checksum_alg.store(alg as i32, Ordering::SeqCst);
    }

    pub fn get_checksum_val(&self) -> u32 {
        self.checksum_val.load(Ordering::SeqCst)
    }

    pub fn set_checksum_val(&self, val: u32) {
        self.checksum_val.store(val, Ordering::SeqCst);
    }

    // Non-atomic getters (no lock needed)
    pub fn get_buffer_idx(&self) -> usize {
        self.buffer_idx
    }

    pub fn get_max_data_buffer_size(&self) -> usize {
        self.max_data_buffer_size
    }

    // Data access (protected by lock)
    pub fn get_data(&self) -> std::sync::MutexGuard<'_, Vec<u8>> {
        self.data_lock.lock().unwrap()
    }

    pub fn clear(&self) {
        let mut data = self.data_lock.lock().unwrap();
        data.fill(0);
    }

    // Test methods
    pub fn test_status(&self, status: BufferStatus) -> bool {
        self.status.load(Ordering::SeqCst) == status as i32
    }

    pub fn test_checksum_alg(&self, alg: ChecksumAlgorithm) -> bool {
        self.checksum_alg.load(Ordering::SeqCst) == alg as i32
    }

    pub fn test_checksum_val(&self, val: u32) -> bool {
        self.checksum_val.load(Ordering::SeqCst) == val
    }
}

impl BufferStatus {
    pub fn from_i32(value: i32) -> Self {
        match value {
            0 => BufferStatus::ReadyForRead,
            1 => BufferStatus::ReadyForTransform,
            2 => BufferStatus::ReadyForWrite,
            3 => BufferStatus::ProcessingRead,
            4 => BufferStatus::ProcessingTransform,
            5 => BufferStatus::ProcessingWrite,
            6 => BufferStatus::Empty,
            7 => BufferStatus::Full,
            8 => BufferStatus::LastBufferToTransform,
            9 => BufferStatus::LastBufferToWrite,
            10 => BufferStatus::PendingRead,
            11 => BufferStatus::PendingTransform,
            12 => BufferStatus::PendingWrite,
            13 => BufferStatus::StatusError,
            _ => BufferStatus::StatusError,
        }
    }
}

impl ChecksumAlgorithm {
    pub fn from_i32(value: i32) -> Self {
        match value {
            0 => ChecksumAlgorithm::None,
            1 => ChecksumAlgorithm::Md5,
            2 => ChecksumAlgorithm::Sha256,
            3 => ChecksumAlgorithm::Sha512,
            _ => ChecksumAlgorithm::None,
        }
    }
}
```

**Atomic vs Non-atomic distinction**:
- `buffer_idx`, `max_data_buffer_size`, and `data` are **non-atomic** — set once during construction, never modified (except data buffer contents which are protected by `Mutex`).
- `status`, `data_buffer_size`, `transformed_data_buffer_size`, `checksum_alg`, and `checksum_val` are **atomic** — modified by pipeline threads, accessed via `.load(Ordering::SeqCst)` / `.store(value, Ordering::SeqCst)`.

## RingBuffer Trait
The public API MUST be defined as a trait:

```rust
use std::io::{Read, Write};

pub trait RingBuffer {
    // Thread Control
    fn start(&mut self);
    fn stop(&mut self);
    fn wait(&self);

    // Configuration
    fn set_read_fd(&mut self, fd: i32);
    fn set_write_fd(&mut self, fd: i32);

    // Logging
    fn set_logging_enabled(&mut self, enabled: bool);
    fn get_logging_enabled(&self) -> bool;
    fn set_output_stream(&mut self, stream: Box<dyn Write + Send>);
    fn get_output_stream(&self) -> &dyn Write;
    fn set_read_logging_enabled(&mut self, enabled: bool);
    fn get_read_logging_enabled(&self) -> bool;
    fn set_read_verbosity(&mut self, level: LogLevel);
    fn get_read_verbosity(&self) -> LogLevel;
    fn set_transform_logging_enabled(&mut self, enabled: bool);
    fn get_transform_logging_enabled(&self) -> bool;
    fn set_transform_verbosity(&mut self, level: LogLevel);
    fn get_transform_verbosity(&self) -> LogLevel;
    fn set_write_logging_enabled(&mut self, enabled: bool);
    fn get_write_logging_enabled(&self) -> bool;
    fn set_write_verbosity(&mut self, level: LogLevel);
    fn get_write_verbosity(&self) -> LogLevel;

    // Accessors
    fn get_status(&self, slot_idx: usize) -> BufferStatus;
    fn set_status(&mut self, slot_idx: usize, status: BufferStatus);
    fn test_status(&self, slot_idx: usize, status: BufferStatus) -> bool;
    fn get_checksum_alg(&self, slot_idx: usize) -> ChecksumAlgorithm;
    fn set_checksum_alg(&mut self, slot_idx: usize, alg: ChecksumAlgorithm);
    fn test_checksum_alg(&self, slot_idx: usize, alg: ChecksumAlgorithm) -> bool;
    fn get_checksum_val(&self, slot_idx: usize) -> u32;
    fn set_checksum_val(&mut self, slot_idx: usize, val: u32);
    fn test_checksum_val(&self, slot_idx: usize, val: u32) -> bool;
    fn get_max_size(&self, slot_idx: usize) -> usize;
    fn set_max_size(&mut self, slot_idx: usize, size: usize);
    fn get_data_size(&self, slot_idx: usize) -> usize;
    fn set_data_size(&mut self, slot_idx: usize, size: usize);
    fn get_transformed_size(&self, slot_idx: usize) -> usize;
    fn set_transformed_size(&mut self, slot_idx: usize, size: usize);
}
```

## Transform Function Type
```rust
pub type TransformFn = Box<dyn Fn(&mut Vec<u8>, &mut usize) + Send + Sync>;
```

The transform function receives the slot's data buffer and a mutable reference to the size. It modifies `data` in-place and updates `*size` with the new size.

## Error Handler Type
```rust
pub type ErrorHandler = Box<dyn Fn(usize, BufferStatus) -> i32 + Send + Sync>;
```

Returning non-zero triggers cooperative cancellation (pipeline shutdown).

## Constants
```rust
pub const MIN_NUMBER_SLOTS: usize = 1;
pub const DEFAULT_BUFFER_SIZE: usize = 4096;
pub const MIN_BUFFER_SIZE: usize = 1;
```

## SwtrRingBuffer Implementation Struct
The concrete implementation struct MUST be named `SwtrRingBuffer` and implement the `RingBuffer` trait.

### Member Variables
```rust
use std::sync::{Arc, Mutex, Condvar};
use std::thread;

pub struct SwtrRingBuffer {
    // Slot storage (shared via Arc for thread safety)
    slots: Vec<Arc<BufferSlot>>,
    num_slots: usize,

    // Index tracking — one independent atomic counter per pipeline stage
    read_index: AtomicUsize,
    transform_index: AtomicUsize,
    write_index: AtomicUsize,

    // File descriptors (atomic for cross-thread access)
    read_fd: AtomicI32,
    write_fd: AtomicI32,

    // Buffer size per slot
    buffer_size: usize,

    // Pipeline functions (set once at construction)
    error_handler: Option<ErrorHandler>,
    transform_fn: Option<TransformFn>,

    // Thread management (using std::thread::JoinHandle)
    read_handle: Mutex<Option<thread::JoinHandle<()>>>,
    transform_handle: Mutex<Option<thread::JoinHandle<()>>>,
    write_handle: Mutex<Option<thread::JoinHandle<()>>>,

    // Synchronization primitives
    sync_lock: Mutex<bool>,       // guard flag for double-start prevention
    cond_var: Condvar,

    // Running state
    running: AtomicBool,

    // Logging configuration (atomic for runtime reconfiguration)
    logging_enabled: AtomicBool,
    read_logging_enabled: AtomicBool,
    transform_logging_enabled: AtomicBool,
    write_logging_enabled: AtomicBool,
    read_verbosity: AtomicI32,
    transform_verbosity: AtomicI32,
    write_verbosity: AtomicI32,

    // Output stream (boxed trait object)
    output_stream: Mutex<Option<Box<dyn Write + Send>>>,

    // Log mutex (separate from sync_lock to avoid nested locking)
    log_mutex: Mutex<()>,
}
```

**Initialization rules**:
- `read_index`, `transform_index`, and `write_index` MUST all be initialized to `0`.
- `read_fd` and `write_fd` MUST be initialized to `-1`.
- All logging booleans MUST default to `false`.
- All log verbosity levels MUST default to `LogLevel::Info` (value 2).
- `output_stream` MUST default to `Box::new(std::io::stderr())`.

### Constructor (Rust Factory Function)
```rust
impl SwtrRingBuffer {
    pub fn new(num_slots: usize, initial_status: BufferStatus, buffer_size: usize,
               error_handler: Option<ErrorHandler>,
               transform_fn: Option<TransformFn>) -> Result<Self, String> {
        if num_slots < MIN_NUMBER_SLOTS {
            return Err(format!("num_slots must be >= {}", MIN_NUMBER_SLOTS));
        }
        if buffer_size < MIN_BUFFER_SIZE {
            return Err(format!("buffer_size must be >= {}", MIN_BUFFER_SIZE));
        }

        let slots: Vec<Arc<BufferSlot>> = (0..num_slots)
            .map(|i| Arc::new(BufferSlot::new(i, buffer_size)))
            .collect();

        Ok(SwtrRingBuffer {
            slots,
            num_slots,
            read_index: AtomicUsize::new(0),
            transform_index: AtomicUsize::new(0),
            write_index: AtomicUsize::new(0),
            read_fd: AtomicI32::new(-1),
            write_fd: AtomicI32::new(-1),
            buffer_size,
            error_handler,
            transform_fn,
            read_handle: Mutex::new(None),
            transform_handle: Mutex::new(None),
            write_handle: Mutex::new(None),
            sync_lock: Mutex::new(false),
            cond_var: Condvar::new(),
            running: AtomicBool::new(false),
            logging_enabled: AtomicBool::new(false),
            read_logging_enabled: AtomicBool::new(false),
            transform_logging_enabled: AtomicBool::new(false),
            write_logging_enabled: AtomicBool::new(false),
            read_verbosity: AtomicI32::new(LogLevel::Info as i32),
            transform_verbosity: AtomicI32::new(LogLevel::Info as i32),
            write_verbosity: AtomicI32::new(LogLevel::Info as i32),
            output_stream: Mutex::new(Some(Box::new(std::io::stderr()))),
            log_mutex: Mutex::new(()),
        })
    }
}
```

- MUST return an `Err` if `num_slots < MIN_NUMBER_SLOTS` or `buffer_size < MIN_BUFFER_SIZE`.
- MUST NOT start threads automatically.

### Pipeline Logic

**Read Loop**: Read from `read_fd` using Rust's file descriptor access (`libc::read`). Mark slot `ReadyForTransform` after fill. Set `data_buffer_size` to bytes read. On EOF (0 bytes returned), mark slot as `LastBufferToTransform`, advance index, notify condition variable, and break the loop. On error (-1), set status to `StatusError`, call error handler — if non-zero, stop the pipeline.

**Transform Loop**: Pass `slot.data` directly to the transform function (in-place modification). The transform modifies `data` and updates `*size`. Store the result size in `transformed_data_buffer_size`. Mark slot as `ReadyForWrite`, advance index, signal condition variable. If no transform function is set, copy data size to transformed size and mark ready for write. On `LastBufferToTransform`, mark slot as `LastBufferToWrite`, advance index, signal condition variable, and break.

**Write Loop**: Write `&slot.data[0..transformed_data_buffer_size]` to `write_fd` using Rust's file descriptor access (`libc::write`). On success, clear slot data using `slot.clear()`, reset sizes, mark slot as `ReadyForRead`, advance index, signal condition variable. On `LastBufferToWrite`, flush the output stream/file descriptor, mark slot as `ReadyForRead`, advance index, signal condition variable, and break. On error, set status to `StatusError`, call error handler — if non-zero, stop the pipeline.

### Thread Management
- `start()`: Create and start all three threads using `std::thread::spawn`. Use a guard (`sync_lock`) to prevent double-start.
- `stop()`: Set `running` flag to `false`, notify the condition variable.
- `wait()`: Join all three threads (blocking via `JoinHandle::join()`).

### Logging Architecture
Use a logging method that checks `logging_enabled` before formatting and outputting. Log messages MUST be thread-safe using the `log_mutex`. Format: `[LEVEL] message`.

### Accessor Implementation Rules
- `get_*` methods MUST use `.load(Ordering::SeqCst)` on atomic members and direct read on non-atomic members.
- `set_*` methods MUST use `.store(value, Ordering::SeqCst)` on atomic members and direct assignment on non-atomic members.
- `test_*` methods MUST perform an equality check using `.load(Ordering::SeqCst)` on the atomic member and compare against the argument.
- Every accessor MUST validate `slot_idx < num_slots` before accessing `slots[slot_idx]`.
- Out-of-bounds: `get_*` returns safe defaults (`StatusError`, `None`, or `0`), `test_*` returns `false`, non-const `set_*` silently returns.

### Slot Wrapping Strategy
Each pipeline stage uses its own independent index counter with modulo wrapping:
```rust
// Read loop uses read_index
let slot_idx = self.read_index.load(Ordering::SeqCst) % self.num_slots;

// Transform loop uses transform_index
let slot_idx = self.transform_index.load(Ordering::SeqCst) % self.num_slots;

// Write loop uses write_index
let slot_idx = self.write_index.load(Ordering::SeqCst) % self.num_slots;
```

### Naming Convention
- Package name: `swtr` (all lowercase)
- Type names: `PascalCase` (e.g., `SwtrRingBuffer`, `BufferSlot`)
- Method names: `snake_case` (e.g., `set_read_fd`, `get_transformed_size`)
- Field names: `snake_case` (e.g., `read_index`, `transform_fn`)
- Constants: `SCREAMING_SNAKE_CASE` (e.g., `MIN_NUMBER_SLOTS`)
- Enum values: `PascalCase` (Rust convention)

### File Organization
All Rust source files MUST be placed under the following directory structure:

```
src/<os>/rust/
├── Cargo.toml                 # Rust package manifest
└── src/
    ├── lib.rs                 # Library root (re-exports, public API)
    └── main.rs                # Test binary entry point (7-test matrix)
```

**Cargo package structure**:
- `lib.rs`: Contains all library code — enum definitions, `BufferSlot`, `RingBuffer` trait, type aliases, constants, and `SwtrRingBuffer` implementation.
- `main.rs`: Test binary entry point that exercises the 7-test matrix (T001-T007). Reads input from stdin, writes output to stdout.

### Test Binary
Each implementation MUST include a test binary written in Rust. The test binary exercises the 7-test matrix (T001-T007) and serves as an implementation example. The test binary MUST:
- Be compiled via `cargo run --bin ringbuffer_test` or `cargo test`
- Read input from stdin, write output to stdout
- Support configuration via command-line arguments (number of slots, buffer size, transform type)
- Exit with code 0 on success, 1 on fatal error

---

**IMPORTANT: This spec defines the functional requirements only. Build configuration is defined in `prompts/common/rust/build.md`.**
