**Temporary Workspace**: See `prompts/common/cpp/testing.md` for the authoritative temporary workspace directives.

Please implement the full testing suite for the Ringbuffer on Ubuntu 24.04 LTS (Linux kernel 6.N).

**Directives:**
- Use `prompts/ubuntu/cpp/testing.md` as the primary platform-specific directive.
- Follow all requirements in `prompts/common/cpp/testing.md` for common C++ testing specifications.

**Scope of Work:**
1. **Environment Setup**: Create the container configuration (`Dockerfile`) as specified for Ubuntu 24.04 LTS, using `FROM ubuntu:24.04` as the base image with all required build tools installed via `apt-get`.
2. **Directory Structure**: Establish the `tests/` directory structure within `src/ubuntu/cpp/tests`, ensuring all directories contain the `.required_directory` marker.
3. **Data Generation & Validation**: 
    - Implement the required shell scripts using `/usr/bin/env` shebangs (e.g., `#!/usr/bin/env bash`).
    - **Scripting Mandate**: All utility scripts MUST be written in **Pure Bash** (version 5.0+) and MUST include a version check at the start.
    - **Shell Script Portability Rule** (from `.bionic`): Do NOT use platform-dependent external tools (`grep`, `sed`, `awk`, `cut`, `sort`, `find`) in Bash scripts — their behavior differs between macOS (BSD) and Linux (GNU). Permitted utilities: `date`, `cat`, `mkdir -p`, `rm -rf`. See `.bionic` for the full rule.
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
All artifacts must be placed in: `src/ubuntu/cpp/tests`

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
7. **Container Runtime Check**: Detect the host OS and verify the appropriate runtime is available:
   - If `uname -s` returns Darwin (macOS): verify `container` is available via `command -v container`. If not found, STOP and report the error with installation instructions.
   - If `uname -s` returns Linux: verify `podman` is available via `command -v podman`. If not found, STOP and report the error with installation instructions.
- **Independent Generation:** Generate all test artifacts independently from `prompts/common/cpp/testing.md` and `prompts/ubuntu/cpp/testing.md`. Do NOT copy test files from another platform. Log: `[timestamp] Independent testing generation — no test artifacts copied from other platforms.`
- **Cross-Platform Verification:** After generating all test artifacts, compare against any other platform's source in `src/` if available. If a reference platform exists, verify byte-identical output (except for allowed differences) and log: `[timestamp] Cross-platform comparison passed — Ubuntu matches <platform>.` If no reference platform exists, log: `[timestamp] Cross-platform comparison skipped — no other platform source available.`

**Tooling and Recovery:
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
