**Default Image:** N/A (macOS is native-only; no container image is used)

Please implement the full regression test suite for the Ringbuffer on macOS.

**Directives:**
1. Use `ringbuffer/prompts/macos/cpp/testing.md` for platform-specific prerequisites.
2. Use `ringbuffer/prompts/common/cpp/testing.md` as the primary testing specification.

**Immediate Requirements:**
- **Logging:** Every build step, configuration change, and verification result MUST be recorded in `ringbuffer/src/macos/cpp/logs/build.log`.
- **Configuration:** Create the test configuration (Makefile) in `ringbuffer/src/macos/cpp/tests/`.
- **Documentation:** Create the `tests/` directory structure with all required subdirectories and `.required_directory` markers.
- **Versioning:** The build system MUST source `version.mk` to generate the versioned artifact names.
- **Artifacts:**
    - Deploy test binaries (`test001_staticlib`, `test001_dynamiclib`) to the `tests/bin/` subdirectory.
    - Generate test data files (`test001.txt` through `test007.txt`) in `tests/data/inputs/`.
    - Generate expected output files in `tests/data/expected/`.
- **Optimization:** Ensure `-flto`, `-fvisibility=hidden`, `-ffunction-sections`, `-fdata-sections`, and `-dead_strip` are applied to achieve the "small binary" goal.
- **Scripting:** All utility scripts MUST be written in **Pure Zsh** (version 5.8+) and MUST include a version check at the start. Avoid external tools in favor of shell built-ins.
- **Makefile Consistency:** The generated test Makefile MUST follow the common testing specification exactly, with only the allowed platform-specific differences (toolchain flags, binary format). Do not compare against or copy from any other platform's test Makefile.

**Native-Only Constraint:**
macOS builds and tests run natively on the host. Containers are prohibited — there is no Dockerfile, no container image, and no `container` target for macOS. The Makefile's `container` target MUST be a no-op that prints: `"Container not used for macOS native build"`.

**Environment Initialization:**
After creating the test configuration, you MUST execute `make container` from the tests directory. This step verifies that:
1. The host OS is correctly detected as macOS.
2. The `container` target executes without error (no-op for native builds).
3. The build environment is fully operational and ready for subsequent test execution steps.

**Verification Criteria:**
Before finishing, you MUST verify and log the following:
1. **Architecture:** Use `lipo -info` on both `.a` and `.dylib` files to confirm they are Universal Binaries (arm64 and x86_64).
2. **Install Name:** Use `otool -L` on the shared library to confirm the install name is `@rpath/libswtr_ringbuffer.dylib`.
3. **Binary Size:** Use `size -m` to verify the effectiveness of dead code elimination.
4. **Cleanliness:** Verify that the `clean` target removes `build/`, `lib/`, and backup files using the `$(RM)` macro.
5. **Test Data Validation:** Run `verify_test_data.zsh` and confirm all seven test files pass validation.
6. **Test Matrix:** All 7 tests (T001–T007) execute with correct exit codes and produce expected output.

**Tooling and Recovery:**
- **Invalid Filenames:** If you encounter files or directories with trailing characters after valid extensions (e.g., `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors:** If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.