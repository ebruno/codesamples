# Functional Requirements — Ringbuffer (Go)

**Cross-Platform Consistency Requirement:** This library is deployed across multiple platforms. To ensure maintainability, the source code MUST be identical across all platforms. Do not adapt the coding style or architecture to the specific platform; follow these specifications strictly.

**Cross-Platform Generation Mandate:** When generating source code for any platform, the agent MUST produce byte-identical `.go` files across all platforms. The only platform-specific artifacts are:
- `go.mod` (if platform-specific build constraints or CGO settings are needed)

All source code files (`*.go`) MUST be generated from the same canonical template. Generate each platform's source independently from this spec — do not copy files between platforms.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/go/functional.md`) conflict with common specs (`prompts/common/go/functional.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

## Language Standards
- **Primary Version**: Go 1.24
- **Fallback Versions** (in priority order): Go 1.23, Go 1.22
- **Minimum Supported**: Go 1.22 — all implementations MUST be compatible with this version
- **Encoding**: UTF-8

## Shared Behavioral Contract (All Languages)
Every implementation must satisfy these requirements regardless of language:
- **Three-stage pipeline**: Independent read, transform, and write stages operating on a shared pool of buffer slots
- **Status-driven coordination**: Slots transition through states (`readyforread` → `readyfortransform` → `readyforwrite` → `readyforread`)
- **Cooperative cancellation**: Pipeline stages must support graceful shutdown via a stop signal / equivalent mechanism
- **Error handling**: An error handler callback that returns non-zero to trigger pipeline shutdown
- **EOF detection**: When read returns EOF (0 bytes), the pipeline must propagate `LAST_BUFFER_TO_TRANSFORM` → `LAST_BUFFER_TO_WRITE` through all stages, then terminate cleanly
- **Transform in-place**: The transform function receives the slot's data buffer and modifies it directly; `transformedDataBufferSize` must be updated with the result size
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
```go
type BufferStatus int32

const (
    ReadyForRead             BufferStatus = 0
    ReadyForTransform        BufferStatus = 1
    ReadyForWrite            BufferStatus = 2
    ProcessingRead           BufferStatus = 3
    ProcessingTransform      BufferStatus = 4
    ProcessingWrite          BufferStatus = 5
    Empty                    BufferStatus = 6
    Full                     BufferStatus = 7
    LastBufferToTransform    BufferStatus = 8
    LastBufferToWrite        BufferStatus = 9
    PendingRead              BufferStatus = 10
    PendingTransform         BufferStatus = 11
    PendingWrite             BufferStatus = 12
    StatusError              BufferStatus = 13
)

func (s BufferStatus) String() string {
    switch s {
    case ReadyForRead: return "READYFORREAD"
    case ReadyForTransform: return "READYFORTRANSFORM"
    case ReadyForWrite: return "READYFORWRITE"
    case ProcessingRead: return "PROCESSING_READ"
    case ProcessingTransform: return "PROCESSING_TRANSFORM"
    case ProcessingWrite: return "PROCESSING_WRITE"
    case Empty: return "EMPTY"
    case Full: return "FULL"
    case LastBufferToTransform: return "LAST_BUFFER_TO_TRANSFORM"
    case LastBufferToWrite: return "LAST_BUFFER_TO_WRITE"
    case PendingRead: return "PENDING_READ"
    case PendingTransform: return "PENDING_TRANSFORM"
    case PendingWrite: return "PENDING_WRITE"
    case StatusError: return "STATUS_ERROR"
    default: return "UNKNOWN"
    }
}
```

### ChecksumAlgorithm
```go
type ChecksumAlgorithm int32

const (
    None     ChecksumAlgorithm = 0
    MD5      ChecksumAlgorithm = 1
    SHA256   ChecksumAlgorithm = 2
    SHA512   ChecksumAlgorithm = 3
)

func (a ChecksumAlgorithm) String() string {
    switch a {
    case None: return "NONE"
    case MD5: return "MD5"
    case SHA256: return "SHA256"
    case SHA512: return "SHA512"
    default: return "UNKNOWN"
    }
}
```

### LogLevel
```go
type LogLevel int32

const (
    Trace    LogLevel = 0
    Debug    LogLevel = 1
    Info     LogLevel = 2
    Warning  LogLevel = 3
    Error    LogLevel = 4
    Critical LogLevel = 5
)

func (l LogLevel) String() string {
    switch l {
    case Trace: return "[TRACE]"
    case Debug: return "[DEBUG]"
    case Info: return "[INFO]"
    case Warning: return "[WARNING]"
    case Error: return "[ERROR]"
    case Critical: return "[CRITICAL]"
    default: return "[UNKNOWN]"
    }
}
```

## BufferSlot Structure
Each slot in the ring buffer pool MUST be defined as:

