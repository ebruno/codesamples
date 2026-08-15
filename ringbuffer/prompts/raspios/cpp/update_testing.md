**Temporary Workspace**: See `prompts/common/cpp/testing.md` for the authoritative temporary workspace directives.

**Workflow Precedence:** This file is the **PRIMARY** execution document for updating an existing Raspberry Pi OS test infrastructure.

Please update the test infrastructure for the Ringbuffer on Raspberry Pi OS.

**Directives:**
1. Use `prompts/raspios/cpp/testing.md` for platform-specific testing requirements.
2. Use `prompts/common/cpp/testing.md` as the primary testing specification.

**Immediate Requirements:**
- **Logging:** Every update step MUST be recorded in `src/raspios/cpp/logs/build.log`.
- **Test Infrastructure**: Update test source files, data generation scripts, and JUnit report generators in `src/raspios/cpp/tests/`.
- **Container Path**: Update `tests/containers/raspios/Dockerfile` if test container requirements have changed.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions, use a Python script with `os.scandir` to identify and recursively remove them.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

**Reporting:**
Once implementation is complete, generate a summary report at `src/raspios/cpp/reports/regression_update_report.md`:

# Regression Test Infrastructure Update Report - Raspberry Pi OS
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]

## Status
**Test Infrastructure Updated:** [Yes/No]

## Changes Applied
- **Modified files**: [List changed test files]
- **Container Dockerfile**: [Describe any changes]

## Self-Audit Results
- **Test Matrix**: [PASS/FAIL] — 7-test matrix (T001-T007) still covered
- **Data Generation**: [PASS/FAIL] — test data scripts still functional

## Fixes and Modifications
<details>
<summary>Click to expand</summary>

[List any fixes or modifications applied during update]

</details>
<EOF>
