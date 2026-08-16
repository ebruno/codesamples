**Temporary Workspace**: See `prompts/common/cpp/functional.md` for the authoritative temporary workspace directives.

**Workflow Precedence:** This file is the **PRIMARY** execution document. The common workflow (`prompts/common/implement_functional.md`) provides structure and routing reference only.

Please implement the Ringbuffer functional code for Raspberry Pi OS.

**Directives:**
1. Use `prompts/raspios/cpp/functional.md` for platform-specific requirements.
2. Use `prompts/common/cpp/functional.md` as the primary functional specification.

**Immediate Requirements:**
- **Logging:** Every implementation step, configuration change, and verification result MUST be recorded in `src/raspios/cpp/logs/build.log`.
- **Source Code**: Generate platform-specific C++ source files in `src/raspios/cpp/`.
- **License**: Create the `LICENSE` file with BSD 3-Clause text in `src/raspios/cpp/`.
- **State Tracking:** Upon completion, create a `.gen_state.json` file in `src/raspios/cpp/` containing the resolved version, SHA-256 hashes of all generated source files.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `ErrorOps.cpp`, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

**Reporting:**
Once implementation is complete, generate a summary report at `src/raspios/cpp/reports/functional_creation_report.md`:

# Functional Implementation Report - Raspberry Pi OS
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Target OS**: Raspberry Pi OS (Debian 13/trixie), arm64
**Ringbuffer Version:** <resolved_version from shared context>
**Start Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**End Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Elapsed Time:** [Duration]

## Status
**Source Code Generated:** [Yes/No]
**License File Created:** [Yes/No]
**Self-Audit Passed:** [Yes/No]

## Files Created
- **Source files**: `src/raspios/cpp/*.cpp`, `src/raspios/cpp/*.hpp`
- **License**: `src/raspios/cpp/LICENSE`
- **Logs**: `build.log` created and updated.

## Self-Audit Results
- **API Surface**: [PASS/FAIL] — matches common spec requirements
- **Pipeline Stages**: [PASS/FAIL] — read, transform, write stages implemented
- **Error Handling**: [PASS/FAIL] — ErrorHandler callback present
- **EOF Detection**: [PASS/FAIL] — LAST_BUFFER_TO_TRANSFORM/WRITE propagation

## Fixes and Modifications
<details>
<summary>Click to expand</summary>

[List any fixes or modifications applied during implementation]

</details>
<EOF>
