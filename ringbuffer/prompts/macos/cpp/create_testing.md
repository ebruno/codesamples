Please implement the full testing suite for the Ringbuffer on macOS.

**Directives:**
- Use `prompts/macos/cpp/testing.md` as the primary platform-specific directive.
- Follow all requirements in `prompts/common/cpp/testing.md` for common C++ testing specifications.

**Scope of Work:**
1. **Host Verification**: Verify that the host OS is macOS using `sw_vers --productName` before starting.
2. **Directory Structure**: Establish the `tests/` directory structure within `src/macos/cpp/tests`, ensuring all directories contain the `.required_directory` marker.
3. **Data Generation & Validation**: 
    - Deploy utility scripts from `prompts/common/cpp/utils/bin/` to `tests/utils/bin/`.
    - **Scripting Mandate**: All utility scripts MUST be written in **Pure Zsh** (version 5.8+) and MUST include a version check at the start. Avoid external tools in favor of shell built-ins.
    - Implement the `verify_test_data.zsh` validator script to enforce the **Strict Line Format Specification** (Length: 58, Prefix space: 5, Suffix space: 4).
    - Generate the zig-zag space pattern test files (`test001.txt` to `test007.txt`).
    - **Validation**: You MUST run the validator and log the success of all seven test files.
4. **Test Program**: Implement the `test001` program with the full CLI interface, supporting both static and dynamic linking.
5. **Build System**: 
    - Create a `Makefile` that supports `clean`, `dist-clean`, and `verify` targets.
    - **Integration**: Implement a `deploy_utils` target that copies scripts from `../../../../prompts/common/cpp/utils/bin/` to `tests/utils/bin/`.
    - **Integration**: Implement a `validate-data` target that the `verify` target depends on.
6. **Verification**:
    - Perform artifact verification using `lipo -info`, `otool -L`, `size`, and `nm`.
    - Execute all scenarios in the **Test Matrix (T001-T007)** and verify the results against expected outcomes.
    - Generate both Markdown (`regression_report.md`) and JUnit XML (`regression_report_junit.xml`) reports in `tests/reports/`.
7. **Documentation**: Create a comprehensive `README.md` in the tests directory.

**Deployment Path:**
All artifacts must be placed in: `src/macos/cpp/tests`

**Definition of Done:**
The task is complete when all binaries are compiled, all test data is generated, all Test Matrix scenarios are verified, and the documentation is complete and accurate.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.