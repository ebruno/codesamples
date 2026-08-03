# Build Requirements - Ringbuffer (Debian 13, C++)

**Implementation Directive:**
This build specification MUST follow the common build specification exactly to ensure binary symmetry. 

Refer to the following document for all shared requirements, flags, and process:
[ringbuffer/prompts/common/cpp/build.md](../../common/cpp/build.md)

**Platform Specifics:**
- **Target Environment**: Debian 13, Linux kernel 6.12 LTS.
- **Prerequisites**: Install the following packages via `apt-get`:
    - `build-essential`, `cmake`, `doxygen`, `clang`, `clang-tidy`, `clang-format`, `procps`, `coreutils`, `findutils`, `which`.
<EOF>
