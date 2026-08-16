# Functional Requirements - Ringbuffer (Common C++)

**Cross-Platform Consistency Requirement:** This library is deployed across multiple Linux distributions. To ensure maintainability and binary symmetry, the source code MUST be byte-identical across all Linux distributions (debian, fedora, ubuntu, raspios). Cross-family differences between Linux and macOS/FreeBSD are limited to minimal platform-specific wrappers (`#ifdef` guards, OS-detection macros). Do not adapt the coding style, naming, or architecture to the specific distribution; follow these specifications strictly.

**Cross-Platform Generation Mandate:** When generating source code for any platform, the agent MUST produce byte-identical `.cpp` and `.hpp` files across all Linux distributions (Ubuntu, Debian, Fedora). The only platform-specific artifacts are:
- `containers/Dockerfile` (base image and package list)
- `Makefile` (container image name, working directory path, host distro check)
- `tests/containers/<os>/Dockerfile` (test container base image)
- `tests/Makefile` (container image name, Dockerfile path, report title)

All source code files (`*.cpp`, `*.hpp`) MUST be generated from the same canonical template. Generate each platform's source independently from this spec — do not copy files between platforms.

**Cross-Platform Verification:** After generating all files independently, compare output against any other platform's source in `src/` if available. If a reference platform exists, verify byte-identical output and log: `[timestamp] Cross-platform comparison passed — <target> matches <reference>.` If no reference platform exists, log: `[timestamp] Cross-platform comparison skipped — no other platform source available.`

**Cross-Platform Build/Test Synchronization Mandate:** The build and test infrastructure MUST be byte-identical across all Linux distributions, with only the following allowed differences:
- Container image names (`ringbuffer_<os>_build`, `ringbuffer_<os>_test`)
- Dockerfile paths (`containers/<os>/Dockerfile` or `tests/containers/<os>/Dockerfile`)
- Host distro detection strings (`ubuntu`, `debian`, etc.)
- Report titles (OS name in regression report header)

All Makefile targets, test matrix definitions, verification steps, JUnit XML generation, and report formats MUST be identical. When modifying one platform's build or test infrastructure, apply the same changes to all platforms to maintain synchronization.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/cpp/functional.md`) conflict with common specs (`prompts/common/cpp/functional.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

> **Quick Reference:** For platform-specific toolchain details (otool, lipo), binary format comparison tables (ELF vs Mach-O), and shared library linking conventions, see `prompts/common/cpp/session_hints.md`.

- Code **MUST** be C++20 compliant.
- Code **MUST** use `std::jthread`, cooperative cancellation, and advanced synchronization primitives.
- Code **MUST** be buildable using both clang and gcc tool chains.
- A ring buffer (also called a circular buffer) is a fixed-size, first-in-first-out (FIFO) data structure that connects its memory end-to-end in a loop. It uses a read pointer and a write pointer that wrap around to the start of the array when they reach the end.
- Fixed Array: A pre-allocated block of memory that never changes size.
- The `BufferSlot` structure MUST be defined exactly as:
  ```cpp
  struct BufferSlot {
      size_t buffer_idx;                                    // non-atomic: slot index
      std::atomic<BufferStatus> status;                     // atomic: current buffer state
      size_t max_data_buffer_size;                          // non-atomic: maximum capacity
      std::atomic<size_t> data_buffer_size;                 // atomic: current bytes in data buffer
      std::atomic<size_t> transformed_data_buffer_size;     // atomic: current bytes in transformed buffer
      std::atomic<ChecksumAlgorithm> checksum_alg;          // atomic: algorithm used for checksum
      std::atomic<uint32_t> checksum_val;                   // atomic: computed checksum value
      std::vector<uint8_t> data;                            // non-atomic: internal data buffer (raw bytes)
  };
  ```
  **Atomic vs Non-atomic distinction**:
    - `buffer_idx`, `max_data_buffer_size`, and `data` are **non-atomic** — they are set once during slot construction and never modified afterward.
    - `status`, `data_buffer_size`, `transformed_data_buffer_size`, `checksum_alg`, and `checksum_val` are **atomic** — they are modified by pipeline threads and must be accessed via `.load()` / `.store()`.
  
  **Negative Constraint**: Do NOT make any member atomic unless the `BufferSlot` struct definition explicitly wraps it in `std::atomic<T>`. The comments `// non-atomic` are binding, not advisory. Every atomic member MUST use `.load()` and `.store()` for access; every non-atomic member uses direct read/write.
  
