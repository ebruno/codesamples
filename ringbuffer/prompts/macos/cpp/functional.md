# Functional Requirements - Ringbuffer (macOS, C++)

- Code should be C++20 compliant.
- Code should use `std::jthread`, cooperative cancellation, and advanced synchronization primitives.
- Code should be buildable using both clang and gcc tool chains.
- A ring buffer (also called a circular buffer) is a fixed-size, first-in-first-out (FIFO) data structure that connects its memory end-to-end in a loop. It uses a read pointer and a write pointer that wrap around to the start of the array when they reach the end.
- Fixed Array: A pre-allocated block of memory that never changes size.
- The ringbuffer structure will be as follows:
  
  |buffer idx number|buffer status|max data buffer size|data buffer size|transformed data buffer size|checksum algorithm|checksum value|data buffer|
  
- Total of 14 buffer status values should be defined using an `enum class`.
- The status values `readforread`, `readyfortransform`, and `readyforwrite` should be aliased to the first 3 values of the `enum class`.
- **Special Terminal Statuses**: 
    - `LAST_BUFFER_TO_TRANSFORM`: Indicates the final buffer to be processed by the transformer.
    - `LAST_BUFFER_TO_WRITE`: Indicates the final buffer to be processed by the writer.
- **Checksum Algorithms**: Common checksum algorithms should be defined using an `enum class`, including at minimum:
    - `MD5`
    - `SHA256`
    - `SHA512`
    - `NONE` (for cases where no checksum is required)

## Performance & Binary Optimization
- **Dead Code Elimination**: The library must be compatible with dead code elimination (e.g., using `-ffunction-sections` and `-fdata-sections`) to ensure the "small binary" goal is verifiable during testing.
- **Memory Alignment**: Buffer slots and index counters should be aligned to cache line boundaries (e.g., using `alignas(64)`) to prevent false sharing between threads.

## Source Organization
- Group functions logically in source files:
    - **Lifecycle**: Use `Lifecycle.cpp` for the constructor and destructor.
    - **Operations**: Group read-related, transform-related, and write-related functions into their own respective logical groups.
    - **Accessors**: Group getter and setter functions together that process the same data.
- **Git Collision Mitigation**: Limit to a maximum of 3 functions per source file to avoid source code collisions in git.

## Constructor Requirements
- **Automatic Start**: The constructor MUST NOT start the read, transform, or write threads automatically.
- Allow specification of the number of slots in the ring buffer.
- Allow specification of the initial status of the ringbuffer.
- Allow specification of the buffer size per slot (default value: 4096).
- **Initialization**: The `max data buffer size` for each slot must be initialized with the "buffer size per slot" value provided to the constructor.
   - The constructor should fail if number slots is not greater than 1 and the buffer size is not greater than 1, and exeception should fail reporting why it failed.
- Default behavior for `readforread`.

## Public Member Functions
- **Thread Control**:
    - Provide a `start` function to initialize and launch the read, transform, and write threads.
    - Provide a `stop` function to trigger cooperative cancellation and join all threads.
    - Provide a `wait` function that blocks the caller until all three pipeline threads have naturally terminated (e.g., after an EOF sequence).
- **Core Operations** (Must be implemented as class member functions):
    - **Read Function**:
        - Should use POSIX file descriptors for reading.
        - After filling the buffer, it will mark the slot as `readyfortransform`.
        - It will set the `data buffer size` after loading the buffer.
    - **Transform Function**:
        - The class should accept a `std::function` to define the transformation operation.
        - The transform function will apply this operation to the data and mark the slot as `readyforwrite`.
        - It will set the `transformed data buffer size` after the transform is complete.
        - **Optional Transform**: If no transform function is specified, the transform method should simply mark the buffer as `readyforwrite` (or `LAST_BUFFER_TO_WRITE` if applicable) and allow it to proceed to the writer.
    - **Write Function**:
        - Should use POSIX file descriptors for writing.
        - It will write the data to the descriptor, clear the buffer, and mark the slot as `readyforread`.
        - It will set the `data buffer size` to 0.
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
    - Provide a global logging enabled/disabled flag with `set` and `get` functions.
    - Provide `set` and `get` functions to specify the output stream (e.g., `std::ostream`). The default stream should be `std::cerr`.
    - **Architecture**: Use a Non-Virtual Public Interface (NVI) pattern:
        - Public non-virtual `log_message` method for external use.
        - Protected pure virtual implementation method `do_log` for derived classes.
        - Use the `override` keyword in derived classes.
    - **Log Levels**: Define an enumeration for the following levels: `Trace`, `Debug`, `Info`, `Warning`, `Error`, `Critical`.
	    - Log levels should have strings that can used in place of enumerated log level values in messages.
    - **Log Public and private log function Signature**: The logging functions must support a variadic template signature: `void do_log(LogLevel level, const char* fmt, Args&&... args)`.
- **Independent Stage Logging**:
    - Provide independent enable/disable flags and verbosity level settings for the **Read**, **Transform**, and **Write** stages.
    - Each stage must check its specific flag and verbosity level before calling the log implementation.

## Execution Model & Threading
- The read, transform, and write functions will run in separate threads using `std::jthread`, cooperative cancellation, and advanced synchronization primitives.
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
- If the error handling routine returns a non-zero value, the entire pipeline should stop (triggering cooperative cancellation of all threads).
