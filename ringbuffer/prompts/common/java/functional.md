# Functional Requirements — Ringbuffer (Java)

**Cross-Platform Consistency Requirement:** This library is deployed across multiple platforms. To ensure maintainability, the source code MUST be identical across all platforms. Do not adapt the coding style or architecture to the specific platform; follow these specifications strictly.

**Cross-Platform Generation Mandate:** When generating source code for any platform, the agent MUST produce byte-identical `.java` files across all platforms. The only platform-specific artifacts are:
- `pom.xml` (if platform-specific dependencies or profiles are needed)

All source code files (`*.java`) MUST be generated from the same canonical template. Generate each platform's source independently from this spec — do not copy files between platforms.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/java/functional.md`) conflict with common specs (`prompts/common/java/functional.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

## Language Standards
- **Primary Version**: Java SE 25 (JDK 25)
- **Fallback Versions** (in priority order): Java SE 24, Java SE 23, Java SE 22, Java SE 21, Java SE 20, Java SE 19, Java SE 17
- **Minimum Supported**: Java SE 17 (LTS) — all implementations MUST be compatible with this version
- **Encoding**: UTF-8

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
The following enums MUST be defined exactly as specified. Each enum value MUST have an explicit ordinal assignment.

### BufferStatus
```java
public enum BufferStatus {
    READYFORREAD(0),
    READYFORTRANSFORM(1),
    READYFORWRITE(2),
    PROCESSING_READ(3),
    PROCESSING_TRANSFORM(4),
    PROCESSING_WRITE(5),
    EMPTY(6),
    FULL(7),
    LAST_BUFFER_TO_TRANSFORM(8),
    LAST_BUFFER_TO_WRITE(9),
    PENDING_READ(10),
    PENDING_TRANSFORM(11),
    PENDING_WRITE(12),
    STATUS_ERROR(13);

    private final int value;

    BufferStatus(int value) {
        this.value = value;
    }

    public int getValue() {
        return value;
    }

    public static BufferStatus fromValue(int value) {
        for (BufferStatus status : values()) {
            if (status.value == value) return status;
        }
        return STATUS_ERROR;
    }
}
```

### ChecksumAlgorithm
```java
public enum ChecksumAlgorithm {
    NONE(0),
    MD5(1),
    SHA256(2),
    SHA512(3);

    private final int value;

    ChecksumAlgorithm(int value) {
        this.value = value;
    }

    public int getValue() {
        return value;
    }

    public static ChecksumAlgorithm fromValue(int value) {
        for (ChecksumAlgorithm alg : values()) {
            if (alg.value == value) return alg;
        }
        return NONE;
    }
}
```

### LogLevel
```java
public enum LogLevel {
    TRACE(0),
    DEBUG(1),
    INFO(2),
    WARNING(3),
    ERROR(4),
    CRITICAL(5);

    private final int value;

    LogLevel(int value) {
        this.value = value;
    }

    public int getValue() {
        return value;
    }

    public static LogLevel fromValue(int value) {
        for (LogLevel level : values()) {
            if (level.value == value) return level;
        }
        return INFO;
    }
}
```

## BufferSlot Structure
Each slot in the ring buffer pool MUST be defined as:

```java
public class BufferSlot {
    private final int bufferIdx;                                    // non-atomic: slot index (set once)
    private volatile BufferStatus status;                           // atomic-equivalent: current buffer state
    private final int maxDataBufferSize;                            // non-atomic: maximum capacity (set once)
    private volatile int dataBufferSize;                            // atomic-equivalent: current bytes in data buffer
    private volatile int transformedDataBufferSize;                 // atomic-equivalent: current bytes in transformed buffer
    private volatile ChecksumAlgorithm checksumAlg;                 // atomic-equivalent: algorithm used for checksum
    private volatile int checksumVal;                               // atomic-equivalent: computed checksum value
    private final byte[] data;                                      // non-atomic: internal data buffer (raw bytes)

    public BufferSlot(int bufferIdx, int maxDataBufferSize) {
        this.bufferIdx = bufferIdx;
        this.maxDataBufferSize = maxDataBufferSize;
        this.data = new byte[maxDataBufferSize];
    }

    // Getters and setters for all fields...
}
```

**Atomic-equivalent distinction**: Java does not have `std::atomic`. Use `volatile` for fields that are read/written by multiple pipeline threads. The `bufferIdx`, `maxDataBufferSize`, and `data` fields are set once during construction and never modified afterward, so they do not need `volatile`.

## RingBuffer Interface
The public API MUST be defined as an interface:

