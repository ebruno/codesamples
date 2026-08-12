**Temporary Workspace**: See `ringbuffer/prompts/common/cpp/build.md` for the authoritative temporary workspace directives.

**Workflow Precedence:** This file is the **PRIMARY** execution document. The common workflow (`ringbuffer/prompts/common/implement_build.md`) provides image resolution and structure reference only.

Please configure the build system for the Ringbuffer on macOS.

**Directives:**
1. Use `ringbuffer/prompts/macos/cpp/build.md` for platform-specific requirements and Universal Binary specifications.
2. Use `ringbuffer/prompts/common/cpp/build.md` as the primary build specification.

**Immediate Requirements:**
- **Host Verification**: Before proceeding, verify that the host operating system is macOS by executing `sw_vers --productName`.
- **Logging:** Every build step, configuration change, and verification result MUST be recorded in `ringbuffer/src/macos/cpp/logs/build.log`.
- **Configuration**: Create the build configuration (e.g., Makefile or CMakeLists.txt) in `ringbuffer/src/macos/cpp`.
- **Documentation**: Create the `specs/` subdirectory and place `build.md`, `testing_requirements.md`, and `artifacts.md` files within it.
- **Versioning**: The build system MUST source `version.mk` to generate the versioned artifact names.
- **Artifacts:** 
    - Deploy libraries to the `lib/` subdirectory.
    - Create relative symbolic links from unversioned names to versioned artifacts within the `lib/` directory.
- **Optimization**: Ensure `-flto`, `-fvisibility=hidden`, `-ffunction-sections`, `-fdata-sections`, and `-dead_strip` are applied to achieve the "small binary" goal.
- **Toolchain**: Use Clang by default.
- **Makefile Consistency:** The generated `Makefile` MUST follow the common build specification exactly, with only the allowed platform-specific differences (`CONTAINER_IMAGE`, working directory path, host distro check). Do not compare against or copy from any other platform's Makefile.
- **State Tracking:** Upon completion, create a `.gen_state.json` file in `ringbuffer/src/macos/cpp/` containing the resolved version, resolved image (N/A for native-only), SHA-256 hashes of `common/cpp/build.md` and `macos/cpp/build.md`, SHA-256 hashes of all generated build artifacts (Makefile, specs files), and file fingerprints for all source files.

**Dockerfile Handling**: macOS builds are native-only and do not use Dockerfiles. If a minimal Dockerfile was created by `implement_build.md` Step 0 (marker file `.dockerfile_created_by_step0` exists), it MUST NOT be modified or augmented — macOS has no container support. Log: `[timestamp] Dockerfile handling skipped — macOS is a native-only platform.`

**Verification Criteria:**
Before finishing, you MUST verify and log the following:
1. **Architecture**: Use `lipo -info` on both `.a` and `.dylib` files to confirm they are Universal Binaries (arm64 and x86_64).
2. **Install Name**: Use `otool -L` on the shared library to confirm the install name is `@rpath/libswtr_ringbuffer.dylib`.
3. **Binary Size**: Use `size -m` to verify the effectiveness of dead code elimination.
4. **Cleanliness**: Verify that the `clean` target removes `build/`, `lib/`, and backup files using the `$(RM)` macro.
5. **`dist-clean` Behavior**: The `dist-clean` target MUST include a conditional check for the `tests/` directory. If `tests/` exists, it MUST execute `make -C tests dist-clean`. Verify this by inspecting the Makefile source.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `ErrorOps.cpp`), use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

**Reporting:**
Once implementation is complete, generate a summary report at `ringbuffer/src/macos/cpp/reports/build_creation_report.md`:

# Build Creation Report - macOS
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Target Image:** N/A (native-only platform)
**Ringbuffer Version:** <resolved_version from shared context>
**Start Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**End Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Elapsed Time:** [Duration]

## Status
**Build System Created:** [Yes/No]
**Container Image Built:** N/A (macOS is native-only)
**Library Build Successful:** [Yes/No]
**Self-Audit Passed:** [Yes/No]

## Artifacts Created
- **Makefile**: `ringbuffer/src/macos/cpp/Makefile`
- **Dockerfile**: N/A (macOS is native-only)
- **Specs**: `specs/build.md`, `specs/testing_requirements.md`, `specs/artifacts.md`
- **Library Artifacts**: [List of `.a` and `.dylib` files in `lib/`]
- **Logs**: `build.log` created and updated.

## Self-Audit Results
- **Makefile Targets**: [PASS/FAIL] — `all`, `static`, `shared`, `clean`, `dist-clean`
- **Dockerfile**: N/A (macOS is native-only)
- **Specs Directory**: [PASS/FAIL] — `build.md`, `testing_requirements.md`, `artifacts.md` present
- **Source Consistency**: [PASS/FAIL] — all `.cpp` files in `SRCS`
- **Artifact Verification**: [PASS/FAIL] — architecture (Mach-O/universal), install name, symlinks

## Fixes and Modifications
<details>
<summary>Click to expand</summary>

[List any fixes or modifications applied during build creation]

</details>
