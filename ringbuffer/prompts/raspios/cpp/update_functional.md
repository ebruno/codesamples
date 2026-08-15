**Temporary Workspace**: See `prompts/common/cpp/functional.md` for the authoritative temporary workspace directives.

**Workflow Precedence:** This file is the **PRIMARY** execution document for updating an existing Raspberry Pi OS functional implementation.

Please update the Ringbuffer functional code for Raspberry Pi OS.

**Directives:**
1. Use `prompts/raspios/cpp/functional.md` for platform-specific requirements.
2. Use `prompts/common/cpp/functional.md` as the primary functional specification.

**Immediate Requirements:**
- **Logging:** Every update step MUST be recorded in `src/raspios/cpp/logs/build.log`.
- **Source Code**: Update platform-specific C++ source files in `src/raspios/cpp/`.
- **State Tracking**: Update `.gen_state.json` with new SHA-256 hashes of all modified source files.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions, use a Python script with `os.scandir` to identify and recursively remove them.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

**Reporting:**
Once implementation is complete, generate a summary report at `src/raspios/cpp/reports/functional_update_report.md`:

# Functional Update Report - Raspberry Pi OS
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]

## Status
**Source Code Updated:** [Yes/No]

## Changes Applied
- **Modified files**: [List changed .cpp/.hpp files]
- **API changes**: [Describe any API surface changes]

## Self-Audit Results
- **API Surface**: [PASS/FAIL] — matches common spec requirements
- **Pipeline Stages**: [PASS/FAIL] — read, transform, write stages intact

## Fixes and Modifications
<details>
<summary>Click to expand</summary>

[List any fixes or modifications applied during update]

</details>
<EOF>
