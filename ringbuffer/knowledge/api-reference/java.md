# Java API Reference — SWTR Ringbuffer v1.0.0

## Package: `swtr`

All types are in the `swtr` package.

## Classes and Interfaces

| Type | Kind | Description |
|------|------|-------------|
| `RingBuffer` | Interface | Abstract public API for all implementations |
| `SwtrRingBuffer` | Class | Concrete implementation — three-stage pipeline |
| `BufferSlot` | Class | Individual buffer slot with status, checksum, and data |

## Enumerations

### BufferStatus
```java
public enum BufferStatus implements IntEnum {
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
    BufferStatus(int value) { this.value = value; }
    public int value() { return value; }
}
```

### ChecksumAlgorithm
```java
public enum ChecksumAlgorithm implements IntEnum {
    NONE(0), MD5(1), SHA256(2), SHA512(3);
    private final int value;
    ChecksumAlgorithm(int value) { this.value = value; }
    public int value() { return value; }
}
```

### LogLevel
```java
public enum LogLevel implements IntEnum {
    TRACE(0), DEBUG(1), INFO(2), WARNING(3), ERROR(4), CRITICAL(5);
    private final int value;
    LogLevel(int value) { this.value = value; }
    public int value() { return value; }
}
```

## Functional Interfaces

### TransformFunction
```java
@FunctionalInterface
public interface TransformFunction {
    void apply(byte[] data, int size);
}
```

### ErrorHandler
```java
@FunctionalInterface
public interface ErrorHandler {
    int handle(int slotIdx, BufferStatus status);
}
```

## Constants (SwtrRingBuffer)

| Constant | Value | Description |
|----------|-------|-------------|
| `MIN_NUMBER_SLOTS` | 1 | Minimum number of buffer slots |
| `DEFAULT_BUFFER_SIZE` | 4096 | Default slot data buffer size in bytes |
| `MIN_BUFFER_SIZE` | 1 | Minimum buffer size per slot |

## RingBuffer Interface

```java
public interface RingBuffer {

    // === Thread Control ===
    void start();                           // Start pipeline threads (non-blocking)
    void stop();                            // Stop pipeline, initiate cooperative cancellation
    void awaitTermination() throws InterruptedException;  // Block until all threads complete

    // === Configuration ===
    void setReadFd(int fd);                 // Set input file descriptor (e.g., 0 for stdin)
    void setWriteFd(int fd);                // Set output file descriptor (e.g., 1 for stdout)

    // === Logging (per-stage, independently configurable) ===
    void setLoggingEnabled(boolean enabled);
    boolean isLoggingEnabled();
    void setOutputStream(OutputStream stream);
    OutputStream getOutputStream();

    // Read stage logging
    void setReadLoggingEnabled(boolean enabled);
    boolean isReadLoggingEnabled();
    void setReadVerbosity(LogLevel level);
    LogLevel getReadVerbosity();

    // Transform stage logging
    void setTransformLoggingEnabled(boolean enabled);
    boolean isTransformLoggingEnabled();
    void setTransformVerbosity(LogLevel level);
    LogLevel getTransformVerbosity();

    // Write stage logging
    void setWriteLoggingEnabled(boolean enabled);
    boolean isWriteLoggingEnabled();
    void setWriteVerbosity(LogLevel level);
    LogLevel getWriteVerbosity();

    // === Slot Accessors (~20 methods — intentional for consumer flexibility) ===
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

## SwtrRingBuffer Concrete Implementation

### Constructor

```java
public SwtrRingBuffer(int numSlots, BufferStatus initialStatus, int bufferSize,
                      ErrorHandler errorHandler, TransformFunction transformFn)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `numSlots` | `int` | Number of buffer slots (≥ 1) |
| `initialStatus` | `BufferStatus` | Initial state for all slots (typically `READYFORREAD`) |
| `bufferSize` | `int` | Data buffer size per slot in bytes (≥ 1) |
| `errorHandler` | `ErrorHandler` | Error handler callback; `null` for default error handling |
| `transformFn` | `TransformFunction` | Transform function; `null` for identity transform (no-op) |

**Throws:** `IllegalArgumentException` if `numSlots < MIN_NUMBER_SLOTS` or `bufferSize < MIN_BUFFER_SIZE`

### Thread Management

- **Daemon threads**: All three pipeline threads are daemon threads — they will not prevent JVM shutdown.
- **Thread names**: `ringbuffer-read`, `ringbuffer-transform`, `ringbuffer-write`
- **Double-start guard**: Calling `start()` twice without stopping first logs a warning and returns silently.
- **NIO channels**: File descriptors are converted to `java.nio.channels.FileChannel` once at startup and reused throughout the pipeline lifecycle.

### Status Transitions

```
readyforread → processing_read → readyfortransform → processing_transform
    → readyforwrite → processing_write → readyforread

EOF propagation: LAST_BUFFER_TO_TRANSFORM → LAST_BUFFER_TO_WRITE
```

### Build Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| JAR | `target/ringbuffer-<version>.jar` | Maven-built JAR with all classes |

### Compilation Example (Maven)

```bash
mvn package -f src/common/java/pom.xml
java -cp target/ringbuffer-1.0.0.jar:. MainClass
```

## Key Design Decisions

- **Library-First API**: The ~20 slot-level accessor methods are intentional design choices providing maximum flexibility to library consumers for debugging, monitoring, and testing.
- **Atomic Indexes**: Each stage has its own `AtomicInteger` index counter — no contention between threads.
- **Cooperative Cancellation**: `stop()` sets a volatile flag and interrupts all threads; `awaitTermination()` joins them.
- **NVI Logging**: Per-stage logging is independently configurable at runtime via `AtomicBoolean` flags and `volatile LogLevel`.
- **Binary Symmetry**: Source code is byte-identical across all platforms (macOS, Debian, Fedora, Ubuntu, Raspios).
