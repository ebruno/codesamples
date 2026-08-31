**Workflow Precedence:** This file is the **PRIMARY** execution document for incremental test updates. The common workflow (`prompts/common/implement_regression.md`) provides structure reference only.

# Incremental Test Update — Arch Linux

**Objective:** Synchronize the Arch Linux test infrastructure with updated common specifications. This prompt is used AFTER initial implementation to apply targeted changes without regenerating the entire test suite.

**Directives:**
1. Use `prompts/archlinux/cpp/testing.md` for platform-specific requirements.
2. Use `prompts/common/cpp/testing.md` as the primary testing specification.

**macOS Skip Logic:** Arch Linux container images are amd64-only. On Apple Silicon (M-series) Macs, there is no ARM64 Arch Linux container available. The test infrastructure setup MUST detect macOS and skip gracefully with a logged message (see `prompts/archlinux/cpp/testing.md` for the exact skip logic).

**Immediate Requirements:**
- **Logging:** Every file creation/modification MUST be recorded in `src/archlinux/cpp/tests/build.log`.
- **State Tracking:** Update `.gen_state.json` in `src/archlinux/cpp/tests/` with new SHA-256 hashes of updated prompts and artifacts.
- **Strict Compliance:** Adhere strictly to the test matrix T001–T007 as defined in `prompts/common/cpp/testing.md`.

**Reporting:**
Once implementation is complete, append to `src/archlinux/cpp/tests/reports/test_infrastructure_report.md`:

# Incremental Test Update - Arch Linux
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Updated Files:** [List of files modified]
**Start Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**End Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Elapsed Time:** [Duration]

## Status
**Test Infrastructure Updated:** [Yes/No/Skipped-macOS]
**Self-Audit Passed:** [Yes/No]

## Changes Applied
- [List of changes applied during this update]

## macOS Skip Note
If this setup was performed on macOS:
- Container image build was skipped (Arch Linux containers are amd64-only)
- Test execution requires a Linux host with podman/docker
