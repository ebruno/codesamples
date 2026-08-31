# Functional Requirements - Ringbuffer (Arch Linux, C++)

**Implementation Directive:**
This implementation MUST follow the common functional specification exactly to ensure cross-platform symmetry. 
Refer to the common specification for all architectural, interface, and implementation details:
[prompts/common/cpp/functional.md](../../common/cpp/functional.md)

**Platform Specifics:**
- **Target OS**: Arch Linux (rolling release — no point-release version)
- **glibc**: Latest available from Arch repositories
- **Toolchains**: Clang and GCC (latest versions from rolling repos)
- **License**: BSD 3-Clause License. The `LICENSE` file must be created in `src/archlinux/cpp` with the standard BSD 3-Clause text.

**Rolling Release Note:** Arch Linux is a rolling-release distribution. Package versions (including glibc, GCC, Clang) are always the latest available from upstream. This means:
- No need to target specific glibc versions — always use the latest available
- Compiler versions are typically newer than point-release distros (GCC 14+, Clang 18+)
- No `VERSION_ID` in `/etc/os-release`; identify by `ID=arch`

**macOS Limitation:** Arch Linux container images are amd64-only. On Apple Silicon (M-series) Macs, there is no ARM64 Arch Linux container available. When running on macOS:
- The build/test workflow will be **skipped** with a logged message
- Source code generation is still supported (it does not require containers)
- Build and test must be performed on a Linux host with `podman` or `docker`

**Tooling and Recovery:** See `prompts/common/cpp/functional.md` for the authoritative tooling and recovery directives.
