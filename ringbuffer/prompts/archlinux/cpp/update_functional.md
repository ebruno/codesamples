**Workflow Precedence:** This file is the **PRIMARY** execution document for incremental functional updates. The common workflow (`prompts/common/implement_functional.md`) provides structure reference only.

# Incremental Functional Update — Arch Linux

**Objective:** Synchronize the Arch Linux functional implementation with updated common specifications. This prompt is used AFTER initial implementation to apply targeted changes without regenerating the entire source tree.

**Directives:**
1. Use `prompts/archlinux/cpp/functional.md` for platform-specific requirements.
2. Use `prompts/common/cpp/functional.md` as the primary architectural and functional specification.

**macOS Note:** Source code generation is supported on all platforms (including macOS). Build and test require a Linux host with podman/docker due to Arch Linux container image limitations on Apple Silicon.

**Immediate Requirements:**
- **Logging:** Every file creation/modification MUST be recorded in `src/archlinux/cpp/logs/functional.log`.
- **State Tracking:** Update `.gen_state.json` in `src/archlinux/cpp/` with new SHA-256 hashes of updated prompts and artifacts.
- **Strict Compliance:** Adhere strictly to the "maximum 3 functions per file" rule and the trailing underscore naming convention for private members.
- **Source Fidelity:** The generated source code MUST be byte-identical to the common specification. Generate all files independently from `prompts/common/cpp/functional.md` — do not copy source files from any other platform.

**Reporting:**
Once implementation is complete, append to `src/archlinux/cpp/reports/implementation_report.md`:

# Incremental Functional Update - Arch Linux
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Updated Files:** [List of files modified]
**Start Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**End Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Elapsed Time:** [Duration]

## Status
**Implementation Updated:** [Yes/No]
**Self-Audit Passed:** [Yes/No]

## Changes Applied
- [List of changes applied during this update]