```go
type BufferSlot struct {
    bufferIdx                int              // non-atomic: slot index (set once)
    status                   atomic.Int32     // atomic: current buffer state (stores BufferStatus as int32)
    maxDataBufferSize        int              // non-atomic: maximum capacity (set once)
    dataBufferSize           atomic.Int32     // atomic: current bytes in data buffer
    transformedDataBufferSize atomic.Int32    // atomic: current bytes in transformed buffer
    checksumAlg              atomic.Int32     // atomic: algorithm used for checksum (stores ChecksumAlgorithm as int32)
    checksumVal              atomic.Uint32    // atomic: computed checksum value
    data                     []byte           // non-atomic: internal data buffer (raw bytes)
}

func NewBufferSlot(idx int, maxSize int) *BufferSlot {
    return &BufferSlot{
        bufferIdx:   idx,
        maxDataBufferSize: maxSize,
        data:        make([]byte, maxSize),
    }
}

func (s *BufferSlot) GetStatus() BufferStatus {
    return BufferStatus(s.status.Load())
}

func (s *BufferSlot) SetStatus(st BufferStatus) {
    s.status.Store(int32(st))
}

// Getters and setters for all atomic fields...
```

**Atomic vs Non-atomic distinction**:
- `bufferIdx`, `maxDataBufferSize`, and `data` are **non-atomic** — set once during construction, never modified.
- `status`, `dataBufferSize`, `transformedDataBufferSize`, `checksumAlg`, and `checksumVal` are **atomic** — modified by pipeline threads, accessed via `.Load()` / `.Store()`.

## RingBuffer Interface
The public API MUST be defined as an interface:

```go
type RingBuffer interface {
    // Thread Control
    Start()
    Stop()
    Wait()

    // Configuration
    SetReadFd(fd int)
    SetWriteFd(fd int)

    // Logging
    SetLoggingEnabled(enabled bool)
    IsLoggingEnabled() bool
    SetOutputStream(stream io.Writer)
    GetOutputStream() io.Writer
    SetReadLoggingEnabled(enabled bool)
    IsReadLoggingEnabled() bool
    SetReadVerbosity(level LogLevel)
    GetReadVerbosity() LogLevel
    SetTransformLoggingEnabled(enabled bool)
    IsTransformLoggingEnabled() bool
    SetTransformVerbosity(level LogLevel)
    GetTransformVerbosity() LogLevel
    SetWriteLoggingEnabled(enabled bool)
    IsWriteLoggingEnabled() bool
    SetWriteVerbosity(level LogLevel)
    GetWriteVerbosity() LogLevel

    // Accessors
    GetStatus(slotIdx int) BufferStatus
    SetStatus(slotIdx int, status BufferStatus)
    TestStatus(slotIdx int, status BufferStatus) bool
    GetChecksumAlg(slotIdx int) ChecksumAlgorithm
    SetChecksumAlg(slotIdx int, alg ChecksumAlgorithm)
    TestChecksumAlg(slotIdx int, alg ChecksumAlgorithm) bool
    GetChecksumVal(slotIdx int) uint32
    SetChecksumVal(slotIdx int, val uint32)
    TestChecksumVal(slotIdx int, val uint32) bool
    GetMaxSize(slotIdx int) int
    SetMaxSize(slotIdx int, size int)
    GetDataSize(slotIdx int) int
    SetDataSize(slotIdx int, size int)
    GetTransformedSize(slotIdx int) int
    SetTransformedSize(slotIdx int, size int)
}
```

## Transform Function Type
```go
type TransformFunction func(data []byte, size *int)
```

The transform function receives the slot's data buffer and a pointer to the size. It modifies `data` in-place and updates `*size` with the new size.

## Error Handler Type
```go
type ErrorHandler func(slotIdx int, status BufferStatus) int
```

Returning non-zero triggers cooperative cancellation (pipeline shutdown).

## Constants
```go
const (
    MinNumberSlots = 1
    DefaultBufferSize = 4096
    MinBufferSize = 1
)
```

## SwtrRingBuffer Implementation Struct
The concrete implementation struct MUST be named `SwtrRingBuffer` and implement the `RingBuffer` interface.

### Member Variables
```go
type SwtrRingBuffer struct {
    // Slot storage
    slots []*BufferSlot
    numSlots int

    // Index tracking — one independent atomic counter per pipeline stage
    readIndex    atomic.Int64
    transformIndex atomic.Int64
    writeIndex   atomic.Int64

    // File descriptors (atomic for cross-thread access)
    readFd  atomic.Int64
    writeFd atomic.Int64

    // Buffer size per slot
    bufferSize int

    // Pipeline functions (set once at construction)
    errorHandler ErrorHandler
    transformFn  TransformFunction

    // Thread management
    readCtx    context.Context
    readCancel context.CancelFunc
    transformCtx context.Context
    transformCancel context.CancelFunc
    writeCtx   context.Context
    writeCancel context.CancelFunc

    // Synchronization primitives
    syncMu     sync.Mutex
    cv         *sync.Cond

    // Logging configuration (atomic for runtime reconfiguration)
    loggingEnabled       atomic.Bool
    readLoggingEnabled   atomic.Bool
    transformLoggingEnabled atomic.Bool
    writeLoggingEnabled  atomic.Bool
    readVerbosity        atomic.Int32
    transformVerbosity   atomic.Int32
    writeVerbosity       atomic.Int32

    // Output stream (interface)
    outputStream io.Writer

    // Log mutex (separate from syncMu to avoid nested locking)
    logMu sync.Mutex
}
```

