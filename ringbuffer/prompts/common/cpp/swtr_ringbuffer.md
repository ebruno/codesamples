# swtr_ringbuffer — C++ Ring Buffer Library with Transform Pipeline

## NAME

**swtr_ringbuffer** — High-performance, thread-safe ring buffer library with configurable transform pipeline and checksum support

## SYNOPSIS

```cpp
#include "ringbuffer.hpp"

// Link against static library:
//   -L<path>/lib -lswtr_ringbuffer

// Link against shared library:
//   -L<path>/lib -lswtr_ringbuffer -Wl,-rpath,<path>/lib
```

## DESCRIPTION

The **swtr_ringbuffer** library provides a lock-free, multi-slot ring buffer with three-stage pipeline processing:

1. **Read** — Reads data from a file descriptor into buffer slots
2. **Transform** — Applies user-defined transformations to slot data (uppercase, XOR, checksum, etc.)
3. **Write** — Writes transformed data to a file descriptor

The library is designed for high-throughput, low-latency data processing with configurable buffer sizes, multiple slots, and comprehensive logging. It supports both static and shared library linking across macOS, Linux, and FreeBSD platforms.

### Key Features

- **Thread-safe**: Atomic status tracking per slot with cache-line alignment to prevent false sharing
- **Multi-slot pipeline**: Configurable number of slots (minimum 1, default varies by platform)
- **Transform pipeline**: User-defined `std::function` transforms applied between read and write stages
- **Checksum support**: MD5, SHA256, or SHA512 checksums per slot
- **Error handling**: Custom error handler callback with slot-level status tracking
- **Logging**: Configurable per-stage logging (read, transform, write) with verbosity levels
- **Cross-platform**: Compiles and links on macOS (clang++), Linux (g++, clang++), FreeBSD (clang++)

## API REFERENCE

### Class: `swtr::SwtrRingBuffer`

```cpp
namespace swtr {

class SwtrRingBuffer : public RingBuffer {
public:
    // Constructor
    SwtrRingBuffer(size_t num_slots = MIN_NUMBER_SLOTS,
                   BufferStatus initial_status = BufferStatus::readyforread,
                   size_t buffer_size = DEFAULT_BUFFER_SIZE,
                   ErrorHandler err_handler = nullptr,
                   TransformFn transform_fn = nullptr);

    ~SwtrRingBuffer() override = default;

    // Thread Control
    void start() override;
    void stop() override;
    void wait() override;

    // Configuration
    void set_read_fd(int fd) override;
    void set_write_fd(int fd) override;

    // Logging
    void set_logging_enabled(bool enabled) override;
    bool get_logging_enabled() const override;
    void set_output_stream(std::ostream& stream) override;
    std::ostream* get_output_stream() const override;
    void set_read_logging_enabled(bool enabled) override;
    bool get_read_logging_enabled() const override;
    void set_read_verbosity(LogLevel level) override;
    LogLevel get_read_verbosity() const override;
    void set_transform_logging_enabled(bool enabled) override;
    bool get_transform_logging_enabled() const override;
    void set_transform_verbosity(LogLevel level) override;
    LogLevel get_transform_verbosity() const override;
    void set_write_logging_enabled(bool enabled) override;
    bool get_write_logging_enabled() const override;
    void set_write_verbosity(LogLevel level) override;
    LogLevel get_write_verbosity() const override;

    // Accessors
    BufferStatus get_status(size_t slot_idx) const override;
    void set_status(size_t slot_idx, BufferStatus status) override;
    bool test_status(size_t slot_idx, BufferStatus status) const override;
    ChecksumAlgorithm get_checksum_alg(size_t slot_idx) const override;
    void set_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) override;
    bool test_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) const override;
    uint32_t get_checksum_val(size_t slot_idx) const override;
    void set_checksum_val(size_t slot_idx, uint32_t val) override;
    bool test_checksum_val(size_t slot_idx, uint32_t val) const override;
    size_t get_max_size(size_t slot_idx) const override;
    void set_max_size(size_t slot_idx, size_t size) override;
    size_t get_data_size(size_t slot_idx) const override;
    void set_data_size(size_t slot_idx, size_t size) override;
    size_t get_transformed_size(size_t slot_idx) const override;
    void set_transformed_size(size_t slot_idx, size_t size) override;

protected:
    void do_log(LogLevel level, const std::string& message) override;
};

} // namespace swtr
```

