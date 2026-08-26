# Swtr Ringbuffer Library (Java)

## Description
A high-performance, thread-safe ring buffer implementation in Java. This platform-insensitive implementation is shared across all operating systems (macOS, Fedora, Debian, Ubuntu) from a single codebase in `src/common/java/`.

## Build Requirements

- **Language**: Java SE 25 (primary), with fallback to Java SE 17+
- **Build System**: Apache Maven (`pom.xml`)
- **Version Source**: `version.mk` — read by `version.sh` to inject version into `pom.xml`

## Building

### Using Make (Recommended)
```bash
cd ringbuffer/src/common/java
make all              # Compile and package JAR artifact
make test             # Run T001–T007 regression tests
make clean            # Remove build artifacts
```

### Using Maven (Alternative)
```bash
cd ringbuffer/src/common/java
mvn compile           # Compile source code
mvn package           # Build JAR artifact (includes test classes)
mvn test              # Run T001–T007 regression tests
```

### Version Propagation
The `version.sh` script reads `version.mk` and injects version properties into `pom.xml`:
```bash
./version.sh          # Generates updated pom.xml with version from version.mk
```

## Library Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| JAR file | `target/ringbuffer-1.0.0.jar` | Built JAR with version from `version.mk` |

## Architecture

- **RingBuffer**: Abstract interface defining the public API
- **SwtrRingBuffer**: Concrete implementation with three pipeline threads (read, transform, write)
- **BufferSlot**: Data storage unit with state and checksum information

## Test Results

Full T001–T007 regression test matrix executed across all supported OSes (macOS native + Linux containers):
- All assertions pass
- Surefire-compatible test harness with `testAll()` method

## Platform Notes

Java is **platform-insensitive** — the same source code runs on all supported operating systems. No per-OS overrides are needed; a single common spec generates identical source for all platforms.
