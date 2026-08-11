# Functional Requirements - Ringbuffer (Debian 13, C++)

**Implementation Directive:**
This implementation MUST follow the common functional specification exactly to ensure cross-platform symmetry. 
Refer to the common specification for all architectural, interface, and implementation details:
[ringbuffer/prompts/common/cpp/functional.md](../../common/cpp/functional.md)

**Platform Specifics:**
- **Target OS**: Debian 13 (Linux kernel 6.12 LTS)
- **Toolchains**: Clang and GCC
- **License**: BSD 3-Clause License. The `LICENSE` file must be created in `src/debian/cpp` with the standard BSD 3-Clause text.

**Version Override Note:** If a version override is provided (e.g., "debian 12"), use this file as the architectural reference but adjust platform-specific details (kernel version, glibc) to match the requested version. For the requested version, check `ringbuffer/src/<os>/cpp/containers/Dockerfile` (if it exists) for the base image tag, or consult Debian's release documentation for kernel/glibc versions.

**Tooling and Recovery:** See `ringbuffer/prompts/common/cpp/functional.md` for the authoritative tooling and recovery directives.
