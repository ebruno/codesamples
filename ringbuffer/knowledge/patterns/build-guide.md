# Build Guide — Using the Ringbuffer Library

> Auto-generated from project test Makefiles and README.md.
> Version: 1.0.0-build-1

## C++

### Minimal Example (macOS)

Create a file `main.cpp`:

```cpp
#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"
using namespace swtr;

int main() {
    // Transform: convert input to uppercase
    auto transform = [](std::vector<uint8_t>& data, size_t& size) {
        for (size_t i = 0; i < size; ++i)
            if (data[i] >= 'a' && data[i] <= 'z') data[i] -= 32;
    };

    // Create a ring buffer with 4 slots, 4096 bytes each
    auto rb = std::make_unique<SwtrRingBuffer>(4, BufferStatus::readyforread, 4096, nullptr, transform);

    // Configure I/O: read from stdin, write to stdout
    rb->set_read_fd(STDIN_FILENO);
    rb->set_write_fd(STDOUT_FILENO);

    // Enable logging for diagnostics
    rb->set_logging_enabled(true);
    rb->set_output_stream(std::cerr);

    // Run the pipeline: reads until EOF, transforms each slot, writes output
    rb->start();
    rb->wait();   // blocks until all data flows through read $\rightarrow$ transform $\rightarrow$ write
    rb->stop();
}
```

Build with:
```bash
clang++ -std=c++20 main.cpp -I../src/macos/cpp -L../src/macos/cpp/lib -lswtr_ringbuffer -o main
```

### Static Linking (macOS)

Link directly against the static library — no runtime path needed:

```bash
$(CXX) $(CXXFLAGS) src/test001.cpp $(LIB_DIR)/libswtr_ringbuffer.a -o $(BIN_DIR)/test001_staticlib
```

### Dynamic Linking (macOS)

Link against the shared library with @rpath for runtime resolution:

```bash
$(CXX) $(CXXFLAGS) src/test001.cpp -L$(LIB_DIR) -lswtr_ringbuffer -o $(BIN_DIR)/test001_dynamiclib
```

### Platform-Specific Notes

| Platform | Compiler | Shared Lib | Linker Flag |
|----------|----------|------------|-------------|
| macOS | clang++ | `.dylib` | `-Wl,-rpath,@loader_path/../lib` |
| Linux (GNU) | g++ | `.so` | `-Wl,-rpath,$ORIGIN/../lib` |
| FreeBSD 14 | clang++ | static only | no rpath — use static library |

## Java

### Maven Project Setup

Add to your `pom.xml`:

```xml
<dependency>
    <groupId>swtr</groupId>
    <artifactId>ringbuffer</artifactId>
    <version>1.0.0</version>
</dependency>
```

Build: `mvn compile package`

JAR output: `target/ringbuffer-1.0.0.jar`

## Python

### Pure Python Mode

No compilation needed — pure Python implementation:

```python
from swtr_ringbuffer_pure import SwtrRingBuffer, BufferStatus

rb = SwtrRingBuffer(num_slots=4, buffer_size=4096)
rb.set_read_fd(0)
rb.set_write_fd(1)
rb.start()
rb.wait()
```

### Concurrent Mode (ctypes)

Requires the C++ shared library (`libswtr_ringbuffer.so` / `.dylib`) to be built first.
The library must be in `src/<os>/cpp/lib/` or on `LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH`.

```python
from swtr_ringbuffer import SwtrRingBuffer, BufferStatus
# Same API, backed by C++ library via ctypes
```
