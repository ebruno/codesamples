# Build Requirements - Ringbuffer (Debian 13, C++)

**Implementation Directive:**
This build specification MUST follow the common build specification exactly to ensure binary symmetry. 

Refer to the following document for all shared requirements, flags, and process:
[ringbuffer/prompts/common/cpp/build.md](../../common/cpp/build.md)

**Platform Specifics:**
- **Target Environment**: Debian 13, Linux kernel 6.12 LTS.
- **Prerequisites**: Install the following packages via `apt-get`:
    - `build-essential`, `cmake`, `cmake-data`, `cmake-doc`, `dh-cmake`, `debhelper`, `devscripts`, `doxygen`, `clang`, `clang-tidy`, `clang-format`, `procps`, `coreutils`, `findutils`, `which`, `python3`.

## Required Tools
- `g++` or `clang++` (Compiler/Linker)
- `make` (Orchestrator)
- `ar` (Archiver)
- `nm` (Symbol Analysis)
- `readelf` (Binary Analysis)
- `python3` (Recovery Scripts)

**Containerized Build Environment**:
- **Base Image**: `debian:13`.
- **Toolchain Installation**: Use `apt-get` to install the following packages:
    - GNU: `gcc`, `g++`, `binutils`, `make`.
    - Build & Docs: `cmake`, `cmake-data`, `cmake-doc`, `dh-cmake`, `debhelper`, `devscripts`, `doxygen`.
    - LLVM/Clang: `clang`, `clang-tidy`, `clang-format`.
    - Utilities: `procps`, `coreutils`, `findutils`, `which`, `file`, `patchelf`, `vim`, `strace`, `emacs-nox`, `python3`.
- **Container Path**: Use `src/debian/cpp/containers/Dockerfile`.
- **Cleanup**: The `Makefile` MUST implement a `clean` rule that removes the `build/` and `lib/` directories, all object files (`*.o`), and all backup files (`*~`, `#*#`).

## Host-Target Compatibility
Build and test prompts may only be executed under the following conditions:
- **macOS host**: The target OS MUST be macOS. No container support is available for macOS — builds must run natively.
- **Linux host**: If the host distro does not match the target distro (e.g., Debian build run from macOS or Fedora host), a container matching the target OS MUST be used. The Makefile's container-build override handles this automatically: `UNAME_S=macOS` ⇒ `container` command; non-matching Linux distro ⇒ `podman`. When the host already matches the target (e.g., Debian build on Debian), native execution is permitted.

## Container Runtime Pre-flight (macOS Host)
When the host OS is macOS and the target OS is Debian, the `container` command MUST be available in PATH before any container operations proceed.
- **Verification**: Execute `command -v container` to confirm availability.
- **Error Handling**: If `container` is NOT found, STOP and display:
  ```
  ERROR: The 'container' command is required for cross-OS builds from macOS to Linux targets, but it was not found in PATH.
  
  Please install Apple Container from: https://github.com/apple/container
  
  After installation, ensure the 'container' command is available in your PATH and re-run the build workflow.
  ```

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
    - **Check Existence**: Verify if the image `ringbuffer_debian_build` already exists.
    - **Create**: If the image does not exist, create it using the `Dockerfile` located at `src/debian/cpp/containers/Dockerfile`.
    - **Update**: If the image exists, rebuild/update it to ensure it is in sync with the current `Dockerfile` specification.
3. **Image Cleanup**:
    - A separate `Makefile` target (e.g., `container-clean`) MUST be implemented to remove the `ringbuffer_debian_build` image from the host system.
    - The `dist-clean` target MUST call this container cleanup rule and remove the `../reports` and `cpp/logs` directories to ensure a complete environment reset.
4. **Documentation**: This automation logic (including host detection, the `make container` trigger, and the cleanup process) MUST be clearly documented in the project's `README.md` files, providing explicit instructions on how the user can set up and tear down their build environment.

- All code is covered under a BSD 3-Clause License.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