- **Exact Enum Definitions**:
    - `BufferStatus` MUST be defined exactly as (with explicit `int` backing type — signed, not unsigned — for ABI stability):
      ```cpp
      enum class BufferStatus : int {
          readyforread = 0,
          readyfortransform = 1,
          readyforwrite = 2,
          processing_read = 3,
          processing_transform = 4,
          processing_write = 5,
          empty = 6,
          full = 7,
          LAST_BUFFER_TO_TRANSFORM = 8,
          LAST_BUFFER_TO_WRITE = 9,
          pending_read = 10,
          pending_transform = 11,
          pending_write = 12,
          STATUS_ERROR = 13
      };
      ```
    - `ChecksumAlgorithm` MUST be defined exactly as (with explicit `int` backing type — signed, not unsigned — for ABI stability):
      ```cpp
      enum class ChecksumAlgorithm : int {
          NONE = 0,
          MD5 = 1,
          SHA256 = 2,
          SHA512 = 3
      };
      ```
    - `LogLevel` MUST be defined exactly as (with explicit `int` backing type — signed, not unsigned — for ABI stability):
      ```cpp
      enum class LogLevel : int {
          Trace = 0,
          Debug = 1,
          Info = 2,
          Warning = 3,
          Error = 4,
          Critical = 5
      };
      ```

## Mandatory Type Definitions
- `ErrorHandler` MUST be defined as: `using ErrorHandler = int (*)(size_t slot_idx, BufferStatus status);`
- `TransformFn` MUST be defined as: `using TransformFn = std::function<void(std::vector<uint8_t>&, size_t&)>;`
- `BufferSlot` members `buffer_idx`, `max_data_buffer_size`, and `data` are **non-atomic**. Members `status`, `data_buffer_size`, `transformed_data_buffer_size`, `checksum_alg`, and `checksum_val` are **atomic**.

## Status Header (`status.hpp`)
The file `status.hpp` MUST contain exactly the three enum definitions (in this order):
```cpp
#pragma once
#include <cstdint>

// BufferStatus enum (14 values, explicit integer types for ABI stability)
enum class BufferStatus : int {
    readyforread = 0,
    readyfortransform = 1,
    readyforwrite = 2,
    processing_read = 3,
    processing_transform = 4,
    processing_write = 5,
    empty = 6,
    full = 7,
    LAST_BUFFER_TO_TRANSFORM = 8,
    LAST_BUFFER_TO_WRITE = 9,
    pending_read = 10,
    pending_transform = 11,
    pending_write = 12,
    STATUS_ERROR = 13
};

// ChecksumAlgorithm enum (4 values)
enum class ChecksumAlgorithm : int {
    NONE = 0,
    MD5 = 1,
    SHA256 = 2,
    SHA512 = 3
};

// LogLevel enum (6 values)
enum class LogLevel : int {
    Trace = 0,
    Debug = 1,
    Info = 2,
    Warning = 3,
    Error = 4,
    Critical = 5
};
```

**Enum Value Completeness Rule**: Every enum value in every enum MUST have an explicit `= N` assignment. No implicit incrementing is allowed anywhere.

**Global Namespace Rule for Enums**: Enums in `status.hpp` are at **global scope** (no namespace wrapper). They are NOT inside `namespace swtr`. Only the abstract class, type aliases, and implementation classes belong in `namespace swtr`.

- `status.hpp` MUST be self-sufficient with only `<cstdint>` as a standard include.
- `status.hpp` MUST use `#pragma once` for include guards.

**Global Include Guard Rule**: All `.hpp` files in the project MUST use `#pragma once` — never `#ifndef`/`#define`/`#endif` guards. This applies to every header file without exception.

## Abstract Base Class
> **Design Note — Granular Slot Accessors**: The `RingBuffer` abstract base class exposes ~20 getter/setter methods for individual slot state fields (e.g., `get_data_buffer_size()`, `set_transformed_data_buffer_size()`, `get_slot_status()`). These are **intentional library API design choices**, not a leaky abstraction. As a reusable library, Ringbuffer must provide maximum flexibility to consumers for debugging, monitoring, performance profiling, and testing. Library users should be able to inspect and manipulate slot state at any granularity level without requiring wrapper code or reflection.

