# Functional Requirements - Ringbuffer (Ubuntu 24.04 LTS, C++)

**Implementation Directive:**
This implementation MUST follow the common functional specification exactly to ensure cross-platform symmetry. 
Refer to the common specification for all architectural, interface, and implementation details:
[prompts/common/cpp/functional.md](../../common/cpp/functional.md)

**Platform Specifics:**
- **Target OS**: Ubuntu 24.04 LTS (Linux kernel 6.N)
- **glibc**: Version 2.39+ compatibility required.
- **Toolchains**: Clang and GCC
- **License**: BSD 3-Clause License. The `LICENSE` file must be created in `src/ubuntu/cpp` with the standard BSD 3-Clause text.

**Version Override Note:** If a version override is provided (e.g., "ubuntu 22.04"), use this file as the architectural reference but adjust platform-specific details (kernel version, glibc) to match the requested version. For the requested version, check `../<os>/containers/build/Dockerfile` (if it exists) for the base image tag, or consult Ubuntu's release documentation for kernel/glibc versions.

**Tooling and Recovery:** See `prompts/common/cpp/functional.md` for the authoritative tooling and recovery directives.
