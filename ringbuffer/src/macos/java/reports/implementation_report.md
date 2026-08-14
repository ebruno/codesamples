# Java Implementation Report — macOS

**Date**: 2025-08-14
**Language**: Java
**OS**: macOS (Apple Silicon)
**Version**: 1.0.0-1 (MAJOR=1, MINOR=0, SUBVERSION=0, BUILD_ID=1)
**Java SE**: 26 (primary target: SE 25, fallback chain: SE 24..SE 17)
**Maven**: 3.9.16

## Artifacts Produced

| Artifact | Path | Size |
|----------|------|------|
| JAR (uber) | `target/ringbuffer-1.0.0-1.jar` | 23,355 bytes |
| JAR (original) | `target/ringbuffer-1.0.0-1.jar` (unshaded) | 23,025 bytes |
| Sources JAR | `target/ringbuffer-1.0.0-1-sources.jar` | 424 bytes |

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

## Notes

- Java is platform-insensitive — identical source from `src/fedora/java/`
- No OS-specific changes needed; NIO channels abstract FD access uniformly across POSIX systems
