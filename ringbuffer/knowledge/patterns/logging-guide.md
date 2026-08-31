# Logging Guide — Per-Stage Configuration

## Overview

The ringbuffer provides a Non-Virtual Public Interface (NVI) logging system with per-stage (read/transform/write) independently configurable verbosity levels. All three stages can be enabled/disabled and set to different log levels simultaneously.

## Key Types

### LogLevel
| Level | Value | Description |
|-------|-------|-------------|
| `TRACE` | 0 | Most verbose — every operation |
| `DEBUG` | 1 | Debug-level details |
| `INFO` | 2 | Informational messages (default) |
| `WARNING` | 3 | Warnings and non-fatal issues |
| `ERROR` | 4 | Error conditions |
| `CRITICAL` | 5 | Most restrictive — only critical messages |

Messages with a level value **below** the configured verbosity are suppressed. For example, if `read_verbosity` is set to `INFO(2)`, only TRACE(0), DEBUG(1), and INFO(2) messages pass through.

## C++ Configuration

```cpp
#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"
using namespace swtr;

auto rb = std::make_unique<SwtrRingBuffer>(4, BufferStatus::readyforread, 4096, nullptr, transform);

// Enable logging globally
rb->set_logging_enabled(true);
rb->set_output_stream(std::cerr);

// Per-stage: enable + set verbosity
rb->set_read_logging_enabled(true);
rb->set_read_verbosity(LogLevel::Debug);

rb->set_transform_logging_enabled(true);
rb->set_transform_verbosity(LogLevel::Info);

rb->set_write_logging_enabled(true);
rb->set_write_verbosity(LogLevel::Info);
```

## Java Configuration

```java
import swtr.*;

SwtrRingBuffer rb = new SwtrRingBuffer(4, BufferStatus.READYFORREAD, 4096, null, transform);

// Enable logging globally
rb.setLoggingEnabled(true);
rb.setOutputStream(System.err);

// Per-stage: enable + set verbosity
rb.setReadLoggingEnabled(true);
rb.setReadVerbosity(LogLevel.DEBUG);

rb.setTransformLoggingEnabled(true);
rb.setTransformVerbosity(LogLevel.INFO);

rb.setWriteLoggingEnabled(true);
rb.setWriteVerbosity(LogLevel.INFO);
```

## Python Configuration

```python
from swtr_ringbuffer import SwtrRingBuffer, LogLevel

rb = SwtrRingBuffer(4, BufferStatus.READYFORREAD, 4096)

# Enable logging globally
rb.set_logging_enabled(True)
rb.set_output_stream(sys.stderr)

# Per-stage: enable + set verbosity
rb.set_read_logging_enabled(True)
rb.set_read_verbosity(LogLevel.DEBUG)

rb.set_transform_logging_enabled(True)
rb.set_transform_verbosity(LogLevel.INFO)

rb.set_write_logging_enabled(True)
rb.set_write_verbosity(LogLevel.INFO)
```

## Thread-Safe Runtime Reconfiguration

All logging settings can be changed at runtime without stopping the pipeline:
- `set_*_logging_enabled()` — toggle per-stage logging on/off
- `set_*_verbosity()` — change verbosity level mid-pipeline

The C++ implementation uses `std::atomic<bool>` for enabled flags and volatile accessors. Java uses `AtomicBoolean` and `volatile LogLevel`. Python uses plain booleans protected by a separate log lock.

## Verbosity Resolution (Python)

In the Python implementation, `_log()` determines effective verbosity from the calling thread's name:
- `ringbuffer-read` → `self.read_verbosity`
- `ringbuffer-transform` → `self.transform_verbosity`
- `ringbuffer-write` → `self.write_verbosity`
- All other threads (e.g., main) → no verbosity filtering (`TRACE`)
