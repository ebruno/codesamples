# Testing Requirements - Ringbuffer (Ubuntu 24.04 LTS, C++)

**Implementation Directive:**
This testing specification MUST follow the common testing specification exactly to ensure identical validation across platforms.

Refer to the following document for all shared requirements, data generation, and test matrices:
[prompts/common/cpp/testing.md](../../common/cpp/testing.md)

Refer to [prompts/common/cpp/testing.md](../../common/cpp/testing.md) for the Platform and Container Runtime Reference before planning any test operation.

**Platform Specifics:**
- **Containerized Build Environment**:
    - **Base Image**: `ubuntu:24.04`.
    - **Toolchain Installation**: Use `apt-get` to install the following packages:
        - GNU: `gcc`, `g++`, `binutils`, `make`.
        - Build & Docs: `cmake`, `cmake-data`, `cmake-doc`, `dh-cmake`, `debhelper`, `devscripts`, `doxygen`.
        - LLVM/Clang: `clang`, `clang-tidy`, `clang-format`.
        - Utilities: `procps`, `coreutils`, `findutils`, `which`, `file`, `strace`, `emacs-nox`, `patchelf`.
    - **Container Configuration**: The `Dockerfile` MUST set `WORKDIR /app` to align with the host volume mounts and the execution workflow.
    - **Toolchain Verification**: Upon first container initialization, verify the toolchain by executing `g++ --version` and `make --version` to ensure all required build tools are present and operational.
    - **Audit Trail**: The `verify` target MUST log the exact versions of the compiler and linker (e.g., `g++ -v` and `ld -v`) into `tests/reports/regression_report.md` to provide a baseline for binary size analysis.
- **Container Path**: Use `tests/containers/ubuntu/Dockerfile`.
- **Header Search Path**: Use `src/ubuntu/cpp`.

**Host-Target Compatibility**, **CRITICAL: Never Attempt Native Linux Builds on macOS**, and **Container Runtime Pre-flight**: See `prompts/common/cpp/testing.md` for the authoritative host-target, container runtime, and native build prevention directives.

**Tooling and Recovery:** See `prompts/common/cpp/testing.md` for the authoritative tooling and recovery directives.
