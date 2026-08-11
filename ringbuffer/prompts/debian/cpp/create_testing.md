**Temporary Workspace Lifecycle:**
1. **Initialization**: Create the `ringbuffer/tmp` directory as the very first action before starting any other task.
2. **Usage**: Ensure all temporary files and scripts generated during the process are stored exclusively within `ringbuffer/tmp`.
3. **Cleanup**: Recursively delete the `ringbuffer/tmp` directory and all its contents immediately upon completion of all tasks associated with this prompt.

Please implement the full testing suite for the Ringbuffer on Debian.

**Directives:**
- Use `ringbuffer/prompts/debian/cpp/testing.md` as the primary platform-specific directive.
- Follow all requirements in `ringbuffer/prompts/common/cpp/testing.md` for common C++ testing specifications.

**Scope of Work:**
1. **Environment Setup**: Create the container configuration (`Dockerfile`) as specified for Debian 13.
2. **Directory Structure**: Establish the `tests/` directory structure within `ringbuffer/src/debian/cpp/tests`, ensuring all directories contain the `.required_directory` marker.
3. **Data Generation & Validation**: 
    - Implement the required shell scripts using `/usr/bin/env` shebangs.
    - **Scripting Mandate**: All utility scripts MUST be written in **Pure Bash** (version 5.0+) and MUST include a version check at the start. Avoid external tools in favor of shell built-ins.
    - Implement the `verify_test_data.sh` validator script to enforce the **Strict Line Format Specification** (Length: 58, Prefix space at position 5, Suffix space at position 54).
    - Generate the zig-zag space pattern test files (`test001.txt` to `test007.txt`).
    - **Validation**: You MUST run the validator and log the success of all seven test files.
4. **Test Program**: Implement the `test001` program with the full CLI interface, supporting both static and dynamic linking.
5. **Build System**: 
    - Create a `Makefile` that supports `clean` and `dist-clean` targets.
    - **Integration**: Implement a `validate-data` target that the `verify` target depends on.
6. **Verification**:
    - Perform artifact verification using `file`, `readelf`, `size`, and `nm`.
    - Execute all scenarios in the **Test Matrix (T001-T007)** and verify the results against expected outcomes.
7. **Documentation**: Create a comprehensive `README.md` in the tests directory.

**Deployment Path:**
All artifacts must be placed in: `ringbuffer/src/debian/cpp/tests`

**Definition of Done:**
The task is complete when all binaries are compiled, all test data is generated, all Test Matrix scenarios are verified, and the documentation is complete and accurate.

## First-Attempt Verification Checklist

Before declaring the task complete, you MUST run every item on this checklist and log the results. If ANY check fails, fix it immediately — do not proceed to "Definition of Done" until all checks pass.

1. **Test Data Line Length**: Run `head -1 data/inputs/test001.txt | wc -c` — the output must be `59` (58 chars + newline). If it is not, regenerate the data.
2. **Test Data Regex Validation**: Run `utils/bin/verify_test_data.sh data/inputs/test*.txt` — all 7 files must pass with exit code 0.
3. **Static Link Compilation**: Run `make static` — must compile without errors or warnings about unused parameters.
4. **Dynamic Link Compilation**: Run `make dynamic` — must compile without errors or warnings about unused parameters.
5. **Binary Format Check**: Run `file bin/test001_staticlib` — must report "ELF 64-bit" (not Mach-O).
6. **SONAME Check**: Run `readelf -d ../lib/libswtr_ringbuffer.so | grep SONAME` — must show `Library soname: [libswtr_ringbuffer.so]`.
7. **Container Runtime Check**: If running on macOS, verify `container` is available via `command -v container`. If not found, STOP and report the error with installation instructions.
8. **Cross-Platform Sync**: Diff the Ubuntu test artifacts (`src/ubuntu/cpp/tests/Makefile`, `tests/reports/regression_report.md`, `tests/reports/regression_report_junit.xml`) against the Debian equivalents. Resolve any non-platform-specific differences. The test execution flow, report format, and container workflow MUST be identical.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
