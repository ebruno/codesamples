**Temporary Workspace**: See `prompts/common/cpp/build.md` for the authoritative temporary workspace directives.

**Workflow Precedence:** This file is the **PRIMARY** execution document for updating an existing Raspberry Pi OS build environment.

Please update the build system for the Ringbuffer on Raspberry Pi OS.

**Directives:**
1. Use `prompts/raspios/cpp/build.md` for platform-specific prerequisites.
2. Use `prompts/common/cpp/build.md` as the primary build specification.

**Immediate Requirements:**
- **Logging:** Every update step MUST be recorded in `src/raspios/cpp/logs/build.log`.
- **Configuration**: Update the build configuration (Makefile) in `src/raspios/cpp/`.
- **Dockerfile**: Update the Dockerfile at `raspios/containers/build/Dockerfile` if package requirements have changed.
- **Specs**: Update `specs/build.md`, `specs/testing_requirements.md` if the prompt specs have changed.
- **State Tracking**: Update `.gen_state.json` with new SHA-256 hashes of all modified artifacts.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions, use a Python script with `os.scandir` to identify and recursively remove them.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

**Reporting:**
Once implementation is complete, generate a summary report at `src/raspios/cpp/reports/build_update_report.md`:

# Build Update Report - Raspberry Pi OS
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Target Image:** <resolved_image>

## Status
**Build System Updated:** [Yes/No]
**Container Image Rebuilt:** [Yes/No]

## Changes Applied
- **Makefile**: [List changes]
- **Dockerfile**: [List changes]
- **Specs**: [List changes]

## Self-Audit Results
- **Makefile Targets**: [PASS/FAIL] — `all`, `static`, `shared`, `clean`, `dist-clean`, `container`
- **Dockerfile**: [PASS/FAIL] — base image, package installation

## Fixes and Modifications
<details>
<summary>Click to expand</summary>

[List any fixes or modifications applied during update]

</details>
<EOF>
