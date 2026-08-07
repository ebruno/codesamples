# Testing Requirements - Ringbuffer (Debian 13, C++)

**Implementation Directive:**
This testing specification MUST follow the common testing specification exactly to ensure identical validation across platforms.

Refer to the following document for all shared requirements, data generation, and test matrices:
[ringbuffer/prompts/common/cpp/testing.md](../../common/cpp/testing.md)

**Platform Specifics:**
- **Containerized Build Environment**:
    - **Base Image**: `debian:13`.
    - **Toolchain Installation**: Use `apt-get` to install the following packages:
        - GNU: `gcc`, `g++`, `binutils`, `make`.
        - Build & Docs: `cmake`, `doxygen`.
        - LLVM/Clang: `clang`, `clang-tidy`, `clang-format`.
        - Utilities: `procps`, `coreutils`, `findutils`, `which`, `file`, `strace`, `emacs-nox`, `patchelf`.
    - **Container Configuration**: The `Dockerfile` MUST set `WORKDIR /app` to align with the host volume mounts and the execution workflow.
    - **Toolchain Verification**: Upon first container initialization, verify the toolchain by executing `g++ --version` and `make --version` to ensure all required build tools are present and operational.
    - **Audit Trail**: The `verify` target MUST log the exact versions of the compiler and linker (e.g., `g++ -v` and `ld -v`) into the final `regression_report.md` to provide a baseline for binary size analysis.
- **Container Path**: Use `tests/containers/debian/Dockerfile`.
- **Header Search Path**: Use `ringbuffer/src/debian/cpp`.
