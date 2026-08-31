**Temporary Workspace**: See `prompts/common/cpp/testing.md` for the authoritative temporary workspace directives.

**Workflow Precedence:** This file is the **PRIMARY** execution document. The common workflow (`prompts/common/implement_regression.md`) provides structure and routing reference only.

Please set up the test infrastructure for the Ringbuffer on Raspberry Pi OS.

**Directives:**
1. Use `prompts/raspios/cpp/testing.md` for platform-specific testing requirements.
2. Use `prompts/common/cpp/testing.md` as the primary testing specification.

**Immediate Requirements:**
- **Logging:** Every test setup step MUST be recorded in `src/raspios/cpp/logs/build.log`.
- **Test Infrastructure**: Create test source files, data generation scripts, and JUnit report generators in `src/raspios/cpp/tests/`.
- **Container Path**: Use `tests/containers/raspios/Dockerfile` for test container builds.
- **Header Search Path**: Use `src/raspios/cpp`.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions, use a Python script with `os.scandir` to identify and recursively remove them.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

**Reporting:**
Once implementation is complete, generate a summary report at `src/raspios/cpp/reports/regression_creation_report.md`:

# Regression Test Infrastructure Report - Raspberry Pi OS
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Target OS**: Raspberry Pi OS (Debian 13/trixie), arm64
**Ringbuffer Version:** <resolved_version from shared context>

## Status
**Test Infrastructure Created:** [Yes/No]
**Container Dockerfile Ready:** [Yes/No]

## Files Created
- **Test source files**: `src/raspios/cpp/tests/src/*.cpp`
- **Data generation scripts**: `src/raspios/cpp/tests/utils/bin/generate_test_data.sh`
- **JUnit report generator**: `src/raspios/cpp/tests/utils/bin/generate_junit_report.sh`
- **Logs**: `build.log` created and updated.

## Self-Audit Results
- **Test Matrix**: [PASS/FAIL] — 7-test matrix (T001-T007) covered
- **Data Generation**: [PASS/FAIL] — test data scripts present and executable
- **JUnit Reports**: [PASS/FAIL] — report generator present and functional

## Fixes and Modifications
<details>
<summary>Click to expand</summary>

[List any fixes or modifications applied during setup]

</details>
<EOF>
