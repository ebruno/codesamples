**Temporary Workspace**: See `ringbuffer/prompts/common/cpp/build.md` for the authoritative temporary workspace directives.

Please configure the build system for the Ringbuffer on Ubuntu 24.04 LTS (Linux kernel 6.N).

**Directives:**
1. Use `ringbuffer/prompts/ubuntu/cpp/build.md` for platform-specific prerequisites.
2. Use `ringbuffer/prompts/common/cpp/build.md` as the primary build specification.

**Immediate Requirements:**
- **Logging:** Every build step, configuration change, and verification result MUST be recorded in `ringbuffer/src/ubuntu/cpp/logs/build.log`.
- **Configuration**: Create the build configuration (e.g., Makefile or CMakeLists.txt) in `ringbuffer/src/ubuntu/cpp`.
- **Documentation**: Create the `specs/` subdirectory and place `build.md`, `testing.md`, and `artifacts.md` files within it.
- **Versioning**: The build system MUST source `version.mk` to generate the versioned artifact names.
- **Artifacts:** 
    - Deploy libraries to the `lib/` subdirectory.
    - Create relative symbolic links from unversioned names to versioned artifacts within the `lib/` directory.
- **Optimization**: Ensure `-flto`, `-fvisibility=hidden`, `-ffunction-sections`, `-fdata-sections`, and `-Wl,--gc-sections` are applied to achieve the "small binary" goal.
- **Scripting**: All utility scripts MUST be written in **Pure Bash** (version 5.0+) and MUST include a version check at the start. Avoid external tools in favor of shell built-ins.
- **Debian Source Availability Check:** Before generating the Makefile, check whether the Debian source directory exists:
  1. Verify that `ringbuffer/src/debian/cpp/` exists as a directory.
  2. If it does NOT exist, log: `[timestamp] Debian source directory missing — ringbuffer/src/debian/cpp/ not found. Ubuntu will generate independently.` and skip all comparison/copy steps.
  3. If it DOES exist, proceed to the Debian Readiness Check below.
- **Debian Build Readiness Check:** (Only if `ringbuffer/src/debian/cpp/` exists)
  1. Verify that `ringbuffer/src/debian/cpp/.gen_state.json` exists.
  2. Read the `spec_hashes` entries for `build.md` from that file.
  3. Compute the current SHA-256 hash of `ringbuffer/prompts/common/cpp/build.md` and compare it against the stored Debian hash.
  4. If the hashes match, log: `[timestamp] Debian build readiness check passed — Debian is built to current build specs. Ubuntu may copy from Debian.`
  5. If the hashes do NOT match or `.gen_state.json` is missing, log: `[timestamp] Debian build readiness check failed — Debian is NOT built to current build specs. Ubuntu will generate independently.`
- **Makefile Generation Path:** Based on the checks above:
  - **If Debian source exists AND is ready:** Copy `ringbuffer/src/debian/cpp/Makefile` to the Ubuntu source directory. Adjust only platform-specific values (`CONTAINER_IMAGE`, working directory path, host distro check). Log each adjustment.
  - **If Debian source is missing OR not ready:** Generate the Makefile independently from `ringbuffer/prompts/common/cpp/build.md` and `ringbuffer/prompts/ubuntu/cpp/build.md`. Do NOT copy the Makefile from another platform. Log: `[timestamp] Independent Makefile generation — no Makefile copied from other platforms.`

**Environment Initialization**:
After creating the build configuration and ensuring the Dockerfile at `src/ubuntu/cpp/containers/Dockerfile` is in place, you MUST execute `make container` from the source directory. This step verifies that:
1. The host OS is correctly detected.
2. The build image (`ringbuffer_ubuntu_build`) is successfully created or updated.
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
