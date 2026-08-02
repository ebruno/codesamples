# Functional Requirements - Ringbuffer (Fedora 44, C++)

- Code should be C++20 compliant.
- Code should use `std::jthread`, cooperative cancellation, and advanced synchronization primitives.
- Code should be buildable using both clang and gcc tool chains.
- A ring buffer (also called a circular buffer) is a fixed-size, first-in-first-out (FIFO) data structure that connects its memory end-to-end in a loop. It uses a read pointer and a write pointer that wrap around to the start of the array when they reach the end.
- Fixed Array: A pre-allocated block of memory that never changes size.
- The `BufferSlot` structure must include:
    - `buffer_idx` (index of the slot)
    - `status` (BufferStatus)
    - `max_data_buffer_size`
    - `data_buffer_size`
    - `transformed_data_buffer_size`
    - `checksum_alg` (ChecksumAlgorithm)
    - `checksum_val` (uint32_t)
    - `data` (the internal data buffer)
  
- Total of 14 buffer status values should be defined using an `enum class`.
- The status values `readyforread`, `readyfortransform`, and `readyforwrite` should be the first 3 values of the `enum class`.
- `STATUS_ERROR` must be the final value of the `enum class` (index 13).
- **Special Terminal Statuses**: 
    - `LAST_BUFFER_TO_TRANSFORM`: Indicates the final buffer to be processed by the transformer.
    - `LAST_BUFFER_TO_WRITE`: Indicates the final buffer to be processed by the writer.
- **Checksum Algorithms**: Common checksum algorithms should be defined using an `enum class`, including at minimum:
    - `MD5`
    - `SHA256`
    - `SHA512`
    - `NONE` (for cases where no checksum is required)

## Header Requirements
- **Self-Sufficiency**: The primary header file (`ringbuffer.hpp`) must be self-sufficient. It must include every standard library header and internal dependency it directly uses. Any translation unit that includes `ringbuffer.hpp` should be able to compile without requiring additional standard includes for the `swtr` namespace types.
- **Primary Header Inclusion**: Every source file (`.cpp`) within the project must include the primary class definition header (`ringbuffer.hpp`) to ensure type consistency and that the implementation remains in sync with the interface.
- **Logging Stream Storage**: To allow for flexible runtime reconfiguration and avoid initialization order issues, the output stream must be stored as a pointer (`std::ostream*`), not a reference. 
    - The setter method for the output stream must accept a reference (`std::ostream&`) for caller convenience but store the address of that stream (`&stream`) in the pointer member.
    - The default output stream must be initialized to `std::cerr`.
- **Stop Token Header**: The `<stop_token>` header must be included in the concrete implementation header (`swtr_ringbuffer_impl.hpp`). This is required because:
    - The header declares thread function signatures that use `std::stop_token` as a parameter type.
    - The `.cpp` files use `std::stop_callback`, which is also declared in `<stop_token>`.
    - While `<thread>` provides `std::jthread` and `std::stop_token` in some implementations, `std::stop_callback` is only guaranteed by `<stop_token>`. Relying on transitive inclusion from `<thread>` is non-portable between Clang and GCC.

## Performance & Binary Optimization
- **Dead Code Elimination**: The library must be compatible with dead code elimination (e.g., using `-ffunction-sections` and `-fdata-sections`) to ensure the "small binary" goal is verifiable during testing.
- **Memory Alignment**: Buffer slots and index counters should be aligned to cache line boundaries (e.g., using `alignas(64)`) to prevent false sharing between threads.
- **Naming Convention**: All private member variables MUST follow the trailing underscore naming convention (e.g., `member_variable_`).
- **Slot Storage**: The ring buffer must store slots using `std::vector<std::unique_ptr<BufferSlot>>`.
- **Atomic Operations**: 
    - All members of `BufferSlot` that are `std::atomic` MUST be accessed using `.load()` and `.store()` methods rather than direct assignment or implicit conversion, especially when passed to functions or used in `std::format` strings, as `std::format` does not support `std::atomic` types directly.

## Source Organization & Deterministic Naming
To ensure build consistency and prevent git collisions, the following strict file mapping MUST be followed. No other source files shall be created unless explicitly requested.

### File Mapping Table
| Requirement / Logic Group | Exact Filename |
| :--- | :--- |
| Primary Abstract Interface | `ringbuffer.hpp` |
| Status and Checksum Enums | `status.hpp` |
| Concrete Implementation Class | `swtr_ringbuffer_impl.hpp` |
| Concrete Implementation Logging | `LoggingOps_1.cpp` (and numbered files if necessary) |
| Constructor and Destructor | `Lifecycle.cpp` |
| Read Pipeline Logic | `ReadOps.cpp` |
| Transform Pipeline Logic | `TransformOps.cpp` |
| Write Pipeline Logic | `WriteOps.cpp` |
| Thread Management (`start`, `stop`, `wait`) | `Threading.cpp` |
| Error Handling (`handle_error`) | `ErrorOps.cpp` |