- The `RingBuffer` abstract class MUST be defined as:
  ```cpp
  namespace swtr {
      class RingBuffer {
      public:
          virtual ~RingBuffer() = default;

          // Thread control
          virtual void start() = 0;
          virtual void stop() = 0;
          virtual void wait() = 0;

          // Configuration
          virtual void set_read_fd(int fd) = 0;
          virtual void set_write_fd(int fd) = 0;

          // Logging
          virtual void set_logging_enabled(bool enabled) = 0;
          virtual bool get_logging_enabled() const = 0;
          virtual void set_output_stream(std::ostream& stream) = 0;
          virtual std::ostream* get_output_stream() const = 0;
          virtual void set_read_logging_enabled(bool enabled) = 0;
          virtual bool get_read_logging_enabled() const = 0;
          virtual void set_read_verbosity(LogLevel level) = 0;
          virtual LogLevel get_read_verbosity() const = 0;
          virtual void set_transform_logging_enabled(bool enabled) = 0;
          virtual bool get_transform_logging_enabled() const = 0;
          virtual void set_transform_verbosity(LogLevel level) = 0;
          virtual LogLevel get_transform_verbosity() const = 0;
          virtual void set_write_logging_enabled(bool enabled) = 0;
          virtual bool get_write_logging_enabled() const = 0;
          virtual void set_write_verbosity(LogLevel level) = 0;
          virtual LogLevel get_write_verbosity() const = 0;

          // Accessors
          virtual BufferStatus get_status(size_t slot_idx) const = 0;
          virtual void set_status(size_t slot_idx, BufferStatus status) = 0;
          virtual bool test_status(size_t slot_idx, BufferStatus status) const = 0;
          virtual ChecksumAlgorithm get_checksum_alg(size_t slot_idx) const = 0;
          virtual void set_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) = 0;
          virtual bool test_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) const = 0;
          virtual uint32_t get_checksum_val(size_t slot_idx) const = 0;
          virtual void set_checksum_val(size_t slot_idx, uint32_t val) = 0;
          virtual bool test_checksum_val(size_t slot_idx, uint32_t val) const = 0;
          virtual size_t get_max_size(size_t slot_idx) const = 0;
          virtual void set_max_size(size_t slot_idx, size_t size) = 0;
          virtual size_t get_data_size(size_t slot_idx) const = 0;
          virtual void set_data_size(size_t slot_idx, size_t size) = 0;
          virtual size_t get_transformed_size(size_t slot_idx) const = 0;
          virtual void set_transformed_size(size_t slot_idx, size_t size) = 0;
      };
  }
  ```
- The `SwtrRingBuffer` class MUST inherit from `RingBuffer`:
  ```cpp
  class SwtrRingBuffer : public RingBuffer {
      // ... implementation ...
  };
  ```

## Header Requirements
- **Self-Sufficiency**: The primary header file (`ringbuffer.hpp`) must be self-sufficient. It must include every standard library header and internal dependency it directly uses. Any translation unit that includes `ringbuffer.hpp` should be able to compile without requiring additional standard includes for the `swtr` namespace types.
- **Exact Include List for `ringbuffer.hpp`**: The file MUST contain these includes in this exact order:
  ```cpp
  #include <atomic>
  #include <cstddef>
  #include <format>
  #include <functional>
  #include <iostream>
  #include <string>
  #include "status.hpp"
  ```
  **Include Rationale**: `<atomic>` is required because `BufferSlot` declares `std::atomic<T>` members. `<format>` is required because the NVI logging uses `std::format_string` and `std::format`. These are not optional — the header must be self-sufficient.
- **`ringbuffer.hpp` Content**: The file MUST contain:
  1. All includes listed above
  2. `#pragma once` guard
  3. The `swtr` namespace wrapper
  4. The `RingBuffer` abstract class definition (as specified in the Abstract Base Class section)
  5. The `ErrorHandler` and `TransformFn` type aliases (as specified in Mandatory Type Definitions)
  6. The `MIN_NUMBER_SLOTS` and `DEFAULT_BUFFER_SIZE` constexpr constants (as specified in Constructor Requirements)
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
- `read_fd_` and `write_fd_` MUST be `std::atomic<int>`.
- **Slot Storage**: The ring buffer must store slots using `std::vector<std::unique_ptr<BufferSlot>>`.
- **Atomic Operations**: 
    - All members of `BufferSlot` that are `std::atomic` MUST be accessed using `.load()` and `.store()` methods rather than direct assignment or implicit conversion, especially when passed to functions or used in `std::format` strings, as `std::format` does not support `std::atomic` types directly.

