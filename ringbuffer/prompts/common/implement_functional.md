# Functional Implementation Workflow

**Objective:** 
Implement the C++ Ringbuffer library by strictly following the specifications defined in `ringbuffer/prompts/common/cpp/functional.md`.

**Process:**
1. **Target Selection**:
   - **Targeting**: If the user request specifies a target platform (e.g., "implement functional for debian"), perform the following steps **only** for that OS. Otherwise, iterate through **all** OS directories found in `ringbuffer/src/` (e.g., debian, fedora, macos).
   - **Language**: This workflow specifically targets the C++ implementation.

2. **Execution Steps**:
   For the selected OS directory, perform the following:

   0. **Environment Setup**:
      - **Navigate**: `cd ringbuffer/src/<os>/cpp`
      - **Log Initialization**: Create the log directory `logs/` if it does not exist. Initialize `functional.log` with the start timestamp and action description as per the "Generation Process Logging" requirement.

   1. **Header Implementation**:
      - Implement the primary interface `ringbuffer.hpp` and the enums in `status.hpp` first.
      - Ensure the **Mandatory Public Interface** and **Hierarchy** requirements are met exactly.
      - Log each file creation in `functional.log`.

   2. **Implementation Class & Logic**:
      - Implement `swtr_ringbuffer_impl.hpp` ensuring all required standard headers are included.
      - Implement the operational `.cpp` files (e.g., `Lifecycle.cpp`, `ReadOps.cpp`, etc.) following the **File Mapping Table**.
      - Strictly adhere to the **Function Distribution** rule (maximum 3 functions per file).
      - Implement the **Include Discipline** (primary header first, then alphabetical standard headers).
      - Log each file creation in `functional.log`.

   3. **Accessor Implementation**:
      - Create the specific `Accessors_[GroupName].cpp` files as defined in the functional specification to minimize git collisions.
      - Log each file creation in `functional.log`.

   4. **Documentation**:
      - Create the `README.md` in the source directory describing the library and build instructions.

   5. **Final Self-Audit**:
      - Perform the **Final Verification Step** listed at the end of `functional.md`:
        - Check Interface Match, Hierarchy Match, Thread Safety (atomics), File Distribution (3-function limit), Include Order, and Naming (trailing underscores).
      - Rectify any discrepancies found during the audit.

**Reporting:**
Once implementation is complete, generate a summary report at `ringbuffer/src/<os>/reports/implementation_report.md`:

# Implementation Report - [OS Name]
**Date:** [YYYY-MM-DD HH:MM:SS]

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