- **Required includes in `swtr_ringbuffer_impl.hpp`**: `<functional>`, `<mutex>`, `<stop_token>`, `<string>`, `<thread>`, `<vector>`, `"ringbuffer.hpp"`, `"status.hpp"`.
- **Symbol Visibility**: To support shared library linking while using `-fvisibility=hidden`, the `SwtrRingBuffer` class must be explicitly marked with `__attribute__((visibility("default")))`.

### Accessor File Pattern
Accessors must be split into separate files based on the data they process to minimize git collisions. The filename MUST follow the pattern `Accessors_[GroupName].cpp`.
- **Status Accessors**: `Accessors_Status.cpp`
- **Checksum Algorithm Accessors**: `Accessors_ChecksumAlg.cpp`
- **Checksum Value Accessors**: `Accessors_ChecksumVal.cpp`
- **Max Size Accessors**: `Accessors_Size_Max.cpp`
- **Data Size Accessors**: `Accessors_Size_Data.cpp`
- **Transformed Size Accessors**: `Accessors_Size_Transformed.cpp`

### Naming & Distribution Rules
- **Casing**: Use `snake_case` for primary headers and the implementation class files. Use `PascalCase` for all operation and lifecycle `.cpp` files.
- **Function Distribution**: To prevent git collisions, limit each `.cpp` file to a maximum of 3 functions. If a logic group exceeds this, it must be further subdivided into numbered files (e.g., `ReadOps_1.cpp`, `ReadOps_2.cpp`).
- **Documentation**: A `README.md` file must be provided in the source directory describing the library and how to build it.

### Include Discipline
To maintain a clean and predictable compilation environment, all source files must follow this include order:
1. **Primary Project Header**: The first non-comment include must be the primary class header (`ringbuffer.hpp`).
2. **Standard Library Headers**: All required `<header>` files, sorted alphabetically (e.g., `<atomic>`, `<iostream>`, `<vector>`).
3. **Third-Party Libraries**: Any external dependencies.
4. **Local Project Headers**: Other `.hpp` files from the project (e.g., `status.hpp`).

**Rules for Includes**:
- **No redundant includes**: Do not include headers in a `.cpp` file that are already provided by the primary project header unless the `.cpp` file uses a type from that header that is not exposed in the primary header.
- **Avoid pollution**: Headers should only include what is strictly necessary for the declarations within that header. Implementation-specific includes (like `<unistd.h>` for POSIX calls) must be placed in `.cpp` files, not headers, to avoid leaking platform-specific macros into the public API.

## Constructor Requirements
- **Member Initializer List**: All member variables must be initialized in the constructor's member initializer list or via in-class default initializers. The constructor body must only contain validation logic and slot initialization.
- **Automatic Start**: The constructor MUST NOT start the read, transform, or write threads automatically.
- The constructor must support the following parameters:
    - Number of slots (default: MIN_NUMBER_SLOTS).
    - Initial status of the ring buffer (default: readyforread).
    - Buffer size per slot (default: DEFAULT_BUFFER_SIZE = 4096).
    - Error Handler function (`ErrorHandler err_handler = nullptr`).
    - Transform function (`std::function<void(std::vector<uint8_t>&, size_t&)> transform_fn = nullptr`).
- **Initialization**: The `max data buffer size` for each slot must be initialized with the "buffer size per slot" value provided to the constructor.
   - The constructor should fail if number slots is not equal to or  greater than 1 and the buffer size is not equal to or greater than 1, and exeception should fail reporting why it failed.
   - Create a macro or const MIN\_NUMBER\_SLOTS and set to 1 use this for the test in constructor.
   - Create a macro or const MIN\_BUFFER\_SIZE and set to 1 use this for the test in constructor.
- Default behavior for `readyforread`.

## Public Member Functions
- **Thread Control**:
    - Provide a `start` function to initialize and launch the read, transform, and write threads.
    - Provide a `stop` function to trigger cooperative cancellation and join all threads.
    - Provide a `wait` function that blocks the caller until all three pipeline threads have naturally terminated (e.g., after an EOF sequence).
