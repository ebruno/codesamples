# Build Requirements - Ringbuffer (Arch Linux, C++)

**Implementation Directive:**
This build specification MUST follow the common build specification exactly to ensure binary symmetry. 

Refer to the following document for all shared requirements, flags, and process:
[prompts/common/cpp/build.md](../../common/cpp/build.md)

Refer to [prompts/common/cpp/build.md](../../common/cpp/build.md) for the Platform and Container Runtime Reference before planning any build operation.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/cpp/build.md`) conflict with common specs (`prompts/common/cpp/build.md`), the platform-specific spec takes precedence for toolchain, binary format, and environment details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

**Platform Specifics:**
- **Target Environment**: Arch Linux (rolling release)
- **Prerequisites**: Install the following packages via `pacman`:
    - `base-devel` (includes gcc, make, binutils)
    - `clang`
    - `cmake`
    - `doxygen`
    - `patchelf`
    - `strace`
    - `python3`

## Required Tools
- `g++` or `clang++` (Compiler/Linker)
- `make` (Orchestrator)
- `ar` (Archiver)
- `nm` (Symbol Analysis)
- `readelf` (Binary Analysis)
- `python3` (Recovery Scripts)

**Containerized Build Environment**:
- **Base Image**: `archlinux:YYYY.MM.DD` (datestamp tag from 3 months ago)
- **Toolchain Installation**: Use `pacman -S --noconfirm` to install the following packages:
    - Base build tools: `base-devel` (provides gcc, make, binutils)
    - Build & Docs: `cmake`, `doxygen`
    - LLVM/Clang: `clang`
    - Utilities: `patchelf`, `strace`, `python3`
- **Container Path**: Use `src/archlinux/cpp/containers/Dockerfile`.
- **Cleanup**: The `Makefile` MUST implement a `clean` rule that removes the `build/` and `lib/` directories, all object files (`*.o`), and all backup files (`*~`, `#*#`).

**Host-Target Compatibility** and **Container Runtime Pre-flight**: See `prompts/common/cpp/build.md` for the authoritative host-target and container runtime directives.

## macOS Skip Logic
Arch Linux container images are amd64-only. On Apple Silicon (M-series) Macs, there is no ARM64 Arch Linux container available. The `container` target in the Makefile MUST detect macOS and skip gracefully:

```makefile
# In the container target, add this check BEFORE any container commands:
ifeq ($(UNAME_S),Darwin)
    @echo "[archlinux] Skipping container build on macOS — Arch Linux containers are amd64-only."
    @echo "[archlinux] Source code generation is supported; build/test requires a Linux host."
    @exit 0
endif
```

When running on macOS, the script MUST log to `build.log`:
```
[timestamp] Arch Linux container build skipped on macOS (Apple Silicon) — no ARM64 container available.
[timestamp] Source code generation is supported; build/test requires a Linux host with podman/docker.
```

## Container Lifecycle Automation
To simplify environment setup, the `Makefile` MUST implement a `container` target.

### Container Target Checklist
The `container` target MUST satisfy these five conditions:
0. [ ] **macOS Skip Check**: Before any container operation, check if the host is macOS (`uname -s`). If Darwin, log the skip message to `build.log` and exit successfully (do NOT attempt container operations).
1. [ ] **Host Detection**: Use `uname -s` to select `container` for macOS and `podman` for Linux.
2. [ ] **Existence Check**: Use `image ls --quiet | grep` to check for the image before calling `build`.
3. [ ] **Image Naming**: Use the pattern `ringbuffer_archlinux_build`.
4. [ ] **Cleanup**: Provide a `container-clean` target that removes the image.

The `container` target must perform the following logic:
- On **Linux hosts**: Build the Arch Linux container image using `podman build` from `src/archlinux/cpp/containers/Dockerfile`. The container image is named `ringbuffer_archlinux_build` and uses the Arch Linux base image with datestamp tag (e.g., `archlinux:2026.05.31`).
- On **macOS hosts**: Skip container build with a logged message (see macOS Skip Logic above).

### Dockerfile Requirements
The `Dockerfile` at `src/archlinux/cpp/containers/Dockerfile` MUST:
1. Use an Arch Linux base image with a datestamp tag (e.g., `FROM archlinux:2026.05.31`)
2. Install build dependencies via `pacman -S --noconfirm` (not `dnf` or `apt-get`)
3. Set `WORKDIR /app` to align with the host volume mounts and execution workflow

### macOS Skip in Dockerfile
The Dockerfile does NOT need modification for macOS — the skip logic is handled at the Makefile level. The Dockerfile is only used on Linux hosts where `podman` can run amd64 containers natively.
