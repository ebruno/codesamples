# Build Requirements - Ringbuffer (Fedora 44, C++)

**Implementation Directive:**
This build specification MUST follow the common testing specification exactly to ensure identical validation across platforms.

Refer to the following document for all shared requirements, data generation, and test matrices:
[ringbuffer/prompts/common/cpp/testing.md](../../common/cpp/testing.md)

Refer to [ringbuffer/prompts/common/cpp/testing.md](../../common/cpp/testing.md) for the Platform and Container Runtime Reference before planning any test operation.

**Platform Specifics:**
- **Containerized Build Environment**:
    - **Base Image**: `fedora:44`.
    - **Toolchain Installation**: Use `dnf` to install the following packages:
        - GNU: `gcc`, `gcc-c++`, `binutils`, `make`.
        - Build & Docs: `cmake`, `doxygen`.
        - LLVM/Clang: `clang`.
        - Utilities: `procps-ng`, `coreutils`, `findutils`, `file`, `strace`, `patchelf`.
    - **vmnet Network Timeout**: Apple Container's vmnet network requires extended dnf timeout. The Dockerfile MUST include `--setopt=timeout=300` in all dnf install commands.
    - **Container Configuration**: The `Dockerfile` MUST set `WORKDIR /app` to align with the host volume mounts and the execution workflow.
    - **Toolchain Verification**: Upon first container initialization, verify the toolchain by executing `g++ --version` and `make --version` to ensure all required build tools are present and operational.
    - **Audit Trail**: The `verify` target MUST log the exact versions of the compiler and linker (e.g., `g++ -v` and `ld -v`) into `tests/reports/regression_report.md` to provide a baseline for binary size analysis.
- **Container Path**: Use `tests/containers/fedora/Dockerfile`.
- **Header Search Path**: Use `ringbuffer/src/fedora/cpp`.