## SwtrRingBuffer Member Variables
The `SwtrRingBuffer` class MUST declare the following member variables with exact names and types:

```cpp
class SwtrRingBuffer : public RingBuffer {
private:
    // Slot storage
    std::vector<std::unique_ptr<BufferSlot>> slots_;
    size_t num_slots_;

    // Index tracking — one independent atomic counter per pipeline stage
    std::atomic<size_t> read_index_;
    std::atomic<size_t> transform_index_;
    std::atomic<size_t> write_index_;

    // File descriptors (atomic for cross-thread access)
    std::atomic<int> read_fd_;
    std::atomic<int> write_fd_;

    // Buffer size per slot
    size_t buffer_size_;

    // Pipeline functions (non-atomic: set once at construction)
    ErrorHandler err_handler_;
    TransformFn transform_fn_;

    // Thread management
    std::jthread read_thread_;
    std::jthread transform_thread_;
    std::jthread write_thread_;

    // Synchronization primitives (aligned to cache line)
    alignas(64) std::mutex sync_mutex_;
    std::condition_variable_any cv_;

    // Logging configuration (atomic for runtime reconfiguration)
    std::atomic<bool> logging_enabled_;
    std::atomic<bool> read_logging_enabled_;
    std::atomic<bool> transform_logging_enabled_;
    std::atomic<bool> write_logging_enabled_;
    std::atomic<LogLevel> read_verbosity_;
    std::atomic<LogLevel> transform_verbosity_;
    std::atomic<LogLevel> write_verbosity_;

    // Output stream (pointer, not reference)
    std::ostream* output_stream_;

    // Log mutex (separate from sync_mutex_ to avoid nested locking)
    std::mutex log_mutex_;
};
```

**Exhaustive Member List Rule**: The member variable list shown above is exhaustive. Every listed member MUST be present in the implementation class, even if not directly referenced by a virtual method signature. Do NOT omit any listed member and do NOT add members not shown.

**Initialization rules**:
- `read_index_`, `transform_index_`, and `write_index_` MUST all be initialized to `0`.
- `read_fd_` and `write_fd_` MUST be initialized to `-1`.
- All logging booleans MUST default to `false`.
- All log verbosity levels MUST default to `LogLevel::Info`.
- `output_stream_` MUST default to `&std::cerr`.

## Source Organization & Deterministic Naming
To ensure build consistency and prevent git collisions, the following strict file mapping MUST be followed. No other source files shall be created unless explicitly requested.

### File Mapping Table
| Requirement / Logic Group | Exact Filename |
| :--- | :--- |
| Primary Abstract Interface (Defines `RingBuffer` only) | `ringbuffer.hpp` |
| Status and Checksum Enums | `status.hpp` |
| Concrete Implementation Class (Defines `SwtrRingBuffer`) | `swtr_ringbuffer_impl.hpp` |
| Concrete Implementation Logging | `LoggingOps_1.cpp` (and numbered files if necessary) |
| Constructor and Destructor | `Lifecycle.cpp` |
| Read Pipeline Logic | `ReadOps.cpp` |
| Transform Pipeline Logic | `TransformOps.cpp` |
| Write Pipeline Logic | `WriteOps.cpp` |
| Thread Management (`start`, `stop`, `wait`) | `Threading.cpp` |
| Error Handling (`handle_error`) | `ErrorOps.cpp` |

- **Required includes in `swtr_ringbuffer_impl.hpp`**: `<atomic>`, `<condition_variable>`, `<functional>`, `<mutex>`, `<stop_token>`, `<string>`, `<thread>`, `<vector>`, `"ringbuffer.hpp"`, `"status.hpp"`.
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
- **STRICT MAXIMUM (Function Distribution)**: No `.cpp` file may contain more than **3 function definitions**. This is a hard architectural constraint to minimize git collisions. If a logic group (e.g., Logging or Accessors) contains more than 3 functions, you **MUST** subdivide them into numbered files (e.g., `LoggingOps_1.cpp`, `LoggingOps_2.cpp`, etc.) until every file has $\le 3$ functions.
- **Function Verification**: In the final `implementation_report.md`, you must include a "Function Count Table" listing every `.cpp` file and the exact number of functions it contains.
- **Documentation**: A `README.md` file must be provided in the source directory describing the library and how to build it. The build instructions MUST include explicit compilation examples for both `g++` and `clang++` toolchains.