### Constructor Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `num_slots` | `size_t` | `MIN_NUMBER_SLOTS` (1) | Number of buffer slots in the ring |
| `initial_status` | `BufferStatus` | `readyforread` | Initial status for all slots |
| `buffer_size` | `size_t` | `DEFAULT_BUFFER_SIZE` (4096) | Maximum bytes per slot data buffer |
| `err_handler` | `ErrorHandler` | `nullptr` | Custom error handler callback |
| `transform_fn` | `TransformFn` | `nullptr` | User-defined transform function |

### Type Definitions

```cpp
using ErrorHandler = int (*)(size_t slot_idx, BufferStatus status);
using TransformFn = std::function<void(std::vector<uint8_t>&, size_t&)>;
```

- **ErrorHandler**: Callback invoked on errors. Receives slot index and status. Return 0 to continue, non-zero to stop pipeline.
- **TransformFn**: User-defined transform function. Modifies data in-place and updates size reference.

### Thread Control Methods

| Method | Description |
|--------|-------------|
| `start()` | Starts the three-stage pipeline (read, transform, write threads) |
| `stop()` | Signals all pipeline threads to stop and joins them |
| `wait()` | Blocks until all pipeline threads have completed |

### Configuration Methods

| Method | Description |
|--------|-------------|
| `set_read_fd(int fd)` | Set file descriptor for read stage input |
| `set_write_fd(int fd)` | Set file descriptor for write stage output |

### Logging Methods

| Method | Description |
|--------|-------------|
| `set_logging_enabled(bool)` | Enable/disable all logging |
| `get_logging_enabled() const` | Check if logging is enabled |
| `set_output_stream(std::ostream&)` | Set output stream (default: `std::cerr`) |
| `get_output_stream() const` | Get current output stream |
| `set_read_logging_enabled(bool)` | Enable/disable read stage logging |
| `get_read_logging_enabled() const` | Check read logging status |
| `set_read_verbosity(LogLevel)` | Set read stage verbosity level |
| `get_read_verbosity() const` | Get read stage verbosity |
| `set_transform_logging_enabled(bool)` | Enable/disable transform stage logging |
| `get_transform_logging_enabled() const` | Check transform logging status |
| `set_transform_verbosity(LogLevel)` | Set transform stage verbosity level |
| `get_transform_verbosity() const` | Get transform stage verbosity |
| `set_write_logging_enabled(bool)` | Enable/disable write stage logging |
| `get_write_logging_enabled() const` | Check write logging status |
| `set_write_verbosity(LogLevel)` | Set write stage verbosity level |
| `get_write_verbosity() const` | Get write stage verbosity |

### Accessor Methods

| Method | Description |
|--------|-------------|
| `get_status(size_t)` / `set_status(size_t, BufferStatus)` | Get/set slot status |
| `test_status(size_t, BufferStatus)` | Test if slot matches expected status |
| `get_checksum_alg(size_t)` / `set_checksum_alg(size_t, ChecksumAlgorithm)` | Get/set checksum algorithm for slot |
| `test_checksum_alg(size_t, ChecksumAlgorithm)` | Test if slot uses expected algorithm |
| `get_checksum_val(size_t)` / `set_checksum_val(size_t, uint32_t)` | Get/set checksum value for slot |
| `test_checksum_val(size_t, uint32_t)` | Test if slot checksum matches expected value |
| `get_max_size(size_t)` / `set_max_size(size_t, size_t)` | Get/set maximum buffer size for slot |
| `get_data_size(size_t)` / `set_data_size(size_t, size_t)` | Get/set current data bytes in slot |
| `get_transformed_size(size_t)` / `set_transformed_size(size_t, size_t)` | Get/set current transformed bytes in slot |

