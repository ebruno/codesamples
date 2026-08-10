# Functional Implementation Workflow

**Objective:** 
Implement the C++ Ringbuffer library by strictly following the specifications defined in `ringbuffer/prompts/common/cpp/functional.md`.

**Process:**
1. **Target Selection**:
   - **Targeting**: 
     - **Specified Platform**: If the user request specifies a target platform (e.g., "implement functional for debian"), verify its existence in `ringbuffer/src/`. If the requested platform is missing from `ringbuffer/src/`, inform the user that the OS is not currently implemented and list all operating systems that are currently supported (those present as directories in `ringbuffer/src/`). Process only the requested platforms that are implemented.
     - **General Request**: Otherwise, iterate through **all** OS directories found in `ringbuffer/src/` (e.g., debian, fedora, macos).
   - **Entry Point**: When targeting a specific OS, first consult `ringbuffer/prompts/<os>/cpp/create_functional.md` (if it exists) for immediate requirements and platform-specific directives.
   - **Language**: This workflow specifically targets the C++ implementation.

2. **Execution Steps**:
   For the selected OS directory, perform the following:

   0. **Environment Setup**:
      - **Navigate**: `cd ringbuffer/src/<os>/cpp`
      - **Log Initialization**: Create the log directory `logs/` if it does not exist. Initialize `functional.log` with the start timestamp and action description as per the "Generation Process Logging" requirement.

   1. **Header Implementation**:
      - Implement the primary interface `ringbuffer.hpp` and the enums in `status.hpp` first.
      - Ensure the **Mandatory Public Interface** and **Hierarchy** requirements are met exactly.
      - Log each file creation in `functional.log` immediately after the file is written.

   2. **Implementation Class & Logic**:
      - Implement `swtr_ringbuffer_impl.hpp` ensuring all required standard headers are included.
      - Implement the operational `.cpp` files (e.g., `Lifecycle.cpp`, `ReadOps.cpp`, etc.) following the **File Mapping Table**.
      - Strictly adhere to the **Function Distribution** rule (maximum 3 functions per file).
      - Implement the **Include Discipline** (primary header first, then alphabetical standard headers).
      - Log each file creation in `functional.log` immediately after the file is written.

   3. **Accessor Implementation**:
      - Create the specific `Accessors_[GroupName].cpp` files as defined in the functional specification to minimize git collisions.
      - Log each file creation in `functional.log` immediately after the file is written.

   4. **Documentation**:
      - Create the `README.md` in the source directory describing the library and build instructions.
      - Log the creation of `README.md` in `functional.log`.

   5. **Final Self-Audit**:
      - Perform the **Final Verification Step** listed at the end of `functional.md`:
        - Check Interface Match, Hierarchy Match, Thread Safety (atomics), File Distribution (3-function limit), Include Order, and Naming (trailing underscores).
      - Rectify any discrepancies found during the audit.

   6. **Finalize Logs**:
      - Append a final entry to `functional.log` stating that the functional implementation is complete.
      - Calculate and include the total elapsed time since the start timestamp in this final entry.

**Reporting:**
Once implementation is complete, generate a summary report at `ringbuffer/src/<os>/reports/implementation_report.md`:

# Implementation Report - [OS Name]
**Date:** [YYYY-MM-DD HH:MM:SS]
**Start Time:** [YYYY-MM-DD HH:MM:SS]
**End Time:** [YYYY-MM-DD HH:MM:SS]
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
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
