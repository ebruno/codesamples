**Temporary Workspace**: See `ringbuffer/prompts/common/cpp/testing.md` for the authoritative temporary workspace directives.

**Default Image**: `reference_linux:latest` (template only — not a real container)

This is the **canonical reference** for Linux test infrastructure. It defines the authoritative test Makefile and Dockerfile that all real platforms (debian, fedora, ubuntu) must match against.

**Directives:**
1. Use `ringbuffer/prompts/common/cpp/testing.md` as the primary testing specification.

**Purpose:**
- Generate the canonical test Makefile at `ringbuffer/src/reference_linux/cpp/tests/Makefile`
- Generate the canonical Dockerfile template at `ringbuffer/src/reference_linux/cpp/tests/containers/reference_linux/Dockerfile`
- Deploy utility scripts to `ringbuffer/src/reference_linux/cpp/tests/utils/bin/` from `prompts/common/cpp/utils/bin/`
- Generate test data files (`test001.txt`–`test007.txt`) in `ringbuffer/src/reference_linux/cpp/tests/data/inputs/`
- Generate expected output files (golden files) in `ringbuffer/src/reference_linux/cpp/tests/data/expected/`

**Important:** This pseudo-OS does NOT build containers or execute tests. It exists solely as a file-based reference for cross-platform verification.

**Verification Criteria:**
Before finishing, verify:
1. The canonical Makefile exists and has all required targets (`clean`, `dist-clean`, `container`, `verify`).
2. The canonical Dockerfile template exists with valid structure.
3. All 7 test data files exist in `tests/data/inputs/`.
4. Utility scripts are deployed to `tests/utils/bin/`.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
