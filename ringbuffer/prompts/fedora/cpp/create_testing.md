**Temporary Workspace**: See `prompts/common/cpp/testing.md` for the authoritative temporary workspace directives.

Please implement the full testing suite for the Ringbuffer on Fedora.

**Directives:**
- Use `prompts/fedora/cpp/testing.md` as the primary platform-specific directive.
- Follow all requirements in `prompts/common/cpp/testing.md` for common C++ testing specifications.

**Scope of Work:**
1. **Environment Setup**: Create the container configuration (`Dockerfile`) as specified for Fedora 44, using `FROM fedora:44` as the base image with all required build tools installed via `dnf`.
2. **Directory Structure**: Establish the `tests/` directory structure within `src/fedora/cpp/tests`, ensuring all directories contain the `.required_directory` marker.
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