## Filename Integrity & Path Discipline
To ensure build system compatibility and prevent file system corruption:
- **Allowed Characters**: Filenames MUST only contain alphanumeric characters, underscores (`_`), and the file extension (e.g., `.cpp`, `.hpp`, `.md`).
- **Forbidden Characters**: Do NOT include curly braces (`{`, `}`), backticks (`` ` ``), markdown markers, or internal prompt tokens (e.g., `<tool_call|>`) in any filename or path.
- **Tool Call Verification**: Before executing a `replace_file` or `shell_command` to create a file, verify that the target path is a clean string containing only the intended filename and directory.

## Temporary Workspace
- **Centralized Storage**: All temporary files, utility scripts, or intermediate data generated during the execution of this prompt MUST be placed in a directory named `tmp`.
- **Isolation**: Do NOT create temporary files (e.g., `.py`, `.txt`, `.sh` scripts used for auditing or listing) in the project root, source directories, or any other permanent project location.

## Generation Process Logging
To ensure traceability during the code generation process, the following logging requirements MUST be implemented:
- **Log Directory**: Create a directory at `src/<os>/<lang>/logs/`.
- **Log Files**: Maintain three separate log files to track progress across the different prompt specifications:
    - `functional.log`: Logs actions performed as part of `functional.md`.
    - `build.log`: Logs actions performed as part of `build.md`.
    - `testing.log`: Logs actions performed as part of `testing.md`.
- **Log Format**: Each entry MUST be date-stamped in the format `[YYYY-MM-DD HH:MM:SS +/-HHMM] <Action Description>`, where the offset is the local time zone offset from UTC.
- **Log Persistence**: If a log file already exists, new entries MUST be appended to the end of the file; the file MUST NOT be overwritten.
- **Requirement**: Every significant milestone (e.g., file creation, build step completion, test data generation) MUST be recorded in the corresponding log file. A final entry MUST be made in `functional.log` marking the completion of the functional implementation phase, including the total elapsed time from the start of the process.

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
- The destructor MUST be `= default`.
- **Constexpr Constants** (defined in the header, outside the class):
  ```cpp
  constexpr size_t MIN_NUMBER_SLOTS = 1;
  constexpr size_t DEFAULT_BUFFER_SIZE = 4096;
  ```

**Constexpr Placement Rule**: These constexprs are declared at **namespace scope** in `ringbuffer.hpp`, outside the class. The `SwtrRingBuffer` member variable section below must NOT re-declare them as static class members.

- **Constructor Signature** (exact parameter order with defaults):
  ```cpp
  SwtrRingBuffer(
      size_t num_slots = MIN_NUMBER_SLOTS,
      BufferStatus initial_status = BufferStatus::readyforread,
      size_t buffer_size = DEFAULT_BUFFER_SIZE,
      ErrorHandler err_handler = nullptr,
      TransformFn transform_fn = nullptr
  );
  ```
- **Initialization**: The `max_data_buffer_size` for each slot must be initialized with the "buffer size per slot" value provided to the constructor.
   - The constructor MUST throw `std::invalid_argument` if `num_slots < MIN_NUMBER_SLOTS` or `buffer_size < 1`, with an error message specifying which parameter failed and why.
   - Create a constexpr `MIN_NUMBER_SLOTS` set to 1, use this for the validation in constructor.
   - Create a constexpr `MIN_BUFFER_SIZE` set to 1, use this for the validation in constructor.
- Default behavior for `readyforread`.

## Mandatory Public Interface
The following virtual functions MUST be implemented exactly as specified. Do not rename or change the signatures.

### Thread Control
- `virtual void start() = 0;`
- `virtual void stop() = 0;`
- `virtual void wait() = 0;`

### Configuration
- `virtual void set_read_fd(int fd) = 0;`
- `virtual void set_write_fd(int fd) = 0;`

### Logging
- `virtual void set_logging_enabled(bool enabled) = 0;`
- `virtual bool get_logging_enabled() const = 0;`
- `virtual void set_output_stream(std::ostream& stream) = 0;`
- `virtual std::ostream* get_output_stream() const = 0;`
- `virtual void set_read_logging_enabled(bool enabled) = 0;`
- `virtual bool get_read_logging_enabled() const = 0;`
- `virtual void set_read_verbosity(LogLevel level) = 0;`
- `virtual LogLevel get_read_verbosity() const = 0;`
- `virtual void set_transform_logging_enabled(bool enabled) = 0;`
- `virtual bool get_transform_logging_enabled() const = 0;`
- `virtual void set_transform_verbosity(LogLevel level) = 0;`
- `virtual LogLevel get_transform_verbosity() const = 0;`
- `virtual void set_write_logging_enabled(bool enabled) = 0;`
- `virtual bool get_write_logging_enabled() const = 0;`
- `virtual void set_write_verbosity(LogLevel level) = 0;`
- `virtual LogLevel get_write_verbosity() const = 0;`

### Accessors
- `virtual BufferStatus get_status(size_t slot_idx) const = 0;`
- `virtual void set_status(size_t slot_idx, BufferStatus status) = 0;`
- `virtual bool test_status(size_t slot_idx, BufferStatus status) const = 0;`
- `virtual ChecksumAlgorithm get_checksum_alg(size_t slot_idx) const = 0;`
- `virtual void set_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) = 0;`
- `virtual bool test_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) const = 0;`
- `virtual uint32_t get_checksum_val(size_t slot_idx) const = 0;`
- `virtual void set_checksum_val(size_t slot_idx, uint32_t val) = 0;`
- `virtual bool test_checksum_val(size_t slot_idx, uint32_t val) const = 0;`
- `virtual size_t get_max_size(size_t slot_idx) const = 0;`
- `virtual void set_max_size(size_t slot_idx, size_t size) = 0;`
- `virtual size_t get_data_size(size_t slot_idx) const = 0;`
- `virtual void set_data_size(size_t slot_idx, size_t size) = 0;`
- `virtual size_t get_transformed_size(size_t slot_idx) const = 0;`
- `virtual void set_transformed_size(size_t slot_idx, size_t size) = 0;`

**Accessor Implementation Rules**:
- `get_*` methods MUST use `.load()` on atomic members and direct read on non-atomic members.
- `set_*` methods MUST use `.store()` on atomic members and direct assignment on non-atomic members.
- `test_*` methods MUST perform an equality check using `.load()` on the atomic member and compare against the argument.

**Bounds Checking Pattern**: Every accessor must validate `slot_idx < num_slots_` before accessing `slots_[slot_idx]`. Do NOT use modulo wrapping (`slot_idx % slots_.size()`) as a substitute for validation.

**Const-Correctness Rule**: `handle_error()` is non-const (it calls `stop()`) and CANNOT be invoked from const accessor methods (`get_*` and `test_*`). Const accessors MUST return safe defaults on out-of-bounds indices:
  - `get_*` methods: return the enum's first/default value (e.g., `BufferStatus::STATUS_ERROR`, `ChecksumAlgorithm::NONE`) or `0` for numeric types.
  - `test_*` methods: return `false`.
- Non-const `set_*` methods: simply `return;` on out-of-bounds (no return value).
- All accessor methods MUST validate `slot_idx < num_slots_`.

## Implementation Logic
- **Read Function**: Use POSIX file descriptors. Mark slot `readyfortransform` after fill. Set `data_buffer_size` to bytes read. Reset to 0 on EOF/error.
- **Transform Function**: Pass `slot.data` directly to the transform function (in-place modification). Store result size in `transformed_data_buffer_size`. If no function, set `transformed_data_buffer_size` = `data_buffer_size` and mark `readyforwrite`. The transform function receives a reference to the slot's data buffer and modifies it in place — failing to modify `slot.data` causes transforms to be no-ops.
- **Write Function**: Use POSIX file descriptors. Write data, clear buffer, mark `readyforread`. Set `data_buffer_size` to 0. Flush (`fsync`) on `LAST_BUFFER_TO_WRITE`.
- **EOF Detection Semantics**: When `read(fd, buf, count)` returns `0`, this indicates EOF. The implementation MUST treat a return value of `0` as EOF and proceed with the EOF sequence. A return value of `-1` indicates an error; set `errno` and handle via the error handler.
- **Buffer Clearing Method**: After writing data to the output file descriptor, clear the `data` buffer using:
  ```cpp
  std::fill(data.begin(), data.end(), 0);
  ```
- **Slot Wrapping Strategy**: Each pipeline stage uses its own independent index counter. When advancing to the next slot, use modulo wrapping on that stage's counter:
  ```cpp
  // Read loop uses read_index_
  slot_idx = read_index_.load() % num_slots_;
  read_index_.fetch_add(1);

  // Transform loop uses transform_index_
  slot_idx = transform_index_.load() % num_slots_;
  transform_index_.fetch_add(1);

  // Write loop uses write_index_
  slot_idx = write_index_.load() % num_slots_;
  write_index_.fetch_add(1);
  ```
- **Critical: Independent Index Counters**: Each pipeline stage (read, transform, write) MUST use its own independent atomic index counter. The read loop uses `read_index_`, the transform loop uses `transform_index_`, and the write loop uses `write_index_`. **Do NOT share index counters between stages** — sharing causes threads to operate on wrong slots and breaks the pipeline.
- **EOF Sequence and Loop Termination**: 
    - **Reader** (uses `read_index_`): When EOF is reached, mark the current slot as `LAST_BUFFER_TO_TRANSFORM`, increment via `read_index_.fetch_add(1)`, notify all, and **break the loop**.
    - **Transformer** (uses `transform_index_`): When `LAST_BUFFER_TO_TRANSFORM` is encountered, mark the slot as `LAST_BUFFER_TO_WRITE`, increment via `transform_index_.fetch_add(1)`, notify all, and **break the loop**.
    - **Writer** (uses `write_index_`): When `LAST_BUFFER_TO_WRITE` is encountered, flush the output, mark the slot as `readyforread`, increment via `write_index_.fetch_add(1)`, notify all, and **break the loop**.
    - This ensures that the `wait()` method (which joins the threads) can return once the final buffer has been processed through the pipeline.

## Logging and Diagnostics
- **Architecture**: Use Non-Virtual Public Interface (NVI) pattern:
    - Public non-virtual `log_message` variadic template method using `std::format_string<Args...>` for the format argument.
    - Protected pure virtual `do_log(LogLevel level, const std::string& message)`.
- **Thread Safety**: Log messages must be printed atomically using a mutex.
- **Log Levels**: `Trace`, `Debug`, `Info`, `Warning`, `Error`, `Critical`. Use string representation (e.g., `[INFO]`).

## Execution Model & Threading
- Pipelines: `read_loop`, `transform_loop`, `write_loop` (all accepting `std::stop_token`).
- **Startup Order**: Threads MUST be started in the following order:
    1. Write thread
    2. Transform thread
    3. Read thread
- Use `std::jthread`, cooperative cancellation, `std::mutex sync_mutex_` and `std::condition_variable_any cv_`.
- The `start()` and `stop()` methods MUST use `std::lock_guard<std::mutex>` with `sync_mutex_`.
- The `start()` method MUST check `!thread_.joinable()` before creating a new `std::jthread`.
- Use `std::stop_callback` for immediate resource release.

## Error Handling and Recovery
- Slot `STATUS_ERROR` $\rightarrow$ call `int (*ErrorHandler)(size_t slot_idx, BufferStatus status)`.
- If return non-zero, trigger cooperative cancellation of all threads.

## Licensing
- All code is covered under a BSD 3-Clause License.

## Final Verification Step
Before providing the final code, you MUST perform a self-audit:
1. **Interface Match**: Do all public methods match the **Mandatory Public Interface** signatures exactly?
2. **Hierarchy Match**: Is the hierarchy exactly `RingBuffer` $\rightarrow$ `SwtrRingBuffer`?
3. **Thread Safety**: Are all configuration flags and `BufferSlot` members `std::atomic`?
4. **File Distribution**: Does any `.cpp` file contain more than 3 functions?
5. **Include Order**: Does every `.cpp` file start with `#include "ringbuffer.hpp"` as the first non-comment include?
6. **Naming**: Do all private members follow the trailing underscore convention?

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

**Excluded Platforms:**
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development.
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/`.
- The only files that should exist in these directories are zero-length `build.md`, `functional.md`, and `testing.md` files.
- If these directories contain any non-zero files, remove them.
