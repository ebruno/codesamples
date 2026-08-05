# Build Requirements - Ringbuffer (Debian 13, C++)

**Implementation Directive:**
This build specification MUST follow the common build specification exactly to ensure binary symmetry. 

Refer to the following document for all shared requirements, flags, and process:
[ringbuffer/prompts/common/cpp/build.md](../../common/cpp/build.md)

**Platform Specifics:**
- **Target Environment**: Debian 13, Linux kernel 6.12 LTS.
- **Prerequisites**: Install the following packages via `apt-get`:
    - `build-essential`, `cmake`, `doxygen`, `clang`, `clang-tidy`, `clang-format`, `procps`, `coreutils`, `findutils`, `which`.

**Containerized Build Environment**:
- **Base Image**: `debian:13`.
- **Toolchain Installation**: Use `apt-get` to install the following packages:
    - GNU: `gcc`, `g++`, `binutils`, `make`.
    - Build & Docs: `cmake`, `doxygen`.
    - LLVM/Clang: `clang`, `clang-tidy`, `clang-format`.
    - Utilities: `procps`, `coreutils`, `findutils`, `which`, `file`, `patchelf`, `vim`, `strace`, `emacs-nox`.
- **Container Path**: Use `src/debian/cpp/containers/Dockerfile`.

## Container Lifecycle Automation
To simplify environment setup, the `Makefile` MUST implement a `container` target that performs the following logic:

1. **Host-Aware Tooling**: The target must detect the host operating system to select the correct container runtime:
    - **macOS**: Use the `container` command.
    - **Linux (Debian, Fedora, etc.)**: Use the `podman` command.
2. **Image State Management**:
    - **Check Existence**: Verify if the image `ringbuffer_debian_build` already exists.
    - **Create**: If the image does not exist, create it using the `Dockerfile` located at `src/debian/cpp/containers/Dockerfile`.
    - **Update**: If the image exists, rebuild/update it to ensure it is in sync with the current `Dockerfile` specification.
3. **Image Cleanup**:
    - A separate `Makefile` target (e.g., `container-clean`) MUST be implemented to remove the `ringbuffer_debian_build` image from the host system.
    - The `dist-clean` target MUST call this container cleanup rule to ensure a complete environment reset.
4. **Documentation**: This automation logic (including host detection, the `make container` trigger, and the cleanup process) MUST be clearly documented in the project's `README.md` files, providing explicit instructions on how the user can set up and tear down their build environment.

- All code is covered under a BSD 3-Clause License.