## ENUMERATIONS

### BufferStatus

Slot state machine states (14 values):

```cpp
enum class BufferStatus : int {
    readyforread = 0,           // Slot ready for read stage
    readyfortransform = 1,      // Slot ready for transform stage
    readyforwrite = 2,          // Slot ready for write stage
    processing_read = 3,        // Read stage active
    processing_transform = 4,   // Transform stage active
    processing_write = 5,       // Write stage active
    empty = 6,                  // Slot is empty
    full = 7,                   // Slot is full
    LAST_BUFFER_TO_TRANSFORM = 8,   // Last buffer before transform wrap
    LAST_BUFFER_TO_WRITE = 9,     // Last buffer before write wrap
    pending_read = 10,          // Read queued
    pending_transform = 11,     // Transform queued
    pending_write = 12,         // Write queued
    STATUS_ERROR = 13           // Error state
};
```

### ChecksumAlgorithm

Available checksum algorithms:

```cpp
enum class ChecksumAlgorithm : int {
    NONE = 0,     // No checksum
    MD5 = 1,      // MD5 hash (128-bit)
    SHA256 = 2,   // SHA-256 hash (256-bit)
    SHA512 = 3    // SHA-512 hash (512-bit)
};
```

### LogLevel

Logging verbosity levels:

```cpp
enum class LogLevel : int {
    Trace = 0,    // Most verbose
    Debug = 1,
    Info = 2,     // Default level
    Warning = 3,
    Error = 4,
    Critical = 5  // Least verbose
};
```

## TRANSFORMS

Transforms are user-defined functions applied to slot data between read and write stages. The transform receives a reference to the data vector and a size reference, allowing in-place modification.

### Example Transforms

**Uppercase Transform:**
```cpp
void uppercase_transform(std::vector<uint8_t>& data, size_t& size) {
    for (size_t i = 0; i < size; ++i) {
        if (data[i] >= 'a' && data[i] <= 'z') {
            data[i] -= 32; // Convert to uppercase
        }
    }
}
```

**XOR Transform (bit inversion):**
```cpp
void xor_transform(std::vector<uint8_t>& data, size_t& size) {
    for (size_t i = 0; i < size; ++i) {
        data[i] ^= 0xFF; // Flip all bits
    }
}
```

**Identity Transform (no-op):**
```cpp
void identity_transform(std::vector<uint8_t>& data, size_t& size) {
    // No modification — passes data through unchanged
}
```

## ERROR HANDLING

### Error Handler Callback

The error handler is invoked when a pipeline stage encounters an unrecoverable error:

```cpp
using ErrorHandler = int (*)(size_t slot_idx, BufferStatus status);
```

- **Return 0**: Continue pipeline processing
- **Return non-zero**: Stop pipeline and signal error

### Error Propagation

Errors are tracked per-slot via `BufferStatus::STATUS_ERROR`. The error handler can inspect the slot status and decide whether to:
- Retry the operation
- Skip the slot
- Stop the entire pipeline

### Logging Errors

Errors are logged at `LogLevel::Error` or `LogLevel::Critical` depending on severity. Enable logging to capture error details:

```cpp
ringbuffer.set_logging_enabled(true);
ringbuffer.set_read_verbosity(LogLevel::Debug);
```

## COMPILATION PER OS

### macOS (clang++)

**Compiler:** `clang++` (Apple Clang or Homebrew)
**C++ Standard:** C++20 (`-std=c++20`)
**LTO:** `-flto=thin` (Apple Clang) or `-flto` (Homebrew g++)

```bash
# Compile with clang++ (default on macOS)
clang++ -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic \
        -flto=thin -fvisibility=hidden -ffunction-sections -fdata-sections \
        -I. -c swtr_ringbuffer.cpp

# Universal binary (arm64 + x86_64) on Apple Silicon
clang++ -std=c++20 -O3 -fPIC -arch arm64 -c swtr_ringbuffer.cpp
clang++ -std=c++20 -O3 -fPIC -arch x86_64 -c swtr_ringbuffer.cpp
```

