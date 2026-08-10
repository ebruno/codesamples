# Functional Requirements - Ringbuffer (Ubuntu 24.04 LTS, C++)

**Implementation Directive:**
This implementation MUST follow the common functional specification exactly to ensure cross-platform symmetry. 
Refer to the common specification for all architectural, interface, and implementation details:
[ringbuffer/prompts/common/cpp/functional.md](../../common/cpp/functional.md)

**Platform Specifics:**
- **Target OS**: Ubuntu 24.04 LTS (Linux kernel 6.N)
- **glibc**: Version 2.39+ compatibility required.
- **Toolchains**: Clang and GCC
- **License**: BSD 3-Clause License. The `LICENSE` file must be created in `src/ubuntu/cpp` with the standard BSD 3-Clause text.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