```java
public interface RingBuffer {
    // Thread Control
    void start();
    void stop();
    void awaitTermination() throws InterruptedException;

    // Configuration
    void setReadFd(int fd);
    void setWriteFd(int fd);

    // Logging
    void setLoggingEnabled(boolean enabled);
    boolean isLoggingEnabled();
    void setOutputStream(java.io.OutputStream stream);
    java.io.OutputStream getOutputStream();
    void setReadLoggingEnabled(boolean enabled);
    boolean isReadLoggingEnabled();
    void setReadVerbosity(LogLevel level);
    LogLevel getReadVerbosity();
    void setTransformLoggingEnabled(boolean enabled);
    boolean isTransformLoggingEnabled();
    void setTransformVerbosity(LogLevel level);
    LogLevel getTransformVerbosity();
    void setWriteLoggingEnabled(boolean enabled);
    boolean isWriteLoggingEnabled();
    void setWriteVerbosity(LogLevel level);
    LogLevel getWriteVerbosity();

    // Accessors
    BufferStatus getStatus(int slotIdx);
    void setStatus(int slotIdx, BufferStatus status);
    boolean testStatus(int slotIdx, BufferStatus status);
    ChecksumAlgorithm getChecksumAlg(int slotIdx);
    void setChecksumAlg(int slotIdx, ChecksumAlgorithm alg);
    boolean testChecksumAlg(int slotIdx, ChecksumAlgorithm alg);
    int getChecksumVal(int slotIdx);
    void setChecksumVal(int slotIdx, int val);
    boolean testChecksumVal(int slotIdx, int val);
    int getMaxSize(int slotIdx);
    void setMaxSize(int slotIdx, int size);
    int getDataSize(int slotIdx);
    void setDataSize(int slotIdx, int size);
    int getTransformedSize(int slotIdx);
    void setTransformedSize(int slotIdx, int size);
}
```

## Transform Function Interface
```java
@FunctionalInterface
public interface TransformFunction {
    void apply(byte[] data, int[] sizeHolder);
}
```

The `sizeHolder` array is used because Java does not support pass-by-reference for primitives. The transform function modifies `data` in-place and updates `sizeHolder[0]` with the new size.

## Error Handler Interface
```java
@FunctionalInterface
public interface ErrorHandler {
    int handle(int slotIdx, BufferStatus status);
}
```

Returning non-zero triggers cooperative cancellation (pipeline shutdown).

## Constants
```java
public static final int MIN_NUMBER_SLOTS = 1;
public static final int DEFAULT_BUFFER_SIZE = 4096;
public static final int MIN_BUFFER_SIZE = 1;
```

## SwtrRingBuffer Implementation Class
The concrete implementation class MUST be named `SwtrRingBuffer` and implement the `RingBuffer` interface.

### Member Variables
```java
public class SwtrRingBuffer implements RingBuffer {
    // Slot storage
    private final BufferSlot[] slots;
    private final int numSlots;

    // Index tracking — one independent counter per pipeline stage (AtomicInteger for thread safety)
    private final AtomicInteger readIndex = new AtomicInteger(0);
    private final AtomicInteger transformIndex = new AtomicInteger(0);
    private final AtomicInteger writeIndex = new AtomicInteger(0);

    // File descriptors (AtomicInteger for cross-thread access)
    private final AtomicInteger readFd = new AtomicInteger(-1);
    private final AtomicInteger writeFd = new AtomicInteger(-1);

    // Buffer size per slot
    private final int bufferSize;

    // Pipeline functions (set once at construction)
    private final ErrorHandler errorHandler;
    private final TransformFunction transformFn;

    // Thread management
    private volatile Thread readThread;
    private volatile Thread transformThread;
    private volatile Thread writeThread;

    // Synchronization primitives
    private final Object syncLock = new Object();
    private volatile boolean running;

    // Logging configuration (AtomicBoolean for runtime reconfiguration)
    private final AtomicBoolean loggingEnabled = new AtomicBoolean(false);
    private final AtomicBoolean readLoggingEnabled = new AtomicBoolean(false);
    private final AtomicBoolean transformLoggingEnabled = new AtomicBoolean(false);
    private final AtomicBoolean writeLoggingEnabled = new AtomicBoolean(false);
    private volatile LogLevel readVerbosity = LogLevel.INFO;
    private volatile LogLevel transformVerbosity = LogLevel.INFO;
    private volatile LogLevel writeVerbosity = LogLevel.INFO;

    // Output stream (reference, not pointer)
    private volatile java.io.OutputStream outputStream = System.err;

    // Log lock (separate from syncLock to avoid nested locking)
    private final Object logLock = new Object();
}
```

**Initialization rules**:
- `readIndex`, `transformIndex`, and `writeIndex` MUST all be initialized to `0`.
- `readFd` and `writeFd` MUST be initialized to `-1`.
- All logging booleans MUST default to `false`.
- All log verbosity levels MUST default to `LogLevel.INFO`.
- `outputStream` MUST default to `System.err`.

### Constructor
```java
public SwtrRingBuffer(int numSlots, BufferStatus initialStatus, int bufferSize, ErrorHandler errorHandler, TransformFunction transformFn)
```

- MUST throw `IllegalArgumentException` if `numSlots < MIN_NUMBER_SLOTS` or `bufferSize < MIN_BUFFER_SIZE`.
- MUST NOT start threads automatically.

### Pipeline Logic

