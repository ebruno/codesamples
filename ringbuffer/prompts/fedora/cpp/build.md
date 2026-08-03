# Build Requirements - Ringbuffer (Fedora 44, C++)

**Implementation Directive:**
This build specification MUST follow the common build specification exactly to ensure binary symmetry. 

Refer to the following document for all shared requirements, flags, and process:
[ringbuffer/prompts/common/cpp/build.md](../../common/cpp/build.md)

**Platform Specifics:**
- **Target Environment**: Fedora 44, Kernel 7.1.5-200.fc44.
- **Prerequisites**: Install the following packages via `dnf`:
    - `gcc`, `gcc-c++`, `binutils`, `make`, `cmake`, `doxygen`, `clang`, `clang-tools-extra`, `procps-ng`, `coreutils`, `findutils`, `which`.
<EOF>