**Notes:**
- Apple Clang uses `libc++` by default (C++20 `<format>` available)
- Homebrew g++ may require `--stdlib=libc++` on modern macOS (Apple deprecated `libstdc++`)
- Universal binaries supported via `lipo -create`

### Linux (g++ or clang++)

**Compiler:** `g++` (GCC) or `clang++` (LLVM)
**C++ Standard:** C++20 (`-std=c++20`)
**LTO:** `-flto` (g++) or disabled for clang++ on Linux

```bash
# Compile with g++ (GCC)
g++ -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic \
    -flto -fvisibility=hidden -ffunction-sections -fdata-sections \
    -I. -c swtr_ringbuffer.cpp

# Compile with clang++ (LLVM) — LTO disabled on Linux
clang++ -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic \
    -fvisibility=hidden -ffunction-sections -fdata-sections \
    -I. -c swtr_ringbuffer.cpp
```

**Notes:**
- g++ on Linux uses `-flto` (native LTO)
- clang++ on Linux does not support direct LTO linking — LTO is disabled
- Use `-fuse-ld=lld` with clang++ for faster linking

### FreeBSD (clang++)

**Compiler:** `clang++` (FreeBSD Clang)
**C++ Standard:** C++20 (`-std=c++20`)
**LTO:** `-flto=thin`

```bash
# Compile with clang++ on FreeBSD
clang++ -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic \
        -flto=thin -fvisibility=hidden -ffunction-sections -fdata-sections \
        -I. -pthread -c swtr_ringbuffer.cpp
```

**Notes:**
- FreeBSD does not provide `std::jthread` (C++20 thread stop token)
- Uses `std::thread` + atomic stop flag as fallback (conditional compilation via `#ifdef __FreeBSD__`)
- Requires `-pthread` flag

## LINKING PER OS

### Static Library Linking

**All platforms:**
```bash
# Link against static library
g++ main.cpp -L<path>/lib -lswtr_ringbuffer

# Or specify full path
g++ main.cpp <path>/lib/libswtr_ringbuffer-1.0.0-1.a
```

**Static library naming:**
| Platform | File Pattern | Example |
|----------|--------------|---------|
| macOS | `libswtr_ringbuffer-<VERSION>.a` | `libswtr_ringbuffer-1.0.0-1.a` |
| Linux | `libswtr_ringbuffer-<VERSION>.a` | `libswtr_ringbuffer-1.0.0-1.a` |
| FreeBSD | `libswtr_ringbuffer-<VERSION>.a` | `libswtr_ringbuffer-1.0.0-1.a` |

**Symlink:** `libswtr_ringbuffer.a` → `libswtr_ringbuffer-<VERSION>.a`

### Shared Library Linking

**macOS (clang++):**
```bash
# Compile and link shared library
clang++ -dynamiclib -install_name @rpath/libswtr_ringbuffer.dylib \
        -dead_strip -o libswtr_ringbuffer-1.0.0-1.dylib \
        Accessors_ChecksumAlg.o Lifecycle.o ...

# Link against shared library at runtime
g++ main.cpp -L<path>/lib -lswtr_ringbuffer \
    -Wl,-rpath,@executable_path/../lib

# Or set DYLD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=<path>/lib:$DYLD_LIBRARY_PATH
```

**Shared library naming:**
| Platform | File Pattern | Example | Install Name / SONAME |
|----------|--------------|---------|----------------------|
| macOS | `libswtr_ringbuffer-<VERSION>.dylib` | `libswtr_ringbuffer-1.0.0-1.dylib` | `@rpath/libswtr_ringbuffer.dylib` |
| Linux | `libswtr_ringbuffer-<VERSION>.so` | `libswtr_ringbuffer-1.0.0-1.so` | `libswtr_ringbuffer.so` |
| FreeBSD | `libswtr_ringbuffer-<VERSION>.so` | `libswtr_ringbuffer-1.0.0-1.so` | `libswtr_ringbuffer.so` |

