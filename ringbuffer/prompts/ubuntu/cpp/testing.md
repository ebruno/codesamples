# Testing Requirements - Ringbuffer (Ubuntu 24.04 LTS, C++)

**Implementation Directive:**
This testing specification MUST follow the common testing specification exactly to ensure identical validation across platforms.

Refer to the following document for all shared requirements, data generation, and test matrices:
[ringbuffer/prompts/common/cpp/testing.md](../../common/cpp/testing.md)

Refer to [ringbuffer/prompts/common/cpp/testing.md](../../common/cpp/testing.md) for the Platform and Container Runtime Reference before planning any test operation.

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
    - **Audit Trail**: The `verify` target MUST log the exact versions of the compiler and linker (e.g., `g++ -v` and `ld -v`) into the final `regression_report.md` to provide a baseline for binary size analysis.
- **Container Path**: Use `tests/containers/ubuntu/Dockerfile`.
- **Header Search Path**: Use `ringbuffer/src/ubuntu/cpp`.

**Host-Target Compatibility:**
- **macOS host**: The target OS MUST be macOS. No container support is available for macOS — testing must run natively.
- **Linux host**: If the host distro does not match the target distro (e.g., Ubuntu testing run from macOS or Fedora host), a container matching the target OS MUST be used. The Makefile's container-build override handles this automatically: `UNAME_S=macOS` ⇒ `container` command; non-matching Linux distro ⇒ `podman`. When the host already matches the target (e.g., Ubuntu testing on Ubuntu), native execution is permitted.

**CRITICAL: Never Attempt Native Linux Builds on macOS**
When the host OS is macOS and the target OS is Ubuntu (or any Linux distribution):
- **NEVER** attempt to compile test binaries natively on the macOS host. The resulting Mach-O binaries will not run in the Linux container and are useless for testing.
- **ALWAYS** execute all build, validation, and test steps inside the `ringbuffer_ubuntu_test` container.
- If the container cannot be built or started, **STOP** and report an error. Do not attempt native compilation as a fallback.

## Container Runtime Pre-flight (macOS Host)
When the host OS is macOS and the target OS is Ubuntu, the `container` command MUST be available in PATH before any container operations proceed.
- **Verification**: Execute `command -v container` to confirm availability.
- **Error Handling**: If `container` is NOT found, STOP and display:
  ```
  ERROR: The 'container' command is required for cross-OS testing from macOS to Linux targets, but it was not found in PATH.
  
  Please install Apple Container from: https://github.com/apple/container
  
  After installation, ensure the 'container' command is available in your PATH and re-run the test workflow.
  ```

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