**Read Loop**: Read from `readFd` using Java NIO or POSIX file descriptor access. Mark slot `READYFORTRANSFORM` after fill. Set `dataBufferSize` to bytes read. On EOF (0 bytes returned), mark slot as `LAST_BUFFER_TO_TRANSFORM`, advance index, notify all waiting threads, and break the loop. On error (-1), set status to `STATUS_ERROR`, call error handler — if non-zero, stop the pipeline.

**Transform Loop**: Pass `slot.data` directly to the transform function (in-place modification). The transform modifies `data` and updates `sizeHolder[0]`. Store the result size in `transformedDataBufferSize`. Mark slot as `READYFORWRITE`, advance index, notify all. If no transform function is set, copy data size to transformed size and mark ready for write. On `LAST_BUFFER_TO_TRANSFORM`, mark slot as `LAST_BUFFER_TO_WRITE`, advance index, notify all, and break.

**Write Loop**: Write `slot.data[0..transformedDataBufferSize]` to `writeFd`. On success, clear slot data using `Arrays.fill(slot.data, (byte)0)`, reset sizes, mark slot as `READYFORREAD`, advance index, notify all. On `LAST_BUFFER_TO_WRITE`, flush the output stream/file descriptor, mark slot as `READYFORREAD`, advance index, notify all, and break. On error, set status to `STATUS_ERROR`, call error handler — if non-zero, stop the pipeline.

### Thread Management
- `start()`: Create and start all three threads if not already running. Use a guard to prevent double-start.
- `stop()`: Set `running` flag, interrupt all threads, notify the sync lock.
- `awaitTermination()`: Join all three threads (blocking).

### Logging Architecture
Use a logging method that checks `loggingEnabled` before formatting and outputting. Log messages MUST be thread-safe using the `logLock`. Format: `[LEVEL] message`.

### Accessor Implementation Rules
- `get_*` methods MUST use `.get()` on `AtomicInteger`/`AtomicBoolean` members and direct read on non-atomic members.
- `set_*` methods MUST use `.set()` on atomic members and direct assignment on non-atomic members.
- `test_*` methods MUST perform an equality check using `.get()` on the atomic member and compare against the argument.
- Every accessor MUST validate `slotIdx < numSlots` before accessing `slots[slotIdx]`.
- Out-of-bounds: `get_*` returns safe defaults (`STATUS_ERROR`, `NONE`, or `0`), `test_*` returns `false`, non-const `set_*` silently returns.

### Slot Wrapping Strategy
Each pipeline stage uses its own independent index counter with modulo wrapping:
```java
// Read loop uses readIndex
slotIdx = readIndex.get() % numSlots;

// Transform loop uses transformIndex
slotIdx = transformIndex.get() % numSlots;

// Write loop uses writeIndex
slotIdx = writeIndex.get() % numSlots;
```

### Naming Convention
- Class names: `PascalCase` (e.g., `SwtrRingBuffer`, `BufferSlot`)
- Method names: `camelCase` (e.g., `setReadFd`, `getTransformedSize`)
- Field names: `camelCase` (e.g., `readIndex`, `transformFn`)
- Constants: `UPPER_SNAKE_CASE` (e.g., `MIN_NUMBER_SLOTS`)

### File Organization
All Java source files MUST be placed under a package directory structure: `src/<os>/java/swtr/`. The package declaration MUST be `package swtr;` in every file.

File mapping:
| File | Purpose |
|------|---------|
| `BufferStatus.java` | BufferStatus enum definition |
| `ChecksumAlgorithm.java` | ChecksumAlgorithm enum definition |
| `LogLevel.java` | LogLevel enum definition |
| `RingBuffer.java` | RingBuffer interface |
| `TransformFunction.java` | TransformFunction functional interface |
| `ErrorHandler.java` | ErrorHandler functional interface |
| `BufferSlot.java` | BufferSlot class definition |
| `SwtrRingBuffer.java` | SwtrRingBuffer implementation (all pipeline logic) |
| `README.md` | Build and usage documentation |

**Function Distribution Rule**: The `SwtrRingBuffer.java` file MUST contain all pipeline logic (read loop, transform loop, write loop) and accessor methods. No other `.java` files may contain more than 3 method definitions (excluding constructors and interface implementations).

### Temporary Workspace
- All temporary files MUST be placed in a directory named `tmp`.
- Do NOT create temporary files in the project root or source directories.

### Generation Process Logging
- Create a directory at `src/<os>/java/logs/`.
- Maintain three log files: `functional.log`, `build.log`, `testing.log`.
- Log format: `[YYYY-MM-DD HH:MM:SS +/-HHMM] <Action Description>`.
- Append to existing log files; do NOT overwrite.
- Record every significant milestone in the corresponding log file.

### Include/Import Discipline
Java uses `import` statements instead of C++ includes. The import order MUST be:
1. `java.*` imports (alphabetical)
2. `javax.*` imports (alphabetical)
3. No third-party imports in the common spec

No redundant imports — only import what is directly used by each file.