**Symlink:** `libswtr_ringbuffer.dylib` (macOS) or `libswtr_ringbuffer.so` (Linux/FreeBSD) → versioned file

**Linker flags per platform:**
| Platform | Static Linker | Shared Linker Flags |
|----------|---------------|---------------------|
| macOS | `libtool -static` | `-dynamiclib -install_name @rpath/libswtr_ringbuffer.dylib -dead_strip` |
| Linux (g++) | `ar rcs` | `-shared -Wl,--gc-sections -Wl,-soname,libswtr_ringbuffer.so` |
| Linux (clang++) | `ar rcs` | `-shared -Wl,--gc-sections -fuse-ld=lld -Wl,-soname,libswtr_ringbuffer.so` |
| FreeBSD | `ar rcs` | `-shared -Wl,--gc-sections -Wl,-rpath,<absolute_path>/lib -Wl,-soname,libswtr_ringbuffer.so` |

**Runtime linking:**
```bash
# macOS — use install_name_tool to fix @rpath if needed
install_name_tool -change @rpath/libswtr_ringbuffer.dylib \
    /absolute/path/to/libswtr_ringbuffer.dylib <executable>

# Linux — use rpath or LD_LIBRARY_PATH
g++ main.cpp -L<path>/lib -lswtr_ringbuffer \
    -Wl,-rpath,<path>/lib

# FreeBSD — RPATH set at build time (absolute path in library)
```

## EXAMPLES

### Basic Usage

```cpp
#include "ringbuffer.hpp"
#include <iostream>
#include <fstream>

using namespace swtr;

int main() {
    // Create ring buffer with 4 slots, 4096 bytes each
    SwtrRingBuffer rb(4, BufferStatus::readyforread, 4096);

    // Enable logging
    rb.set_logging_enabled(true);
    rb.set_read_verbosity(LogLevel::Info);

    // Set file descriptors (example: stdin/stdout)
    rb.set_read_fd(STDIN_FILENO);
    rb.set_write_fd(STDOUT_FILENO);

    // Start pipeline
    rb.start();

    // Wait for completion (blocks until stop() is called)
    rb.wait();

    return 0;
}
```

### With Transform

```cpp
#include "ringbuffer.hpp"
#include <vector>
#include <algorithm>

using namespace swtr;

// Uppercase transform
void to_upper(std::vector<uint8_t>& data, size_t& size) {
    std::transform(data.begin(), data.begin() + size, data.begin(),
                   [](uint8_t c) { return std::toupper(c); });
}

int main() {
    SwtrRingBuffer rb(4, BufferStatus::readyforread, 4096,
                      nullptr,        // No custom error handler
                      to_upper);      // Uppercase transform

    rb.set_logging_enabled(true);
    rb.start();
    rb.wait();

    return 0;
}
```

### With Checksum

```cpp
#include "ringbuffer.hpp"

using namespace swtr;

int main() {
    SwtrRingBuffer rb(4);

    // Set SHA256 checksum for slot 0
    rb.set_checksum_alg(0, ChecksumAlgorithm::SHA256);

    // Verify checksum algorithm
    if (rb.test_checksum_alg(0, ChecksumAlgorithm::SHA256)) {
        std::cout << "Slot 0 uses SHA256 checksum\n";
    }

    rb.start();
    rb.wait();

    return 0;
}
```

## SEE ALSO

- `ringbuffer.hpp` — Header file with class definitions
- `status.hpp` — Enumerations (BufferStatus, ChecksumAlgorithm, LogLevel)
- `swtr_ringbuffer_impl.hpp` — Implementation details
- `Makefile` — Build configuration per platform
- `version.mk` — Version information

## VERSION

**Current version:** 1.0.0-1 (MAJOR.MINOR.SUBVERSION-BUILD_ID)

## AUTHOR

swtr_ringbuffer project — High-performance ring buffer with transform pipeline
