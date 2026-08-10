# Build Requirements - Ringbuffer (Fedora 44, C++)

**Implementation Directive:**
This build specification MUST follow the common build specification exactly to ensure binary symmetry. 

Refer to the following document for all shared requirements, flags, and process:
[ringbuffer/prompts/common/cpp/build.md](../../common/cpp/build.md)

**Platform Specifics:**
- **Target Environment**: Fedora 44, Kernel 7.1.5-200.fc44.
- **Prerequisites**: Install the following packages via `dnf`:
    - `gcc`, `gcc-c++`, `binutils`, `make`, `cmake`, `cmake-doc`, `cmake-data`, `cmake-rpm`, `doxygen`, `clang`, `clang-tools-extra`, `procps-ng`, `coreutils`, `findutils`, `which`, `python3`, `fedora-packager`.

## Required Tools
- `g++` or `clang++` (Compiler/Linker)
- `make` (Orchestrator)
- `ar` (Archiver)
- `nm` (Symbol Analysis)
- `readelf` (Binary Analysis)
- `python3` (Recovery Scripts)
- `fedora-packager` (Packaging)

**Containerized Build Environment**:
- **Base Image**: `fedora:44`.
- **Toolchain Installation**: Use `dnf` to install the following packages:
    - GNU: `gcc`, `gcc-c++`, `binutils`, `make`.
    - Build & Docs: `cmake`, `cmake-doc`, `cmake-data`, `cmake-rpm`, `doxygen`.
    - LLVM/Clang: `clang`, `clang-tools-extra (for clang-tidy and clang-format).`
    - Utilities: `procps-ng`, `coreutils`, `findutils`, `which`, `file`, `patchelf`, `vim`, `strace`, `emacs-nox`, `python3`, `fedora-packager`.
- **Container Path**: Use `src/fedora/cpp/containers/Dockerfile`.
- **Cleanup**: The `Makefile` MUST implement a `clean` rule that removes the `build/` and `lib/` directories, all object files (`*.o`), and all backup files (`*~`, `#*#`).

## Host-Target Compatibility
Build and test prompts may only be executed under the following conditions:
- **macOS host**: The target OS MUST be macOS. No container support is available for macOS — builds must run natively.
- **Linux host**: If the host distro does not match the target distro (e.g., Fedora build run from macOS or Ubuntu host), a container matching the target OS MUST be used. The Makefile's container-build override handles this automatically: `UNAME_S=macOS` ⇒ `container` command; non-matching Linux distro ⇒ `podman`. When the host already matches the target (e.g., Fedora build on Fedora), native execution is permitted.

## Container Lifecycle Automation
To simplify environment setup, the `Makefile` MUST implement a `container` target.

### Container Target Checklist
The `container` target MUST satisfy these four conditions:
1. [ ] **Host Detection**: Use `uname -s` to select `container` for macOS and `podman` for Linux.
2. [ ] **Existence Check**: Use `image ls | grep` to check for the image before calling `build`.
3. [ ] **Image Naming**: Use the pattern `ringbuffer_[platform]_build`.
4. [ ] **Cleanup**: Provide a `container-clean` target that removes the image.

The `container` target must perform the following logic:

1. **Host-Aware Tooling**: The target must detect the host operating system to select the correct container runtime:
    - **macOS**: Use the `container` command.
    - **Linux (Debian, Fedora, etc.)**: Use the `podman` command.
2. **Image State Management**:
    - **Check Existence**: Verify if the image `ringbuffer_fedora_build` already exists.
    - **Create**: If the image does not exist, create it using the `Dockerfile` located at `src/fedora/cpp/containers/Dockerfile`.
    - **Update**: If the image exists, rebuild/update it to ensure it is in sync with the current `Dockerfile` specification.
3. **Image Cleanup**:
    - A separate `Makefile` target (e.g., `container-clean`) MUST be implemented to remove the `ringbuffer_fedora_build` image from the host system.
    - The `dist-clean` target MUST call this container cleanup rule and remove the `../reports` and `cpp/logs` directories to ensure a complete environment reset.
4. **Documentation**: This automation logic (including host detection, the `make container` trigger, and the cleanup process) MUST be clearly documented in the project's `README.md` files, providing explicit instructions on how the user can set up and tear down their build environment.

- All code is covered under a BSD 3-Clause License.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
