**Temporary Workspace Lifecycle:**
1. **Initialization**: Create the `ringbuffer/tmp` directory as the very first action before starting any other task.
2. **Usage**: Ensure all temporary files and scripts generated during the process are stored exclusively within `ringbuffer/tmp`.
3. **Cleanup**: Recursively delete the `ringbuffer/tmp` directory and all its contents immediately upon completion of all tasks associated with this prompt.

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
- **Makefile Consistency:** The generated `Makefile` MUST match the Debian Makefile exactly, except for platform-specific values (`CONTAINER_IMAGE`, working directory path, host distro check). After generating the Makefile, diff it against `src/debian/cpp/Makefile` and resolve any non-platform-specific differences.

**Environment Initialization**:
After creating the build configuration and ensuring the `Dockerfile` is in place, you MUST execute `make container` from the source directory. This step verifies that:
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
