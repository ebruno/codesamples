**Workflow Precedence:** This file is the **PRIMARY** execution document for incremental build updates. The common workflow (`prompts/common/implement_build.md`) provides structure reference only.

# Incremental Build Update — Arch Linux

**Objective:** Synchronize the Arch Linux build system with updated common specifications. This prompt is used AFTER initial implementation to apply targeted changes without regenerating the entire build system.

**Directives:**
1. Use `prompts/archlinux/cpp/build.md` for platform-specific prerequisites.
2. Use `prompts/common/cpp/build.md` as the primary build specification.

**macOS Skip Logic:** Arch Linux container images are amd64-only. On Apple Silicon (M-series) Macs, there is no ARM64 Arch Linux container available. The `container` target MUST detect macOS and skip gracefully with a logged message (see `prompts/archlinux/cpp/build.md` for the exact skip logic).

**Immediate Requirements:**
- **Logging:** Every build step, configuration change, and verification result MUST be recorded in `src/archlinux/cpp/logs/build.log`.
- **State Tracking:** Update `.gen_state.json` in `src/archlinux/cpp/` with new SHA-256 hashes of updated prompts and artifacts.
- **Makefile Consistency:** The generated `Makefile` MUST follow the common build specification exactly, with only the allowed platform-specific differences (`CONTAINER_IMAGE`, working directory path, host distro check).

**Reporting:**
Once implementation is complete, append to `src/archlinux/cpp/reports/build_creation_report.md`:

# Incremental Build Update - Arch Linux
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Updated Files:** [List of files modified]
**Start Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**End Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Elapsed Time:** [Duration]

## Status
**Build System Updated:** [Yes/No]
**Self-Audit Passed:** [Yes/No]

## Changes Applied
- [List of changes applied during this update]

## macOS Skip Note
If this build was performed on macOS:
- Container image build was skipped (Arch Linux containers are amd64-only)
- Source code generation is supported; build/test requires a Linux host with podman/docker
