# Ringbuffer Library

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

## What is a Circular Buffer?

A **circular buffer** (also called a ring buffer) is a fixed-size data structure that uses a single, pre-allocated array to store streaming data. When the buffer fills up, new data overwrites the oldest entries — hence "circular."

**Why use one?**
- **Zero-allocation streaming**: No dynamic memory allocation during operation — critical for real-time systems, audio processing, and network packet handling
- **Bounded memory usage**: Predictable memory footprint regardless of data volume
- **Lock-free concurrency**: Multiple threads can read/write simultaneously without mutexes when using proper slot-based designs
- **Deterministic latency**: No garbage collection pauses or heap fragmentation

**Common use cases:**
- Audio/video streaming pipelines (capture → process → output)
- Network packet buffers (receive → parse → dispatch)
- Log aggregation systems (collect → transform → persist)
- Real-time sensor data processing

The Ringbuffer library implements a **pipelined circular buffer** — extending the basic concept with three independent processing stages (Read → Transform → Write) that operate concurrently on shared slots.

---

## Why Ringbuffer?

### Performance Characteristics
- **Throughput**: Pipelined architecture achieves near-linear scaling with slot count (4+ slots recommended)
- **Latency**: Single-pass processing — data flows through all stages without intermediate storage
- **Memory efficiency**: Fixed-size allocation, no fragmentation, cache-line aligned (64-byte boundaries)

### Reliability Features
- **Data integrity**: Per-slot checksums (MD5/SHA256/SHA512) detect corruption
- **Graceful shutdown**: Cooperative cancellation via `std::jthread` or equivalent
- **Error recovery**: Custom error handlers can inspect slot state and decide whether to continue

### Developer Experience
- **Simple API**: Basic usage requires 5 lines of code; advanced features are opt-in
- **Cross-platform**: Same source compiles on 7 OSes with identical behavior
- **Multi-language**: C++, Java, and Python implementations share the same functional specification

### When to Use Ringbuffer
- ✅ Real-time data processing pipelines (audio, video, network)
- ✅ High-throughput ETL operations (extract → transform → load)
- ✅ Systems requiring deterministic memory usage
- ❌ Variable-size data with frequent resize operations (use `std::vector` instead)
- ❌ Single-threaded batch processing (overhead not justified)

---

## Ringbuffer vs Alternatives

| Feature | Ringbuffer | std::vector | std::queue (deque) | Custom FIFO |
|---------|------------|-------------|-------------------|-------------|
| Fixed memory | ✅ Yes | ❌ No (grows) | ⚠️ Dynamic | ✅ Yes |
| Lock-free multi-threaded | ✅ Yes | ❌ No | ⚠️ Requires mutex | ⚠️ Depends on impl |
| Zero allocation (runtime) | ✅ Yes | ❌ No | ⚠️ Sometimes | ✅ Yes |
| Backpressure support | ✅ Built-in | ❌ No | ⚠️ Manual | ⚠️ Manual |
| Pipeline support | ✅ 3-stage | ❌ No | ❌ No | ❌ No |
| Checksum verification | ✅ Built-in | ❌ No | ❌ No | ❌ No |
| Cross-platform | ✅ 7 OSes | ⚠️ Platform-specific | ⚠️ Platform-specific | ❌ Custom |

---

## Extending the Pipeline

The ringbuffer's class-based design makes it easy to extend beyond the default three-stage pipeline (Read → Transform → Write). Since `RingBuffer` is an abstract base class and the slot state machine is well-defined, you can add custom processing stages.

### Add Custom Pipeline Stages (C++)

```cpp
// Read → Transform → Validate → Write (4 stages)
class ValidatingRingBuffer : public SwtrRingBuffer {
public:
    ValidatingRingBuffer(size_t num_slots, size_t buffer_size)
        : SwtrRingBuffer(num_slots, BufferStatus::readyforread, buffer_size) {}

protected:
    // Override transform stage to add validation between transform and write
    void do_transform(size_t slot_idx) override {
        SwtrRingBuffer::do_transform(slot_idx);  // Run standard transform
        
        // Add validation logic
        BufferStatus status = get_status(slot_idx);
        if (status == BufferStatus::readyforwrite) {
            // Validate data integrity before write stage
            if (!validate_slot_data(slot_idx)) {
                handle_error(slot_idx, BufferStatus::STATUS_ERROR);
            }
        }
    }

private:
    bool validate_slot_data(size_t slot_idx) {
        // Custom validation logic here
        return true;  // Simplified for example
    }
};
```

### Common Extension Patterns

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **Read → Transform → Validate → Write** | Add checksum verification or data integrity checks before output | Financial transactions, medical data |
| **Read → Transform → Encrypt → Write** | Insert encryption stage for secure transmission | Secure messaging, payment processing |
| **Read → Transform → Split → Merge → Write** | Fan-out/fan-in for parallel processing | Video frame processing, batch jobs |
| **Read → Transform → Cache → Write** | Add caching layer for retry logic | Unreliable networks, intermittent storage |
| **Read → Transform → Audit → Write** | Add logging/audit trail without affecting data flow | Compliance, debugging |

### How It Works

The slot state machine (`BufferStatus` enum) defines the transitions between stages. Each stage:
1. Reads slots in `readyfor<stage>` state
2. Processes data and updates slot size/checksum
3. Transitions slot to `readyfor<next_stage>` state

By implementing additional stage methods that follow this pattern, you can insert new processing steps without modifying the core pipeline logic.

### When to Extend vs Use Built-in Features

- **Extend** when you need custom processing logic not covered by the transform function
- **Use built-in features** for standard operations (the transform function handles most data manipulation needs)
- **Consider composition** — wrap a `SwtrRingBuffer` instance rather than subclassing for complex scenarios

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

BSD 3-Clause License

Copyright (c) 2019, Eric Bruno
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
