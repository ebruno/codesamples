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
        - Build & Docs: `cmake`, `cmake-doc`, `cmake-data`, `cmake-rpm`, `doxygen`.
        - LLVM/Clang: `clang`, `clang-tools-extra` (for `clang-tidy` and `clang-format`).
        - Utilities: `procps-ng`, `coreutils`, `findutils`, `which`, `file`, `strace`, `emacs-nox`, `patchelf`, `fedora-packager`.
    - **Container Configuration**: The `Dockerfile` MUST set `WORKDIR /app` to align with the host volume mounts and the execution workflow.
    - **Toolchain Verification**: Upon first container initialization, verify the toolchain by executing `g++ --version` and `make --version` to ensure all required build tools are present and operational.
    - **Audit Trail**: The `verify` target MUST log the exact versions of the compiler and linker (e.g., `g++ -v` and `ld -v`) into the final `regression_report.md` to provide a baseline for binary size analysis.
- **Container Path**: Use `tests/containers/fedora/Dockerfile`.
- **Header Search Path**: Use `ringbuffer/src/fedora/cpp`.

**Host-Target Compatibility:**
- **macOS host**: The target OS MUST be macOS. No container support is available for macOS — testing must run natively.
- **Linux host**: If the host distro does not match the target distro (e.g., Fedora testing run from macOS or Ubuntu host), a container matching the target OS MUST be used. The Makefile's container-build override handles this automatically: `UNAME_S=macOS` ⇒ `container` command; non-matching Linux distro ⇒ `podman`. When the host already matches the target (e.g., Fedora testing on Fedora), native execution is permitted.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
