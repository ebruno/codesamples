# Testing Requirements - Ringbuffer (Fedora 44, C++)

**Implementation Directive:**
This testing specification MUST follow the common testing specification exactly to ensure identical validation across platforms.

Refer to the following document for all shared requirements, data generation, and test matrices:
[ringbuffer/prompts/common/cpp/testing.md](../../common/cpp/testing.md)

**Platform Specifics:**
- **Containerized Build Environment**:
    - **Base Image**: `fedora:44`.
    - **Toolchain Installation**: Use `dnf` to install the following packages:
        - GNU: `gcc`, `gcc-c++`, `binutils`, `make`.
        - Build & Docs: `cmake`, `doxygen`.
        - LLVM/Clang: `clang`, `clang-tools-extra` (for `clang-tidy` and `clang-format`).
        - Utilities: `procps-ng`, `coreutils`, `findutils`, `which`, `file`, `strace`, `emacs-nox`, `patchelf`.
- **Container Path**: Use `tests/containers/fedora/Dockerfile`.
- **Header Search Path**: Use `ringbuffer/src/fedora/cpp`.
<EOF>
