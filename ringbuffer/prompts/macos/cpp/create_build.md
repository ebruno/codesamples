**Temporary Workspace Lifecycle:**
1. **Initialization**: Create the `ringbuffer/tmp` directory as the very first action before starting any other task.
2. **Usage**: Ensure all temporary files and scripts generated during the process are stored exclusively within `ringbuffer/tmp`.
3. **Cleanup**: Recursively delete the `ringbuffer/tmp` directory and all its contents immediately upon completion of all tasks associated with this prompt.

Please configure the build system for the Ringbuffer on macOS.

**Directives:**
1. Use `ringbuffer/prompts/macos/cpp/build.md` for platform-specific requirements and Universal Binary specifications.
2. Use `ringbuffer/prompts/common/cpp/build.md` as the primary build specification.

**Immediate Requirements:**
- **Host Verification**: Before proceeding, verify that the host operating system is macOS by executing `sw_vers --productName`.
- **Logging:** Every build step, configuration change, and verification result MUST be recorded in `ringbuffer/src/macos/cpp/logs/build.log`.
- **Configuration**: Create the build configuration (e.g., Makefile or CMakeLists.txt) in `ringbuffer/src/macos/cpp`.
- **Documentation**: Create `build.md`, `testing.md`, and `artifacts.md` files in the project root.
- **Versioning**: The build system MUST source `version.mk` to generate the versioned artifact names.
- **Artifacts:** 
    - Deploy libraries to the `lib/` subdirectory.
    - Create relative symbolic links from unversioned names to versioned artifacts within the `lib/` directory.
- **Optimization**: Ensure `-flto`, `-fvisibility=hidden`, `-ffunction-sections`, `-fdata-sections`, and `-dead_strip` are applied to achieve the "small binary" goal.
- **Toolchain**: Use Clang by default.
- **Scripting**: All utility scripts MUST be written in **Pure Zsh** (version 5.8+) and MUST include a version check at the start. Avoid external tools in favor of shell built-ins.

**Verification Criteria:**
Before finishing, you MUST verify and log the following:
1. **Architecture**: Use `lipo -info` on both `.a` and `.dylib` files to confirm they are Universal Binaries (arm64 and x86_64).
2. **Install Name**: Use `otool -L` on the shared library to confirm the install name is `@rpath/libswtr_ringbuffer.dylib`.
3. **Binary Size**: Use `size -m` to verify the effectiveness of dead code elimination.
4. **Cleanliness**: Verify that the `clean` target removes `build/`, `lib/`, and backup files using the `$(RM)` macro.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
