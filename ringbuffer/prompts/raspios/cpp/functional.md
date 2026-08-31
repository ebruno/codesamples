# Functional Requirements - Ringbuffer (Raspberry Pi OS, C++)

**Implementation Directive:**
This implementation MUST follow the common functional specification exactly to ensure cross-platform symmetry. 
Refer to the common specification for all architectural, interface, and implementation details:
[prompts/common/cpp/functional.md](../../common/cpp/functional.md)

**Platform Specifics:**
- **Target OS**: Raspberry Pi OS (Debian 13/trixie), Linux kernel 6.1.x LTS
- **OS Identification**: `ID=debian` in `/etc/os-release`, confirmed by presence of `/etc/rpi-issue`
- **Architecture**: arm64 (aarch64) — runs natively on Apple Silicon Macs
- **Toolchains**: Clang and GCC
- **License**: BSD 3-Clause License. The `LICENSE` file must be created in `src/raspios/cpp` with the standard BSD 3-Clause text.

**Version Override Note:** If a version override is provided (e.g., "raspios bookworm"), use this file as the architectural reference but adjust platform-specific details (kernel version, glibc) to match the requested version. For the requested version, check `../<os>/containers/build/Dockerfile` (if it exists) for the base image tag, or consult Debian's release documentation for kernel/glibc versions.

**Tooling and Recovery:** See `prompts/common/cpp/functional.md` for the authoritative tooling and recovery directives.
