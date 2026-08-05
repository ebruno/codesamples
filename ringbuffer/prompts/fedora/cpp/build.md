# Build Requirements - Ringbuffer (Fedora 44, C++)

**Implementation Directive:**
This build specification MUST follow the common build specification exactly to ensure binary symmetry. 

Refer to the following document for all shared requirements, flags, and process:
[ringbuffer/prompts/common/cpp/build.md](../../common/cpp/build.md)

**Platform Specifics:**
- **Target Environment**: Fedora 44, Kernel 7.1.5-200.fc44.
- **Prerequisites**: Install the following packages via `dnf`:
    - `gcc`, `gcc-c++`, `binutils`, `make`, `cmake`, `doxygen`, `clang`, `clang-tools-extra`, `procps-ng`, `coreutils`, `findutils`, `which`.

**Containerized Build Environment**:
- **Base Image**: `fedora:44`.
- **Toolchain Installation**: Use `dnf` to install the following packages:
    - GNU: `gcc`, `gcc-c++`, `binutils`, `make`.
    - Build & Docs: `cmake`, `doxygen`.
    - LLVM/Clang: `clang`, `clang-tools-extra`.
    - Utilities: `procps-ng`, `coreutils`, `findutils`, `which`, `file`, `patchelf`, `vim`, `strace`, `emacs-nox`.
- **Container Path**: Use `src/fedora/cpp/containers/Dockerfile`.

## Container Lifecycle Automation
To simplify environment setup, the `Makefile` MUST implement a `container` target that performs the following logic:

1. **Host-Aware Tooling**: The target must detect the host operating system to select the correct container runtime:
    - **macOS**: Use the `container` command.
    - **Linux (Debian, Fedora, etc.)**: Use the `podman` command.
2. **Image State Management**:
    - **Check Existence**: Verify if the image `ringbuffer_fedora_build` already exists.
    - **Create**: If the image does not exist, create it using the `Dockerfile` located at `src/fedora/cpp/containers/Dockerfile`.
    - **Update**: If the image exists, rebuild/update it to ensure it is in sync with the current `Dockerfile` specification.
3. **Image Cleanup**:
    - A separate `Makefile` target (e.g., `container-clean`) MUST be implemented to remove the `ringbuffer_fedora_build` image from the host system.
    - The `dist-clean` target MUST call this container cleanup rule to ensure a complete environment reset.
4. **Documentation**: This automation logic (including host detection, the `make container` trigger, and the cleanup process) MUST be clearly documented in the project's `README.md` files, providing explicit instructions on how the user can set up and tear down their build environment.

- All code is covered under a BSD 3-Clause License.
