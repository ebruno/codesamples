# Build Requirements - Ringbuffer (Arch Linux, C++)

**Implementation Directive:**
This build specification MUST follow the common testing specification exactly to ensure identical validation across platforms.

Refer to the following document for all shared requirements, data generation, and test matrices:
[prompts/common/cpp/testing.md](../../common/cpp/testing.md)

Refer to [prompts/common/cpp/testing.md](../../common/cpp/testing.md) for the Platform and Container Runtime Reference before planning any test operation.

**Platform Specifics:**
- **Containerized Build Environment**:
    - **Base Image**: `archlinux:YYYY.MM.DD` (datestamp tag from 3 months ago)
    - **Toolchain Installation**: Use `pacman -S --noconfirm` to install the following packages:
        - Base build tools: `base-devel` (provides gcc, make, binutils)
        - Build & Docs: `cmake`, `doxygen`
        - LLVM/Clang: `clang`
        - Utilities: `patchelf`, `strace`, `python3`
    - **Container Configuration**: The `Dockerfile` MUST set `WORKDIR /app` to align with the host volume mounts and the execution workflow.
    - **Toolchain Verification**: Upon first container initialization, verify the toolchain by executing `g++ --version` and `make --version` to ensure all required build tools are present and operational.
    - **Audit Trail**: The `verify` target MUST log the exact versions of the compiler and linker (e.g., `g++ -v` and `ld -v`) into `tests/reports/regression_report.md` to provide a baseline for binary size analysis.
- **Container Path**: Use `tests/containers/archlinux/Dockerfile`.
- **Header Search Path**: Use `src/archlinux/cpp`.

**macOS Skip Logic:**
Arch Linux container images are amd64-only. On Apple Silicon (M-series) Macs, there is no ARM64 Arch Linux container available. The test infrastructure setup MUST detect macOS and skip gracefully:

When running on macOS, the script MUST log to `build.log`:
```
[timestamp] Arch Linux test infrastructure skipped on macOS (Apple Silicon) — no ARM64 container available.
[timestamp] Test execution requires a Linux host with podman/docker.
```

The `container` target in the test Makefile MUST include the same macOS skip check as described in `build.md`.
