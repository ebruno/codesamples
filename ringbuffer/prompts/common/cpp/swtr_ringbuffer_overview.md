/** @mainpage Ringbuffer Library

A high-performance, cross-platform circular buffer library designed for binary symmetry and deterministic execution.

**Implemented:** C++, Java, Python &nbsp;|&nbsp; **7 target OSes:** macOS, Fedora, Debian, Ubuntu, Arch Linux, FreeBSD 14, Raspberry Pi OS &nbsp;|&nbsp; **Pipeline:** Read → Transform → Write with lock-free atomic coordination

---

## What It Does

The Ringbuffer library implements a **three-stage pipelined architecture** (Read → Transform → Write) that connects independent threads through a fixed-size array of shared slots. Each slot carries its own state machine, checksum, and data buffer, enabling lock-free concurrent processing with cache-line-aligned counters to prevent false sharing.

### How the Pipeline Works

1. **Read thread** fills slots from an input file descriptor, marking each slot `readyfortransform` when full. On EOF, it marks the final slot with `LAST_BUFFER_TO_TRANSFORM`.
2. **Transform thread** applies a user-supplied function to each slot's data, computes an atomic checksum (MD5/SHA256/SHA512), and marks the slot `readyforwrite`.
3. **Write thread** writes transformed data to an output file descriptor, clears the slot buffer, and resets it to `readyforread`. On the last buffer, it flushes (`fsync`) before signaling completion.

Each stage uses its own independent atomic index counter, so threads operate on slots without contention. The `wait()` method blocks until all data has flowed through the entire pipeline and threads have joined cleanly.

---

## Core Features

- **Pipelined Architecture** — Decoupled read, transform, and write loops for maximum throughput
- **Performance** — Cache-line alignment (64-byte), dead code elimination, thin link-time optimization
- **Data Integrity** — Integrated checksumming (MD5, SHA256, SHA512) per buffer slot
- **Diagnostics** — Per-stage (read/transform/write) independently configurable logging verbosity
- **Cooperative Cancellation** — Graceful shutdown via stop signal or equivalent mechanism
- **Error Handling** — Error handler callback that returns non-zero to trigger pipeline shutdown
- **EOF Detection** — Automatic propagation of `LAST_BUFFER_*` status through all stages

---

## Platform Support

| OS | C++ | Java | Python |
|----|-----|------|--------|
| macOS | ✅ | ✅ | ✅ |
| Fedora | ✅ | ✅ | ✅ |
| Debian | ✅ | ✅ | ✅ |
| Ubuntu | ✅ | ✅ | ✅ |
| Arch Linux | ✅ | ✅ | ✅ |
| FreeBSD 14 | ✅ | ✅ | ✅ |
| Raspberry Pi OS | ⚠️ Unsupported (GCC 12 lacks C++20 `<format>`) | ✅ | ✅ |

**Binary symmetry:** Source code is byte-identical across platforms within the same OS family via symlinks to a single canonical source tree.

---

## Architecture Overview

### C++ Class Hierarchy

```
swtr::RingBuffer (abstract base class)
    └── swtr::SwtrRingBuffer (concrete implementation)

swtr::BufferSlot (struct — shared slot with state machine, checksum, data buffer)
```

### Java Class Hierarchy

```
swtr.RingBuffer (interface)
    └── swtr.SwtrRingBuffer (concrete implementation)

swtr.BufferSlot, swtr.BufferStatus, swtr.ChecksumAlgorithm, swtr.LogLevel
```

---

## Quick Example (C++)

```cpp
#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"
using namespace swtr;

int main() {
    auto transform = [](std::vector<uint8_t>& data, size_t& size) {
        for (size_t i = 0; i < size; ++i)
            if (data[i] >= 'a' && data[i] <= 'z') data[i] -= 32;
    };

    auto rb = std::make_unique<SwtrRingBuffer>(4, BufferStatus::readyforread, 4096, nullptr, transform);
    rb->set_read_fd(STDIN_FILENO);
    rb->set_write_fd(STDOUT_FILENO);
    rb->start();
    rb->wait();   // blocks until all data flows through read → transform → write
    rb->stop();
}
```

---

## Build & Test Pattern (All Languages)

- **Build:** `verify_build` → `<os>/<lang>/Makefile all` — builds artifacts
- **Test:** `run_regression` → `tests/Makefile verify` — runs T001–T007 test matrix

---

## License

This project is developed through prompt-driven LLM development using LM Studio Bionic.

*/
