# Java Implementation Report — Fedora

**Date**: 2025-08-14
**Language**: Java
**OS**: Fedora (reference: macOS host with Java 26 / Maven 3.9.16)
**Version**: 1.0.0-1 (MAJOR=1, MINOR=0, SUBVERSION=0, BUILD_ID=1)
**Java SE**: 26 (primary target: SE 25, fallback chain: SE 24..SE 17)
**Maven**: 3.9.16

## Artifacts Produced

| Artifact | Path | Size |
|----------|------|------|
| JAR (uber) | `target/ringbuffer-1.0.0-1.jar` | 23,355 bytes |
| JAR (original) | `target/ringbuffer-1.0.0-1.jar` (unshaded) | 23,025 bytes |
| Sources JAR | `target/ringbuffer-1.0.0-1-sources.jar` | 424 bytes |

## Source Files

| File | Lines | Description |
|------|-------|-------------|
| `swtr/BufferSlot.java` | 134 | Thread-safe slot with volatile fields |
| `swtr/BufferStatus.java` | 48 | Enum: READYFORREAD, PROCESSING_READ, etc. |
| `swtr/ChecksumAlgorithm.java` | 37 | Enum: NONE, CRC32, XOR |
| `swtr/ErrorHandler.java` | 15 | Functional interface for error handling |
| `swtr/LogLevel.java` | 39 | Enum: TRACE, DEBUG, INFO, WARNING, ERROR |
| `swtr/RingBuffer.java` | 213 | Abstract interface definition |
| `swtr/SwtrRingBuffer.java` | 778 | Core implementation (3-stage pipeline) |
| `swtr/TransformFunction.java` | 15 | Functional interface for transform |
| `swtr/test/TestRingbuffer.java` | 493 | Test harness (T001-T007) |
| **Total** | **1,772** | |

## Build Configuration

- **Build System**: Maven (pom.xml)
- **Compiler Release**: 26
- **Plugins**: compiler 3.13.0, jar 3.4.1, shade 3.5.1, surefire 3.2.5
- **Module System**: Requires `--add-opens java.base/java.io=ALL-UNNAMED` for reflection-based FD access

## Test Results

| Test | Description | Result |
|------|-------------|--------|
| T001 | Default (identity transform) | PASSED |
| T002 | Stress test (1 slot, 1-byte buffer) | PASSED |
| T003 | Uppercase transform | PASSED |
| T004 | Small input, fast EOF | PASSED |
| T005 | Fatal error mode | PASSED |
| T006 | Non-fatal error mode | PASSED |
| T007 | XOR transform (binary data) | PASSED |

**All 7 tests passed.**

## Key Implementation Decisions

1. **File Descriptor Access**: Uses reflection to create `FileInputStream(FileDescriptor)` and `FileOutputStream(FileDescriptor)` — the int-arg constructors were removed in Java 17+. A `FileDescriptor` object is created via its public no-arg constructor, then its private `fd` int field is set via reflection.

2. **Cached NIO Channels**: Channels are created once in `start()` and cached as volatile fields, reused throughout the pipeline lifecycle. This avoids closing/reopening FDs on each operation (which would break shared FD semantics).

3. **Module System Compatibility**: Requires `--add-opens` JVM flags for reflection on `java.io.FileDescriptor.fd`. Added to surefire plugin `argLine` for test execution.

4. **Pure Java**: No native code, no JNI, no C extensions — pure Java implementation as required.

5. **Test Binary**: `TestRingbuffer.java` serves as both test harness and implementation example, runnable via `java -jar ringbuffer-1.0.0-1.jar <test_number> [num_slots] [buffer_size]`.

## Known Limitations

- Requires `--add-opens` JVM flags for reflection-based FD access (Java 17+ module system)
- File descriptor sharing relies on POSIX semantics; closing one stream may affect others sharing the same FD