- **Core Operations** (Must be implemented as class member functions):
    - **Configuration**:
        - Provide `set_read_fd(int fd)` and `set_write_fd(int fd)` to configure the POSIX file descriptors used by the pipeline.
    - **Read Function**:
        - Should use POSIX file descriptors for reading.
        - After filling the buffer, it will mark the slot as `readyfortransform`.
        - It must set the `data buffer size` to the exact number of bytes read.
        - In the event of EOF or a read error, the `data buffer size` should be reset to 0.
    - **Transform Function**:
        - The class should accept a `std::function` to define the transformation operation.
        - The transform function will apply this operation to the data and mark the slot as `readyforwrite`.
        - Because the buffer sizes are stored as `std::atomic`, the transform function (which takes a `size_t&`) must be called by loading the atomic value into a local temporary, passing that temporary to the function, and then storing the result back into the atomic member.
        - **Optional Transform**: If no transform function is specified, the transform method should set the `transformed data buffer size` equal to the `data buffer size` using `.store()` and `.load()` to avoid illegal atomic assignments, report this in a log message, and mark the buffer as `readyforwrite` (or `LAST_BUFFER_TO_WRITE` if applicable) to allow it to proceed to the writer.
    - **Write Function**:
        - Should use POSIX file descriptors for writing.
        - It will write the data to the descriptor, clear the buffer, and mark the slot as `readyforread`.
        - It must set the `data buffer size` to 0 after writing.
        - The log message for a successful write must report both the number of bytes written and the slot's original `data buffer size`.
        - It must perform a flush (e.g., `fsync`) on the file descriptor after writing the final buffer (`LAST_BUFFER_TO_WRITE`).
- **Data Accessors**:
    - **State & Checksum**: Generate `get`, `set`, and `test` functions for:
        - `buffer status`
        - `checksum algorithm`
        - `checksum value`
    - **Buffer Sizes**: Generate `get` and `set` functions for:
        - `max data buffer size`
        - `data buffer size`
        - `transformed data buffer size`

## Logging and Diagnostics
- **Logging Control**:
    - Provide `set_logging_enabled(bool enabled)` and `get_logging_enabled()` functions.
    - Provide `set_output_stream(std::ostream& stream)` which stores the address of the stream in a pointer.
    - Provide `get_output_stream()` which returns the `std::ostream*` pointer.
    - The default stream should be initialized to `std::cerr`.
    - **Architecture**: Use a Non-Virtual Public Interface (NVI) pattern:
        - Public non-virtual `log_message` variadic template method for external use. This method should use `std::format` to construct a log message string.
        - Protected pure virtual implementation method `do_log(LogLevel level, const std::string& message)` for derived classes.
        - Use the `override` keyword in derived classes.
    - **Thread Safety**: Log messages must be printed atomically. The library must ensure that messages from different threads are not interleaved in the output stream (e.g., using a mutex).
    - **Log Levels**: Define an enumeration for the following levels: `Trace`, `Debug`, `Info`, `Warning`, `Error`, `Critical`.
	    - The implementation of `do_log` must use the string representation of the log level (e.g., `[INFO]`, `[DEBUG]`) rather than its numeric enumeration value.
- **Independent Stage Logging**:
    - Provide the following functions for each stage (**Read**, **Transform**, and **Write**):
        - `set_[stage]_logging_enabled(bool enabled)`
        - `get_[stage]_logging_enabled()`
        - `set_[stage]_verbosity(LogLevel level)`
        - `get_[stage]_verbosity()`
    - Each stage must check its specific flag and verbosity level before calling the log implementation.

## Execution Model & Threading
- The read, transform, and write pipelines must be implemented as `read_loop`, `transform_loop`, and `write_loop` respectively. Each must accept a `std::stop_token` as its first parameter.
- These functions will run in separate threads using `std::jthread`, cooperative cancellation, and synchronization using `std::mutex sync_mutex_` and `std::condition_variable_any cv_`.
- **Thread Control**:
    - All threads must check and honor the `std::stop_token` from `std::jthread`.
    - Use `std::stop_callback` to ensure immediate resource release and improve responsiveness during cancellation.
- **End-of-Stream (EOF) Graceful Shutdown Sequence**:
    - **Reader**: When the reader detects EOF (end of file) on the read file handle, it must set the current buffer status to `LAST_BUFFER_TO_TRANSFORM` and then the reader thread should terminate.
    - **Transformer**: When the transformer encounters a buffer with status `LAST_BUFFER_TO_TRANSFORM`, it must perform the transformation, set the status to `LAST_BUFFER_TO_WRITE`, and then the transformer thread should terminate.
    - **Writer**: When the writer encounters a buffer with status `LAST_BUFFER_TO_WRITE`, it must write the buffer to the destination and then the writer thread should terminate.

## Error Handling and Recovery
- If a slot enters a `STATUS_ERROR` state, the system should call an error handling routine.
- **Error Handler Signature**: The error handling routine must follow the signature: `int (*ErrorHandler)(size_t slot_idx, BufferStatus status)`.
- **Implementation Note**: Error handlers that do not use `slot_idx` or `status` should explicitly cast them to `(void)` to avoid `-Wunused-parameter` warnings.
- If the error handling routine returns a non-zero value, the entire pipeline should stop (triggering cooperative cancellation of all threads).

## Licensing
- All code is covered under a BSD 3-Clause License.
- A `LICENSE` file must be created in `src/fedora/cpp` with the following content:

```text
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
```
<EOF>