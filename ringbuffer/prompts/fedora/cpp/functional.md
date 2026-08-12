# Functional Requirements - Ringbuffer (Fedora 44, C++)

**Implementation Directive:**
This implementation MUST follow the common functional specification exactly to ensure cross-platform symmetry. 
Refer to the common specification for all architectural, interface, and implementation details:
[prompts/common/cpp/functional.md](../../common/cpp/functional.md)

**Platform Specifics:**
- **Target OS**: Fedora 44 (Linux kernel 7.1.5-200.fc44)
- **glibc**: Version 2.38+ compatibility required.
- **Toolchains**: Clang and GCC
- **License**: BSD 3-Clause License. The `LICENSE` file must be created in `src/fedora/cpp` with the standard BSD 3-Clause text.

**Version Override Note:** If a version override is provided (e.g., "fedora 43"), use this file as the architectural reference but adjust platform-specific details (kernel version, glibc) to match the requested version. For the requested version, check `src/<os>/cpp/containers/Dockerfile` (if it exists) for the base image tag, or consult Fedora's release documentation for kernel/glibc versions.

**Tooling and Recovery:** See `prompts/common/cpp/functional.md` for the authoritative tooling and recovery directives.