**Initialization rules**:
- `readIndex`, `transformIndex`, and `writeIndex` MUST all be initialized to `0`.
- `readFd` and `writeFd` MUST be initialized to `-1`.
- All logging booleans MUST default to `false`.
- All log verbosity levels MUST default to `LogLevelInfo` (value 2).
- `outputStream` MUST default to `os.Stderr`.

### Constructor (Go Factory Function)
```go
func NewSwtrRingBuffer(numSlots int, initialStatus BufferStatus, bufferSize int, errorHandler ErrorHandler, transformFn TransformFunction) (*SwtrRingBuffer, error)
```

- MUST return an error if `numSlots < MinNumberSlots` or `bufferSize < MinBufferSize`.
- MUST NOT start threads automatically.

### Pipeline Logic

**Read Loop**: Read from `readFd` using Go's file descriptor access (`syscall.Read`). Mark slot `ReadyForTransform` after fill. Set `dataBufferSize` to bytes read. On EOF (0 bytes returned), mark slot as `LastBufferToTransform`, advance index, signal condition variable, and break the loop. On error (-1), set status to `StatusError`, call error handler — if non-zero, stop the pipeline.

**Transform Loop**: Pass `slot.data` directly to the transform function (in-place modification). The transform modifies `data` and updates `*size`. Store the result size in `transformedDataBufferSize`. Mark slot as `ReadyForWrite`, advance index, signal condition variable. If no transform function is set, copy data size to transformed size and mark ready for write. On `LastBufferToTransform`, mark slot as `LastBufferToWrite`, advance index, signal condition variable, and break.

**Write Loop**: Write `slot.data[0:transformedDataBufferSize]` to `writeFd` using Go's file descriptor access (`syscall.Write`). On success, clear slot data using `fill(slot.data, 0)`, reset sizes, mark slot as `ReadyForRead`, advance index, signal condition variable. On `LastBufferToWrite`, flush the output stream/file descriptor, mark slot as `ReadyForRead`, advance index, signal condition variable, and break. On error, set status to `StatusError`, call error handler — if non-zero, stop the pipeline.

### Thread Management
- `Start()`: Create and start all three goroutines using `context.WithCancel`. Use a guard to prevent double-start.
- `Stop()`: Call cancel functions on all contexts, signal the condition variable.
- `Wait()`: Wait for all goroutines to complete (use a `sync.WaitGroup`).

### Logging Architecture
Use a logging method that checks `loggingEnabled` before formatting and outputting. Log messages MUST be thread-safe using the `logMu`. Format: `[LEVEL] message`.

### Accessor Implementation Rules
- `Get_*` methods MUST use `.Load()` on atomic members and direct read on non-atomic members.
- `Set_*` methods MUST use `.Store()` on atomic members and direct assignment on non-atomic members.
- `Test_*` methods MUST perform an equality check using `.Load()` on the atomic member and compare against the argument.
- Every accessor MUST validate `slotIdx < numSlots` before accessing `slots[slotIdx]`.
- Out-of-bounds: `Get_*` returns safe defaults (`StatusError`, `None`, or `0`), `Test_*` returns `false`, non-const `Set_*` silently returns.

### Slot Wrapping Strategy
Each pipeline stage uses its own independent index counter with modulo wrapping:
```go
// Read loop uses readIndex
slotIdx = int(readIndex.Load()) % numSlots

// Transform loop uses transformIndex
slotIdx = int(transformIndex.Load()) % numSlots

// Write loop uses writeIndex
slotIdx = int(writeIndex.Load()) % numSlots
```

### Naming Convention
- Package name: `swtr` (all lowercase)
- Type names: `PascalCase` (e.g., `SwtrRingBuffer`, `BufferSlot`)
- Method names: `PascalCase` (exported) or `camelCase` (unexported)
- Field names: `PascalCase` for exported, `camelCase` for unexported
- Constants: `PascalCase` (Go convention)

### File Organization
All Go source files MUST be placed under the package `swtr`. The directory structure is:

```
src/<os>/go/
├── go.mod                     # Go module definition
└── swtr.go                    # All source in a single file (Go convention)
```

**Single-file Go convention**: Unlike C++ and Java, Go projects typically place all package source in a single `.go` file or a small number of files. For this project, place all source code in `swtr.go` to maintain simplicity and avoid the complexity of Go's import system for a single-package library.

### Temporary Workspace
- All temporary files MUST be placed in a directory named `tmp`.
- Do NOT create temporary files in the project root or source directories.

### Generation Process Logging
- Create a directory at `src/<os>/go/logs/`.
- Maintain three log files: `functional.log`, `build.log`, `testing.log`.
- Log format: `[YYYY-MM-DD HH:MM:SS +/-HHMM] <Action Description>`.
- Append to existing log files; do NOT overwrite.
- Record every significant milestone in the corresponding log file.

### Import Discipline
Go uses `import` statements. The import order MUST follow Go conventions:
1. Standard library imports (alphabetical, grouped)
2. No third-party imports in the common spec

No redundant imports — only import what is directly used by each file.
