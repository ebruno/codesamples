**Temporary Workspace**: See `ringbuffer/prompts/common/cpp/build.md` for the authoritative temporary workspace directives.

**Workflow Precedence:** This file is the **PRIMARY** execution document. The common workflow (`ringbuffer/prompts/common/implement_build.md`) provides image resolution and structure reference only.

Please configure the build system for the Ringbuffer on Fedora.

**Directives:**
1. Use `ringbuffer/prompts/fedora/cpp/build.md` for platform-specific prerequisites.
2. Use `ringbuffer/prompts/common/cpp/build.md` as the primary build specification.

**Immediate Requirements:**
- **Logging:** Every build step, configuration change, and verification result MUST be recorded in `ringbuffer/src/fedora/cpp/logs/build.log`.
- **Configuration**: Create the build configuration (e.g., Makefile or CMakeLists.txt) in `ringbuffer/src/fedora/cpp`.
- **Documentation**: Create the `specs/` subdirectory and place `build.md`, `testing_requirements.md`, and `artifacts.md` files within it.
- **Versioning**: The build system MUST source `version.mk` to generate the versioned artifact names.
- **Artifacts:** 
    - Deploy libraries to the `lib/` subdirectory.
    - Create relative symbolic links from unversioned names to versioned artifacts within the `lib/` directory.
- **Optimization**: Ensure `-flto`, `-fvisibility=hidden`, `-ffunction-sections`, `-fdata-sections`, and `-Wl,--gc-sections` are applied to achieve the "small binary" goal.
- **Scripting**: All utility scripts MUST be written in **Pure Bash** (version 5.0+) and MUST include a version check at the start. Avoid external tools in favor of shell built-ins.
- **Makefile Consistency:** The generated `Makefile` MUST follow the common build specification exactly, with only the allowed platform-specific differences (`CONTAINER_IMAGE`, working directory path, host distro check). Do not compare against or copy from any other platform's Makefile.
- **State Tracking:** Upon completion, create a `.gen_state.json` file in `ringbuffer/src/fedora/cpp/` containing the resolved version, resolved image, SHA-256 hashes of `common/cpp/build.md` and `fedora/cpp/build.md`, SHA-256 hashes of all generated build artifacts (Makefile, Dockerfile, specs files), and file fingerprints for all source files.

**Dockerfile Handling**:
Before creating the Dockerfile, check if `.dockerfile_created_by_step0` exists (created by `implement_build.md` Step 0). If it does, **augment** the existing Dockerfile by adding platform-specific package installations — do NOT rewrite or replace it. Read its first line (`FROM ...`) and use that as the base image for any package additions.

**macOS Service Pre-Check**: When generating the `container:` target in the Makefile, include a macOS service pre-check before any container commands. If `UNAME_S` is Darwin, check if the Apple Container daemon is running with `$(CONTAINER_CMD) system status`. If not running, start it with `$(CONTAINER_CMD) system start` before proceeding. This ensures `make container` works when invoked directly from a macOS host where the daemon may not be running.

**Environment Initialization**:
After creating the build configuration and ensuring the Dockerfile at `src/fedora/cpp/containers/Dockerfile` is in place, you MUST execute `make container` from the source directory. This step verifies that:
1. The host OS is correctly detected.
2. The build image (`ringbuffer_fedora_build`) is successfully created or updated.
3. The container environment is fully operational and ready for subsequent compilation steps.

**Verification Criteria:**
Before finishing, you MUST verify and log the following:
1. **Architecture**: Use the `file` command on both `.a` and `.so` files.
2. **SONAME**: Use `readelf -d` on the shared library to confirm the SONAME is `libswtr_ringbuffer.so`.
3. **Binary Size**: Use `size` to verify the effectiveness of dead code elimination.
4. **Cleanliness**: Verify that the `clean` target removes `build/`, `lib/`, and backup files using the `$(RM)` macro.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `ErrorOps.cpp`, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

**Reporting:**
Once implementation is complete, generate a summary report at `ringbuffer/src/fedora/cpp/reports/build_creation_report.md`:

# Build Creation Report - Fedora
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Target Image:** <resolved_image>
**Ringbuffer Version:** <resolved_version from shared context>
**Start Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**End Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Elapsed Time:** [Duration]

## Status
**Build System Created:** [Yes/No]
**Container Image Built:** [Yes/No]
**Library Build Successful:** [Yes/No]
**Self-Audit Passed:** [Yes/No]

## Artifacts Created
- **Makefile**: `ringbuffer/src/fedora/cpp/Makefile`
- **Dockerfile**: `ringbuffer/src/fedora/cpp/containers/Dockerfile`
- **Specs**: `specs/build.md`, `specs/testing_requirements.md`, `specs/artifacts.md`
- **Library Artifacts**: [List of `.a` and `.so` files in `lib/`]
- **Logs**: `build.log` created and updated.

## Self-Audit Results
- **Makefile Targets**: [PASS/FAIL] — `all`, `static`, `shared`, `clean`, `dist-clean`, `container`
- **Dockerfile**: [PASS/FAIL] — base image, package installation
- **Specs Directory**: [PASS/FAIL] — `build.md`, `testing_requirements.md`, `artifacts.md` present
- **Source Consistency**: [PASS/FAIL] — all `.cpp` files in `SRCS`
- **Artifact Verification**: [PASS/FAIL] — architecture (ELF), SONAME, symlinks

## Fixes and Modifications
<details>
<summary>Click to expand</summary>

[List any fixes or modifications applied during build creation]

</details>
