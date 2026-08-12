**Temporary Workspace**: See `prompts/common/cpp/functional.md` for the authoritative temporary workspace directives.

**Workflow Precedence:** This file is the **PRIMARY** execution document. The common workflow (`prompts/common/implement_functional.md`) provides version resolution and structure reference only.

# Functional Implementation Workflow — Ubuntu

**Objective:** Implement the C++ Ringbuffer library for Ubuntu by strictly following the specifications defined in `prompts/common/cpp/functional.md` and platform-specific requirements in `prompts/ubuntu/cpp/functional.md`. If a version override was provided via the common workflow's **Target Version** input, use that instead of the default version below.

Default version for this platform: Ubuntu 24.04 LTS (overridable via Target Version input).

**Version Context:** The version from the common workflow's **Target Version** input should be passed as context. If no version is provided in the user prompt, use default: Ubuntu 24.04 LTS.

**Directives:**
1. Use `prompts/ubuntu/cpp/functional.md` for platform-specific requirements.
2. Use `prompts/common/cpp/functional.md` as the primary architectural and functional specification.

0. **Environment Setup**:
      - **Use Version**: Use the version resolved by `prompts/common/implement_functional.md` Step 0. If no version was resolved, use the default: Ubuntu 24.04 LTS.
      - **Log Initialization**: If `functional.log` does not yet exist, create it with the start timestamp, action description, and resolved version. Otherwise, skip initialization (already performed by common workflow Step 0).

1. **Header Implementation**:
      - Implement the primary interface `ringbuffer.hpp` and the enums in `status.hpp`, following `prompts/common/cpp/functional.md`. Apply any platform-specific overrides from `prompts/ubuntu/cpp/functional.md`.
      - Ensure the **Mandatory Public Interface** and **Hierarchy** requirements are met exactly.
      - Log each file creation in `functional.log` immediately after the file is written.

2. **Implementation Class & Logic**:
      - Implement `swtr_ringbuffer_impl.hpp` ensuring all required standard headers are included, following `prompts/common/cpp/functional.md`. Apply any platform-specific overrides from `prompts/ubuntu/cpp/functional.md`.
      - Implement the operational `.cpp` files (e.g., `Lifecycle.cpp`, `ReadOps.cpp`, etc.) following the **File Mapping Table**.
      - Strictly adhere to the **Function Distribution** rule (maximum 3 functions per file).
      - Implement the **Include Discipline** (primary header first, then alphabetical standard headers).
      - Log each file creation in `functional.log` immediately after the file is written.

3. **Accessor Implementation**:
      - Create the specific `Accessors_[GroupName].cpp` files as defined in `prompts/common/cpp/functional.md`. Apply any platform-specific overrides from `prompts/ubuntu/cpp/functional.md`.
      - Log each file creation in `functional.log` immediately after the file is written.

4. **Documentation**:
      - Create the `README.md` in the source directory describing the library and build instructions.
      - Log the creation of `README.md` in `functional.log`.

5. **Final Self-Audit**:
      - Verify Interface Match, Hierarchy Match, Thread Safety (atomics), File Distribution (3-function limit), Include Order, and Naming (trailing underscores).
      - Rectify any discrepancies found during the audit.

6. **Finalize Logs**:
      - Append a final entry to `functional.log` stating that the functional implementation is complete.
      - Calculate and include the total elapsed time since the start timestamp in this final entry.

**Immediate Requirements:**
- **Source Tree:** Implement the full set of files defined in the **File Mapping Table** of the common specification. 
- **Strict Compliance:** Adhere strictly to the "maximum 3 functions per file" rule and the trailing underscore naming convention for private members.
- **Location:** All generated source code and the `LICENSE` file must be placed in `src/ubuntu/cpp`.
- **State Tracking:** Upon completion, create a `.gen_state.json` file in `src/ubuntu/cpp` containing the SHA-256 hashes of the prompts used and the fingerprints of all generated files to support future incremental updates.
- **Source Fidelity:** The generated source code MUST be byte-identical to the common specification. Generate all files independently from `prompts/common/cpp/functional.md` — do not copy source files from any other platform.
- **Cross-Platform Verification:** After generating all files independently, compare output against any other platform's source in `src/` if available. If a reference platform exists, verify byte-identical output and log: `[timestamp] Cross-platform comparison passed — Ubuntu matches <platform>.` If no reference platform exists, log: `[timestamp] Cross-platform comparison skipped — no other platform source available.`
- **Documentation:** Create a `README.md` in the source directory describing the library and build instructions.

**Reporting:**
Once implementation is complete, generate a summary report at `src/ubuntu/cpp/reports/implementation_report.md`:

# Implementation Report - Ubuntu <use the version resolved in Step 0, e.g., "24.04 LTS">
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Target Version:** <use the version resolved in Step 0, e.g., "24.04 LTS">
**Start Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**End Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Elapsed Time:** [Duration]

## Status
**Implementation Complete:** [Yes/No]
**Self-Audit Passed:** [Yes/No]

## Artifacts Created
- **Headers**: [List of .hpp files]
- **Source Files**: [List of .cpp files]
- **Logs**: `functional.log` created and updated.

## Compliance Notes
- **Function Distribution**: Verified no file exceeds 3 functions.
- **Include Order**: Verified `ringbuffer.hpp` is first in all `.cpp` files.
- **Naming**: Verified trailing underscore convention for private members.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `ErrorOps.cpp`, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
<EOF>
