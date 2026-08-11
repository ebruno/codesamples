# Update Build System - Debian

**Objective:** Update the build configuration to reflect changes in the source tree or build specifications.

**Temporary Workspace Lifecycle:**
1. **Initialization**: Create the `ringbuffer/tmp` directory as the very first action before starting any other task.
2. **Usage**: Ensure all temporary files and scripts generated during the process are stored exclusively within `ringbuffer/tmp`.
3. **Cleanup**: Recursively delete the `ringbuffer/tmp` directory and all its contents immediately upon completion of all tasks associated with this prompt.

**Inputs:**
1. The current build file (e.g., `Makefile` or `CMakeLists.txt`).
2. The current list of files in `src/debian/cpp`.
3. `ringbuffer/prompts/debian/cpp/build.md`.

**Directives:**
1. Use `ringbuffer/prompts/debian/cpp/build.md` for platform-specific prerequisites.
2. Use `ringbuffer/prompts/common/cpp/build.md` as the primary build specification.

**Instructions:**
- **Source Sync:** If new `.cpp` or `.hpp` files have been added to the source tree, add them to the build targets.
- **Cleanup:** Remove references to any files that have been deleted.
- **Flag Update:** If `build.md` has updated compiler flags or optimization levels, apply them to the build script.
- **Validation:** Ensure the build script still produces the target binary with the correct visibility settings (`-fvisibility=hidden`).

**Architecture Changes:**
When the source tree changes in ways not covered by the File Mapping Table (e.g., new logic groups, refactored files, or additional operation categories):
1. **New Source Files:** If new `.cpp` or `.hpp` files exist that are not referenced in the Makefile's `SRCS` variable, add them to the appropriate build target.
2. **New Makefile Targets:** If a new library type or artifact is required (e.g., a static-only variant), add the corresponding Makefile target and update `.PHONY` accordingly.
3. **File Mapping Table Updates:** If the common spec's File Mapping Table has been updated (e.g., new accessor groups), ensure the Makefile includes all referenced files. If a file in the table is missing from the source tree, report it as an error rather than silently skipping it.
4. **Function Count Constraint:** Verify that no `.cpp` file exceeds the 3-function limit after changes. If a new file would cause an existing file to exceed this limit, split the functions into numbered files (e.g., `LoggingOps_7.cpp`).

**Container Runtime Pre-flight (macOS Host):**
If this update involves container operations (e.g., rebuilding the build image), and the host OS is macOS, the `container` command MUST be available in PATH before proceeding.
- **Verification**: Execute `command -v container` to confirm availability.
- **Error Handling**: If `container` is NOT found, STOP and display:
  ```
  ERROR: The 'container' command is required for cross-OS builds from macOS to Linux targets, but it was not found in PATH.
  
  Please install Apple Container from: https://github.com/apple/container
  
  After installation, ensure the 'container' command is available in your PATH and re-run the build workflow.
  ```

**State Management:**
- **Spec Hash Update:** Update the hash of the platform-specific `build.md` in `.gen_state.json` upon completion.

**Documentation Synchronization:**
- **README Update:** If the build or testing changes affect the high-level project status (e.g., a platform is now "WIP" instead of "TBS"), use `ringbuffer/prompts/common/generate_toplevel_readme.md` to update the top-level `README.md`.

**Output:**
- The updated build file.

## Cross-Platform Update Propagation
After successfully updating the build system for this platform, you MUST:
1. Copy the updated `Makefile` to the other Linux platform's source directory (e.g., Debian → Ubuntu, or vice versa), adjusting only `CONTAINER_IMAGE`, working directory path, and host distro check.
2. Verify byte-identity of all non-platform-specific content with `diff`.
3. Update `.gen_state.json` in **both** platforms.
4. Log the propagation action in both platform's `logs/build.log`.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

## Scope Boundary — Build Update Only

The purpose of this prompt is to update the build configuration (Makefile, compiler flags, source file references) for the library. **You MUST NOT touch anything in the `tests/` directory.**

**Allowed scope (build-related only):**
- Update `Makefile`: add/remove source file references, update compiler flags, add new library targets
- Update `containers/Dockerfile`: adjust package installations for the build environment
- Create/update files in `specs/` directory (build requirements documentation)
- Update `.gen_state.json` with spec hash

**Explicitly forbidden (testing-related):**
- **NEVER create, modify, or delete any files inside `tests/`** — this includes test source code, test data, utility scripts, container configs, Makefiles, logs, or reports
- **NEVER create missing directories inside `tests/`** (e.g., `tests/logs`, `tests/reports`)
- **NEVER create or update test scripts** (e.g., `verify_test_data.sh`, `generate_test_data.sh`)
- **NEVER create or update test programs** (e.g., `tests/src/test001.cpp`)
- **NEVER run any test commands** (`make -C tests`, `make verify`, etc.)

If the `tests/` directory is missing required files or directories, **report this as a finding and STOP**. Do not create or fix them. The `tests/` directory is managed exclusively by testing-related prompts (`create_testing.md`, `update_testing.md`).
<EOF>
