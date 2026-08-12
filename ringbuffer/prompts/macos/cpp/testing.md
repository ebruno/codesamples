# Testing Requirements - Ringbuffer (macOS, C++)

**Implementation Directive:**
This testing specification MUST follow the common testing specification exactly to ensure identical validation across platforms.

Refer to the following document for all shared requirements, data generation, and test matrices:
[ringbuffer/prompts/common/cpp/testing.md](../../common/cpp/testing.md)

Refer to [ringbuffer/prompts/common/cpp/testing.md](../../common/cpp/testing.md) for the Platform and Container Runtime Reference before planning any test operation.

**Platform Specifics:**
- **Host Verification**: Build and test prompts may only be executed if the generating host is macOS and the target OS is macOS. Verify the host OS using the `sw_vers --productName` command (must return "macOS").
- **No Container Support**: macOS builds and tests run natively on a macOS host. There is no container target for the macOS Makefile — do not attempt to use containers or cross-compile. The `sw_vers --productName` check above enforces this constraint.
- **Docker Prohibition**: Docker (`docker`) MUST NOT be used on macOS under any circumstances. The `container` command is the only supported container runtime for macOS, and even that is prohibited — all macOS builds and tests must run natively.
- **Toolchain Verification**: Verify the toolchain by executing `clang++ --version` and `make --version` to ensure all required build tools are present and operational.
- **Audit Trail**: The `verify` target MUST log the exact versions of the compiler and linker (e.g., `clang++ -v` and `ld -v`) into the final `regression_report.md` to provide a baseline for binary size analysis.
- **Timing Mechanism**: In the `tests/Makefile`, use `date +%s` for capturing start and end times. The macOS `date` utility does not support nanosecond precision (`%N`).

- **Artifact Verification**:
    - **Architecture**: Use `lipo -info <artifact>` to verify that both `arm64` and `x86_64` slices are present.
    - **Install Name**: Use `otool -L <dylib>` to verify that the install name is set to `@rpath/libswtr_ringbuffer.dylib`.
- **Header Search Path**: Use `ringbuffer/src/macos/cpp`.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.