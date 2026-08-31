# Testing Requirements - Ringbuffer (Raspberry Pi OS, C++)

**Implementation Directive:**
This testing specification MUST follow the common testing specification exactly to ensure identical validation across platforms.

Refer to the following document for all shared requirements, data generation, and test matrices:
[prompts/common/cpp/testing.md](../../common/cpp/testing.md)

Refer to [prompts/common/cpp/testing.md](../../common/cpp/testing.md) for the Platform and Container Runtime Reference before planning any test operation.

**Platform Specifics:**
- **Containerized Build Environment**:
    - **Base Image**: `debian:13` (trixie) — Bookworm's GCC 12 lacks C++20 `<format>` support (requires GCC 13+); Debian 13 provides GCC 14.2 with full C++20 support and OpenJDK 21.
    - **Toolchain Installation**: Use `apt-get` to install the following packages:
        - GNU: `gcc`, `g++`, `binutils`, `make`.
        - Build & Docs: `cmake`, `doxygen`.
        - LLVM/Clang: `clang`, `clang-tidy`, `clang-format`.
        - Utilities: `procps`, `coreutils`, `findutils`, `which`, `file`, `strace`, `emacs-nox`, `patchelf`.
        - Java: `openjdk-21-jdk-headless`, `maven`.
    - **Container Configuration**: The `Dockerfile` MUST set `WORKDIR /app` to align with the host volume mounts and the execution workflow.
    - **Toolchain Verification**: Upon first container initialization, verify the toolchain by executing `g++ --version` and `make --version` to ensure all required build tools are present and operational.
    - **Audit Trail**: The `verify` target MUST log the exact versions of the compiler and linker (e.g., `g++ -v` and `ld -v`) into `tests/reports/regression_report.md` to provide a baseline for binary size analysis.
- **Container Path**: Use `tests/containers/raspios/Dockerfile`.
- **Header Search Path**: Use `src/raspios/cpp`.

**Host-Target Compatibility**: Raspberry Pi OS is arm64-only. On Apple Silicon Macs, containers run natively (no cross-architecture emulation needed). On x86_64 hosts, use `--platform linux/arm64` with podman.

**Host-Target Compatibility** and **Container Runtime Pre-flight**: See `prompts/common/cpp/testing.md` for the authoritative host-target and container runtime directives.

**Tooling and Recovery:** See `prompts/common/cpp/testing.md` for the authoritative tooling and recovery directives.
