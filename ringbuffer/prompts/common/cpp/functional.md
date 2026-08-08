# Functional Requirements - Ringbuffer (Common C++)

**Cross-Platform Consistency Requirement:** This library is deployed across multiple Linux distributions. To ensure maintainability and binary symmetry, the source code MUST be identical across all platforms. Do not adapt the coding style, naming, or architecture to the specific distribution; follow these specifications strictly.

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
  
- **Exact Enum Definitions**:
    - `BufferStatus` MUST be defined exactly as: `readyforread`, `readyfortransform`, `readyforwrite`, `processing_read`, `processing_transform`, `processing_write`, `empty`, `full`, `LAST_BUFFER_TO_TRANSFORM`, `LAST_BUFFER_TO_WRITE`, `pending_read`, `pending_transform`, `pending_write`, `STATUS_ERROR` (index 13).
    - `ChecksumAlgorithm` MUST be defined exactly as: `NONE`, `MD5`, `SHA256`, `SHA512`.

## Mandatory Type Definitions
- `ErrorHandler` MUST be defined as: `using ErrorHandler = int (*)(size_t slot_idx, BufferStatus status);`
- `TransformFn` MUST be defined as: `using TransformFn = std::function<void(std::vector<uint8_t>&, size_t&)>;`
- `BufferSlot` members `buffer_idx`, `status`, `max_data_buffer_size`, `data_buffer_size`, `transformed_data_buffer_size`, `checksum_alg`, and `checksum_val` MUST all be `std::atomic`.

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
- `read_fd_` and `write_fd_` MUST be `std::atomic<int>`.
- **Slot Storage**: The ring buffer must store slots using `std::vector<std::unique_ptr<BufferSlot>>`.
- **Atomic Operations**: 
    - All members of `BufferSlot` that are `std::atomic` MUST be accessed using `.load()` and `.store()` methods rather than direct assignment or implicit conversion, especially when passed to functions or used in `std::format` strings, as `std::format` does not support `std::atomic` types directly.

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
- **Documentation**: A `README.md` file must be provided in the source directory describing the library and how to build it.

## Filename Integrity & Path Discipline
To ensure build system compatibility and prevent file system corruption:
- **Allowed Characters**: Filenames MUST only contain alphanumeric characters, underscores (`_`), and the file extension (e.g., `.cpp`, `.hpp`, `.md`).
- **Forbidden Characters**: Do NOT include curly braces (`{`, `}`), backticks (`` ` ``), markdown markers, or internal prompt tokens (e.g., `<tool_call|>`) in any filename or path.
- **Tool Call Verification**: Before executing a `replace_file` or `shell_command` to create a file, verify that the target path is a clean string containing only the intended filename and directory.

## Temporary Workspace
- **Centralized Storage**: All temporary files, utility scripts, or intermediate data generated during the execution of this prompt MUST be placed in a directory named `ringbuffer/tmp`.
- **Isolation**: Do NOT create temporary files (e.g., `.py`, `.txt`, `.sh` scripts used for auditing or listing) in the project root, source directories, or any other permanent project location.

## Generation Process Logging
To ensure traceability during the code generation process, the following logging requirements MUST be implemented:
- **Log Directory**: Create a directory at `ringbuffer/src/<os>/<lang>/logs/`.
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

## Implementation Logic
- **Read Function**: Use POSIX file descriptors. Mark slot `readyfortransform` after fill. Set `data buffer size` to bytes read. Reset to 0 on EOF/error.
- **Transform Function**: Apply `std::function`. Mark slot `readyforwrite`. Load atomic size to temporary, pass to function, store result back. If no function, set `transformed data buffer size` = `data buffer size` and mark `readyforwrite`.
- **Write Function**: Use POSIX file descriptors. Write data, clear buffer, mark `readyforread`. Set `data buffer size` to 0. Flush (`fsync`) on `LAST_BUFFER_TO_WRITE`.
- **EOF Sequence and Loop Termination**: 
    - **Reader**: When EOF is reached, mark the current slot as `LAST_BUFFER_TO_TRANSFORM`, increment the index, notify all, and **break the loop**.
    - **Transformer**: When `LAST_BUFFER_TO_TRANSFORM` is encountered, mark the slot as `LAST_BUFFER_TO_WRITE`, increment the index, notify all, and **break the loop**.
    - **Writer**: When `LAST_BUFFER_TO_WRITE` is encountered, flush the output, mark the slot as `readyforread`, increment the index, notify all, and **break the loop**.
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
