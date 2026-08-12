**Temporary Workspace**: See `ringbuffer/prompts/common/cpp/testing.md` for the authoritative temporary workspace directives.

**Default Image**: `ubuntu:24.04`

**Workflow Precedence:** This file is the **PRIMARY** execution document. The common workflow (`ringbuffer/prompts/common/implement_regression.md`) provides image resolution and structure reference only.

Please implement the full regression test suite for the Ringbuffer on Ubuntu 24.04 LTS (Linux kernel 6.N).

**Directives:**
1. Use `ringbuffer/prompts/ubuntu/cpp/testing.md` for platform-specific prerequisites.
2. Use `ringbuffer/prompts/common/cpp/testing.md` as the primary testing specification.

**Immediate Requirements:**
- **Logging:** Every build step, configuration change, and verification result MUST be recorded in `ringbuffer/src/ubuntu/cpp/logs/build.log`.
- **Configuration**: Create the test configuration (Makefile) in `ringbuffer/src/ubuntu/cpp/tests/`.
- **Documentation**: Create the `tests/` directory structure with all required subdirectories and `.required_directory` markers.
- **Versioning**: The build system MUST source `version.mk` to generate the versioned artifact names.
- **Artifacts:** 
    - Deploy test binaries (`test001_staticlib`, `test001_dynamiclib`) to the `tests/bin/` subdirectory.
    - Generate test data files (`test001.txt` through `test007.txt`) in `tests/data/inputs/`.
    - Generate expected output files in `tests/data/expected/`.
- **Optimization**: Ensure `-flto`, `-fvisibility=hidden`, `-ffunction-sections`, `-fdata-sections`, and `-Wl,--gc-sections` are applied to achieve the "small binary" goal.
- **Scripting:** All utility scripts MUST be written in **Pure Bash** (version 5.0+) and MUST include a version check at the start. Avoid external tools in favor of shell built-ins.
- **Makefile Generation:** Generate the test Makefile independently from `ringbuffer/prompts/common/cpp/testing.md` and `ringbuffer/prompts/ubuntu/cpp/testing.md`. Do NOT copy the test Makefile from another platform. Log: `[timestamp] Independent test Makefile generation — no test Makefile copied from other platforms.`

**Dockerfile Handling**:
Before creating the Dockerfile, check if `.dockerfile_created_by_step0` exists (created by `implement_regression.md` Step 0). If it does, **augment** the existing Dockerfile by adding platform-specific package installations — do NOT rewrite or replace it. Read its first line (`FROM ...`) and use that as the base image for any package additions.

**macOS Service Pre-Check**: When generating the `container:` target in the test Makefile, include a macOS service pre-check before any container commands. If `UNAME_S` is Darwin, check if the Apple Container daemon is running with `$(CONTAINER_CMD) system status`. If not running, start it with `$(CONTAINER_CMD) system start` before proceeding. This ensures `make container` works when invoked directly from a macOS host where the daemon may not be running.

**Environment Initialization**:
After creating the test configuration and ensuring the Dockerfile at `tests/containers/ubuntu/Dockerfile` is in place, you MUST execute `make container` from the tests directory. This step verifies that:
1. The host OS is correctly detected.
2. The test image (`ringbuffer_ubuntu_test`) is successfully created or updated.
3. The container environment is fully operational and ready for subsequent test execution steps.

**Verification Criteria:**
Before finishing, you MUST verify and log the following:
1. **Architecture**: Use the `file` command on both `.a` and `.so` files.
2. **SONAME**: Use `readelf -d` on the shared library to confirm the SONAME is `libswtr_ringbuffer.so`.
3. **Binary Size**: Use `size` to verify the effectiveness of dead code elimination. Parse the total column for the byte count.
4. **Cleanliness**: Verify that the `clean` target removes `build/`, `lib/`, and backup files using the `$(RM)` macro.
5. **Test Data Validation**: Run `verify_test_data.sh` and confirm all seven test files pass validation.
6. **Test Matrix**: All 7 tests (T001–T007) execute with correct exit codes and produce expected output.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `ErrorOps.cpp`, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
