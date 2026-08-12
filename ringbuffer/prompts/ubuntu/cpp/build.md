# Build Requirements - Ringbuffer (Ubuntu 24.04 LTS, C++)

**Implementation Directive:**
This build specification MUST follow the common build specification exactly to ensure binary symmetry. 

Refer to the following document for all shared requirements, flags, and process:
[prompts/common/cpp/build.md](../../common/cpp/build.md)

Refer to [prompts/common/cpp/build.md](../../common/cpp/build.md) for the Platform and Container Runtime Reference before planning any build operation.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/cpp/build.md`) conflict with common specs (`prompts/common/cpp/build.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

**Platform Specifics:**
- **Target Environment**: Ubuntu 24.04 LTS, Linux kernel 6.N.
- **glibc**: Version 2.39+. The library must be compatible with glibc 2.39+.
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
- **Base Image**: `ubuntu:24.04`.
- **Toolchain Installation**: Use `apt-get` to install the following packages:
    - GNU: `gcc`, `g++`, `binutils`, `make`.
    - Build & Docs: `cmake`, `cmake-data`, `cmake-doc`, `dh-cmake`, `debhelper`, `devscripts`, `doxygen`.
    - LLVM/Clang: `clang`, `clang-tidy`, `clang-format`.
    - Utilities: `procps`, `coreutils`, `findutils`, `which`, `file`, `patchelf`, `vim`, `strace`, `emacs-nox`, `python3`.
- **Container Path**: Use `src/ubuntu/cpp/containers/Dockerfile`.
- **Cleanup**: The `Makefile` MUST implement a `clean` rule that removes the `build/` and `lib/` directories, all object files (`*.o`), and all backup files (`*~`, `#*#`).

**Host-Target Compatibility** and **Container Runtime Pre-flight**: See `prompts/common/cpp/build.md` for the authoritative host-target and container runtime directives.

## Container Lifecycle Automation
To simplify environment setup, the `Makefile` MUST implement a `container` target.

### Container Target Checklist
The `container` target MUST satisfy these five conditions:
0. [ ] **Service Pre-flight**: Before any container operation, verify the runtime service is running. On macOS (`container` command), run `container system status 2>/dev/null | grep -q "status.*running"`; if it fails, start the service with `container system start` and wait up to 5 seconds. On Linux (`podman`), verify with `podman info >/dev/null 2>&1`. If the service cannot be started, STOP and report.
1. [ ] **Host Detection**: Use `uname -s` to select `container` for macOS and `podman` for Linux.
2. [ ] **Existence Check**: Use `image ls --quiet | grep` to check for the image before calling `build`.
3. [ ] **Image Naming**: Use the pattern `ringbuffer_[platform]_build`.
4. [ ] **Cleanup**: Provide a `container-clean` target that removes the image.

The `container` target must perform the following logic:

1. **Host-Aware Tooling**: The target must detect the host operating system to select the correct container runtime:
    - **macOS**: Use the `container` command.
    - **Linux (Debian, Fedora, Ubuntu, etc.)**: Use the `podman` command.
2. **Image State Management**:
    - **Check Existence**: Verify if the image `ringbuffer_ubuntu_build` already exists.
    - **Create**: If the image does not exist, create it using the `Dockerfile` located at `src/ubuntu/cpp/containers/Dockerfile`.
    - **Update**: If the image exists, rebuild/update it to ensure it is in sync with the current `Dockerfile` specification.
3. **Image Cleanup**:
    - A separate `Makefile` target (e.g., `container-clean`) MUST be implemented to remove the `ringbuffer_ubuntu_build` image from the host system.
    - The `dist-clean` target MUST call this container cleanup rule and remove the `../reports` and `cpp/logs` directories to ensure a complete environment reset.
4. **Documentation**: This automation logic (including host detection, the `make container` trigger, and the cleanup process) MUST be clearly documented in the project's `README.md` files, providing explicit instructions on how the user can set up and tear down their build environment.

## Scope Boundary — Build Phase Only
The purpose of this prompt is to compile the library and produce artifacts in `./lib/`. **Your task ends once both static (`.a`) and shared (`.so`) library artifacts exist with correct symlinks.**

You MUST NOT:
- Run `make verify` or `make -C tests`
- Generate test data, compile test binaries, or execute any tests
- Invoke `regression_test_execution.md` or any testing workflow
- Proceed to verification, reporting, or test matrix execution

If the user wants testing, they will issue a separate request. Do not assume testing is part of a build request.

## Container Build Failure Handling
If the `make container` target fails during image creation or update:

1. **Report**: Display the full error output from the failed container build command.
2. **Diagnose** using these common failure modes:
   - **Dockerfile errors**: Syntax errors, missing base image, failed `RUN` commands. Check the Dockerfile at `src/<os>/cpp/containers/Dockerfile`.
   - **Package installation failures**: Package names may have changed in newer base images. Verify package availability with `dnf list <package>` (Fedora) or `apt-cache search <package>` (Debian/Ubuntu).
   - **Network issues**: Base image pull failures. Retry or configure a mirror registry.
3. **Fix and retry** at most **2 times**. If all retries fail, STOP and report the final error. Do NOT proceed to build or test steps.

- All code is covered under a BSD 3-Clause License.

**Tooling and Recovery:** See `prompts/common/cpp/build.md` for the authoritative tooling and recovery directives.
