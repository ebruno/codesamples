# Functional Requirements - Ringbuffer (macOS, C++)

**Implementation Directive:**
This implementation MUST follow the common functional specification exactly to ensure cross-platform symmetry. 
Refer to the common specification for all architectural, interface, and implementation details:
[ringbuffer/prompts/common/cpp/functional.md](../../common/cpp/functional.md)

**Platform Specifics:**
- **Target OS**: macOS
- **Toolchains**: Clang (Default)
- **License**: BSD 3-Clause License. The `LICENSE` file must be created in `src/macos/cpp` with the standard BSD 3-Clause text.

**Platform-Specific API Notes:**
- **C++20 Support**: Requires Xcode 14+ (clang 14+) for full `std::jthread` and `<stop_token>` support.
- **libc**: macOS uses BSD libc (NOT glibc). `std::jthread` is supported via pthreads backend.
- **POSIX Features**: Full POSIX.1-2008 support. `O_DIRECT` is NOT available; use standard buffered I/O.
- **fsync()**: Use `fcntl(fd, F_FULLFSYNC)` for guaranteed persistent storage (stronger than Linux `fsync()`). Standard `fsync()` only guarantees data, not metadata.
- **errno Semantics**: `EAGAIN` and `EINTR` exist but may have different numeric values than Linux. Always check errno symbolically, not by value.
- **stderr Buffering**: `std::cerr` is unbuffered by default on macOS (same as Linux), but note that `std::cout` is line-buffered when connected to a terminal.
- **Library Loading**: The library uses `@rpath` for install names. Consumers must set `DYLD_LIBRARY_PATH` or use `-rpath` at link time.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
