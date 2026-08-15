**Temporary Workspace**: See `prompts/common/cpp/testing.md` for the authoritative temporary workspace directives.

**Workflow Precedence:** This file is the **PRIMARY** execution document. The common workflow (`prompts/common/implement_regression.md`) provides structure reference only.

# Test Infrastructure Setup — Arch Linux

**Objective:** Set up the test infrastructure for the C++ Ringbuffer library on Arch Linux by strictly following the specifications defined in `prompts/common/cpp/testing.md` and platform-specific requirements in `prompts/archlinux/cpp/testing.md`.

**Directives:**
1. Use `prompts/archlinux/cpp/testing.md` for platform-specific requirements.
2. Use `prompts/common/cpp/testing.md` as the primary testing specification.

0. **Environment Setup**:
      - **Log Initialization**: If `build.log` does not yet exist, create it with the start timestamp and action description. Otherwise, skip initialization (already performed by common workflow Step 0).

1. **Test Source Code**:
      - Generate the test source code (`test001.cpp`) following `prompts/common/cpp/testing.md`.
      - Place test source in `src/archlinux/cpp/tests/src/`.
      - Log each file creation in `build.log` immediately after the file is written.

2. **Test Data**:
      - Generate test input files (`test001.txt` through `test007.txt`) using the utility scripts.
      - Generate expected output files (`t001.out` through `t007.out`).
      - Place test data in `src/archlinux/cpp/tests/data/`.

3. **Test Makefile**:
      - Create the test `Makefile` in `src/archlinux/cpp/tests/`.
      - Include the same macOS skip logic as described in `prompts/archlinux/cpp/testing.md`.
      - The Makefile MUST implement targets: `all`, `static`, `dynamic`, `verify`, `clean`, `dist-clean`, `container`.

4. **Container Setup**:
      - Create the test container Dockerfile at `src/archlinux/cpp/tests/containers/archlinux/Dockerfile`.
      - On Linux hosts: Build the container image using `podman build`.
      - On macOS hosts: Skip with a logged message (see macOS Skip Logic below).

5. **macOS Skip Logic**:
      Arch Linux container images are amd64-only. On Apple Silicon (M-series) Macs, there is no ARM64 Arch Linux container available. The test infrastructure setup MUST detect macOS and skip gracefully:

      When running on macOS, the script MUST log to `build.log`:
      ```
      [timestamp] Arch Linux test infrastructure skipped on macOS (Apple Silicon) — no ARM64 container available.
      [timestamp] Test execution requires a Linux host with podman/docker.
      ```

6. **Finalize Logs**:
      - Append a final entry to `build.log` stating that the test infrastructure setup is complete.
      - Calculate and include the total elapsed time since the start timestamp in this final entry.

**Immediate Requirements:**
- **Test Directory Structure**: Create the full test directory structure in `src/archlinux/cpp/tests/` including `src/`, `data/inputs/`, `data/expected/`, `logs/`, `reports/`, and `containers/archlinux/`.
- **Strict Compliance:** Adhere strictly to the test matrix T001–T007 as defined in `prompts/common/cpp/testing.md`.
- **State Tracking:** Upon completion, create a `.gen_state.json` file in `src/archlinux/cpp/tests/` containing the SHA-256 hashes of the prompts used and the fingerprints of all generated files.

**Reporting:**
Once implementation is complete, generate a summary report at `src/archlinux/cpp/tests/reports/test_infrastructure_report.md`:

# Test Infrastructure Report - Arch Linux
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Start Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**End Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Elapsed Time:** [Duration]

## Status
**Test Infrastructure Created:** [Yes/No/Skipped-macOS]
**Container Image Built:** [Yes/No/Skipped-macOS]
**Self-Audit Passed:** [Yes/No]

## Artifacts Created
- **Test Source**: `tests/src/test001.cpp`
- **Test Data**: `tests/data/inputs/test001.txt` through `test007.txt`
- **Expected Output**: `tests/data/expected/t001.out` through `t007.out`
- **Makefile**: `tests/Makefile`
- **Dockerfile**: `tests/containers/archlinux/Dockerfile` (Linux hosts only)
- **Logs**: `build.log` created and updated.

## macOS Skip Note
If this setup was performed on macOS:
- Container image build was skipped (Arch Linux containers are amd64-only)
- Test execution requires a Linux host with podman/docker

## Notes
- Arch Linux is a rolling-release distribution; package versions are always the latest available.
- Container images use datestamp tags (e.g., `archlinux:2026.05.31`) from 3 months ago for reproducibility.
- On Apple Silicon Macs, Arch Linux test execution must be performed on a Linux host.
