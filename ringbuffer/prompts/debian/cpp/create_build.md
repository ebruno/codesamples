**Temporary Workspace**: See `ringbuffer/prompts/common/cpp/build.md` for the authoritative temporary workspace directives.

Please configure the build system for the Ringbuffer on Debian.

**Directives:**
1. Use `ringbuffer/prompts/debian/cpp/build.md` for platform-specific prerequisites.
2. Use `ringbuffer/prompts/common/cpp/build.md` as the primary build specification.

**Immediate Requirements:**
- **Logging:** Every build step, configuration change, and verification result MUST be recorded in `ringbuffer/src/debian/cpp/logs/build.log`.
- **Configuration**: Create the build configuration (e.g., Makefile or CMakeLists.txt) in `ringbuffer/src/debian/cpp`.
- **Documentation**: Create the `specs/` subdirectory with:
  - `build.md`: Copy of `ringbuffer/prompts/debian/cpp/build.md`
  - `testing_requirements.md`: Copy of `ringbuffer/prompts/debian/cpp/testing.md` (NOT named `testing.md`)
  - `artifacts.md`: Create with the standard library artifacts table:
    ```markdown
    # Build Artifacts — Debian

    ## Library Artifacts
    | Artifact | Path | Description |
    |----------|------|-------------|
    | Static Library | `lib/libswtr_ringbuffer-<MAJOR>.<MINOR>.<SUBVERSION>-<BUILD_ID>.a` | Static archive built with `ar` |
    | Shared Library | `lib/libswtr_ringbuffer-<MAJOR>.<MINOR>.<SUBVERSION>-<BUILD_ID>.so` | Shared object built with `-shared` |
    | Static Link | `lib/libswtr_ringbuffer.a` → versioned static library | Relative symlink for linking |
    | Shared Link | `lib/libswtr_ringbuffer.so` → versioned shared library | Relative symlink for linking |
    ```
- **Versioning**: The build system MUST source `version.mk` to generate the versioned artifact names.
- **Artifacts:** 
    - Deploy libraries to the `lib/` subdirectory.
    - Create relative symbolic links from unversioned names to versioned artifacts within the `lib/` directory.
- **Optimization**: Ensure `-flto`, `-fvisibility=hidden`, `-ffunction-sections`, `-fdata-sections`, and `-Wl,--gc-sections` are applied to achieve the "small binary" goal.
- **Scripting**: All utility scripts MUST be written in **Pure Bash** (version 5.0+) and MUST include a version check at the start. Avoid external tools in favor of shell built-ins.
- **Makefile Consistency:** The generated `Makefile` MUST be created independently from `ringbuffer/prompts/common/cpp/build.md` and the platform-specific build spec. Do NOT copy Makefiles from other platforms.

**Dockerfile Handling**:
Before creating the Dockerfile, check if `.dockerfile_created_by_step0` exists (created by `implement_build.md` Step 0). If it does, **augment** the existing Dockerfile by adding platform-specific package installations — do NOT rewrite or replace it. Read its first line (`FROM ...`) and use that as the base image for any package additions.

**Environment Initialization**:
After creating the build configuration and ensuring the Dockerfile at `src/debian/cpp/containers/Dockerfile` is in place, you MUST execute `make container` from the source directory. This step verifies that:
1. The host OS is correctly detected.
2. The build image (`ringbuffer_debian_build`) is successfully created or updated.
3. The container environment is fully operational and ready for subsequent compilation steps.

**Verification Criteria:**
Before finishing, you MUST verify and log the following:
1. **Architecture**: Use the `file` command on both `.a` and `.so` files.
2. **SONAME**: Use `readelf -d` on the shared library to confirm the SONAME is `libswtr_ringbuffer.so`.
3. **Binary Size**: Use `size` to verify the effectiveness of dead code elimination. Parse the total column for the byte count.
4. **Cleanliness**: Verify that the `clean` target removes `build/`, `lib/`, and backup files using the `$(RM)` macro.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
