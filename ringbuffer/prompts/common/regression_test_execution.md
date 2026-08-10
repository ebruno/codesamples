# Regression Test Execution and Reporting

**Objective:** Execute the build, run verification tests, and generate reports. This file covers execution only; infrastructure setup is in `regression_test_infrastructure.md`.

**Prerequisite:** Infrastructure setup from `regression_test_infrastructure.md` must be completed before proceeding.

## Execution Steps

7. **Consolidated Build and Verification**:
   - **Timeout Limit**: Container execution timeouts must be limited to a maximum of 600,000 ms (10 minutes).
   - **Navigate**: `cd ringbuffer/src/<os>`
   - **Execute (Split Pipeline)**:
     - Use `JOBS` (e.g., 4 or 8) to enable parallel compilation.
     - **Step 1: Build Library and Tests**:
       - **Native**: `cd cpp && make clean && make -j\$(JOBS) && if [ -d tests ]; then cd tests && make clean && make -j\$(JOBS); else echo 'ERROR: Tests directory missing.'; exit 1; fi`
       - **Container**: `<runtime> run --rm -m <memory_limit> -v \$(pwd):/app ringbuffer_<os>_test sh -c "cd /app/cpp && make clean && make -j\$(JOBS) && if [ -d tests ]; then cd tests && make clean && make -j\$(JOBS); else echo 'ERROR: Tests directory missing.'; exit 1; fi"`, where `<runtime>` is `container` on macOS or `podman` on Linux.
     - **Step 2: Run Verification**:
       - **Native**: `cd cpp && make verify`
       - **Container**: `<runtime> run --rm -m <memory_limit> -v \$(pwd):/app ringbuffer_<os>_test sh -c "cd /app/cpp && make verify"`, where `<runtime>` is `container` on macOS or `podman` on Linux.
   - **Timing Requirements**:
     - **Start Time**: The report `Start Time` MUST be captured at the exact moment the `make verify` target is invoked in the `tests/Makefile`.
     - **End Time**: The report `End Time` MUST be captured immediately after the final test scenario (T007) in the test matrix has completed its execution.
   - **Verify Artifacts**:
     - Confirm that both `test001_staticlib` and `test001_dynamiclib` were created in the `bin/` directory of the tests folder.
     - Confirm that the `make verify` target passed for the main library.
     - **JUnit Report**: Confirm that `tests/reports/regression_report_junit.xml` was generated and follows the required JUnit XML structure.
   - **Evaluate**: If any step fails, follow the procedure below. Do NOT loop indefinitely.

      **Build/Verification Failure Procedure:**
      1. Capture the full error output (compiler errors, linker errors, test failures).
      2. Analyze the logs to determine the root cause:
         - **Compiler errors**: Check for missing includes, type mismatches, or syntax errors in the source files.
         - **Linker errors**: Verify that all object files are present and that library dependencies are correctly specified.
         - **Test failures**: Compare actual output against expected results in `tests/data/expected/`.
      3. Apply the minimal fix required to address the root cause.
      4. Retry the **entire consolidated pipeline** (build + verify) at most **2 times**.
      5. If all retries fail, STOP and report the final failure with:
         - The original error output
         - A list of all fixes attempted
         - A recommendation to investigate manually
         ```
         BUILD/VERIFICATION FAILED — [OS Name]

         Fixes attempted:
         - <fix 1>: <description>
         - <fix 2>: <description>

         Final error: <last error output>

         Recommendation: Investigate the root cause manually. Check `cpp/logs/build.log` and `tests/logs/` for detailed output.
         ```

## Reporting

For each platform processed, generate a detailed report at `ringbuffer/src/<os>/reports/regression_report.md` using the following format:

# Regression Verification Report - [OS Name]
**Date:** [YYYY-MM-DD HH:MM:SS ±HHMM]
**Start Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
**End Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
**Elapsed Time:** [Duration]
**Host OS:** [Host OS Name/Version]

## Status
**Final Result:** [PASS / FAIL]

## Audit Trail
- **Compiler**: [Version output from -v]
- **Linker**: [Version output from -v]

## Test Results
| Test ID | Description | Result | Execution Time | Note |
| :--- | :--- | :--- | :--- | :--- |
| T001 | Exact match with input | [PASS/FAIL] | [Time] | [Brief note] |
| T002 | Stress test (1 slot, 1 byte) | [PASS/FAIL] | [Time] | [Brief note] |
| T003 | All chars uppercase | [PASS/FAIL] | [Time] | [Brief note] |
| T004 | Input < 1 slot (fast EOF) | [PASS/FAIL] | [Time] | [Brief note] |
| T005 | Pipeline stop (Fatal Error) | [PASS/FAIL] | [Time] | [Brief note] |
| T006 | Pipeline continues (Non-fatal) | [PASS/FAIL] | [Time] | [Brief note] |
| T007 | Bit-inverted output | [PASS/FAIL] | [Time] | [Brief note] |

## Fixes and Modifications
*If files were modified to achieve a successful build, list them here:*
- `path/to/file`: [Brief explanation of the fix]

## Verification Details
- **Library Build**: [Success/Failure] - [Brief note on logs/errors]
- **Test Build**: [Success/Failure] - [Brief note on logs/errors]
- **Artifacts Verified**: [Yes/No] (Architecture, SONAME/Install Name, Binary Size)

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
<EOF>
