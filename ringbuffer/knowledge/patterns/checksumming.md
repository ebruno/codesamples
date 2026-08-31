# Checksumming Guide — Per-Slot Integrity Verification

## Overview

Each buffer slot carries its own atomic checksum value, computed after the transform stage applies the user-supplied function. The checksum algorithm is configurable per-slot, allowing different integrity levels for different data segments.

## Key Types

### ChecksumAlgorithm
| Value | Algorithm | Output Size | Use Case |
|-------|-----------|-------------|----------|
| `NONE(0)` | No checksum | 0 bytes | Performance-critical paths where integrity is not required |
| `MD5(1)` | MD5 | 32-bit hash (truncated) | Fast integrity verification, legacy compatibility |
| `SHA256(2)` | SHA-256 | 32-bit hash (truncated) | Balanced performance/integrity (recommended default) |
| `SHA512(3)` | SHA-512 | 32-bit hash (truncated) | Maximum integrity, security-sensitive data |

**Note:** All checksum values are stored as `uint32_t` (32-bit). The full hash is computed but truncated to 32 bits for storage. This provides collision resistance sufficient for pipeline integrity verification while keeping the atomic counter small and cache-friendly.

## C++ Usage

```cpp
#include "ringbuffer.hpp"
using namespace swtr;

auto rb = std::make_unique<SwtrRingBuffer>(4, BufferStatus::readyforread, 4096, nullptr, transform);

// Set checksum algorithm per slot
rb->set_checksum_alg(0, ChecksumAlgorithm::SHA256);
rb->set_checksum_alg(1, ChecksumAlgorithm::SHA256);
rb->set_checksum_alg(2, ChecksumAlgorithm::MD5);
rb->set_checksum_alg(3, ChecksumAlgorithm::NONE);

// After pipeline completes, inspect checksums
for (size_t i = 0; i < 4; ++i) {
    auto alg = rb->get_checksum_alg(i);
    uint32_t val = rb->get_checksum_val(i);
    std::cerr << "Slot " << i << ": alg=" << static_cast<int>(alg)
              << ", checksum=0x" << std::hex << val << std::dec << std::endl;
}

// Test specific algorithm or value
if (rb->test_checksum_alg(0, ChecksumAlgorithm::SHA256)) {
    // Slot 0 uses SHA-256
}
if (rb->test_checksum_val(0, expected_hash)) {
    // Slot 0 checksum matches expected value
}
```

## Java Usage

```java
import swtr.*;

SwtrRingBuffer rb = new SwtrRingBuffer(4, BufferStatus.READYFORREAD, 4096, null, transform);

// Set checksum algorithm per slot
rb.setChecksumAlg(0, ChecksumAlgorithm.SHA256);
rb.setChecksumAlg(1, ChecksumAlgorithm.SHA256);
rb.setChecksumAlg(2, ChecksumAlgorithm.MD5);
rb.setChecksumAlg(3, ChecksumAlgorithm.NONE);

// After pipeline completes, inspect checksums
for (int i = 0; i < 4; ++i) {
    ChecksumAlgorithm alg = rb.getChecksumAlg(i);
    int val = rb.getChecksumVal(i);
    System.err.println("Slot " + i + ": alg=" + alg + ", checksum=0x"
        + Integer.toHexString(val));
}

// Test specific algorithm or value
if (rb.testChecksumAlg(0, ChecksumAlgorithm.SHA256)) { /* ... */ }
if (rb.testChecksumVal(0, expectedHash)) { /* ... */ }
```

## Python Usage

```python
from swtr_ringbuffer import SwtrRingBuffer, ChecksumAlgorithm

rb = SwtrRingBuffer(4, BufferStatus.READYFORREAD, 4096)

# Set checksum algorithm per slot
rb.set_checksum_alg(0, ChecksumAlgorithm.SHA256)
rb.set_checksum_alg(1, ChecksumAlgorithm.SHA256)
rb.set_checksum_alg(2, ChecksumAlgorithm.MD5)
rb.set_checksum_alg(3, ChecksumAlgorithm.NONE)

# After pipeline completes, inspect checksums
for i in range(4):
    alg = rb.get_checksum_alg(i)
    val = rb.get_checksum_val(i)
    print(f"Slot {i}: alg={alg}, checksum=0x{val:x}")

# Test specific algorithm or value
if rb.test_checksum_alg(0, ChecksumAlgorithm.SHA256):  # ...
if rb.test_checksum_val(0, expected_hash):              # ...
```

## Checksum Computation Flow

1. **Read stage** fills slot data → status: `readyfortransform`
2. **Transform stage** applies user function → computes checksum based on `checksum_alg` → status: `readyforwrite`
3. **Write stage** writes data → clears slot buffer → status: `readyforread`

The checksum is computed **after** the transform function runs, so it covers the transformed data (not the raw input). This allows consumers to verify that the transform was applied correctly.

## Default Behavior

If no checksum algorithm is explicitly set, slots default to `NONE` — no checksum computation occurs. This provides zero overhead for use cases that don't need integrity verification.
