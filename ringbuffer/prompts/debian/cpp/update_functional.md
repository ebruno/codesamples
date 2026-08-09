# Update Functional Implementation - Debian

**Objective:** Synchronize an existing source file with the updated functional specifications while minimizing unnecessary churn.

**Inputs:**
1. The current content of the target file.
2. `ringbuffer/prompts/debian/cpp/functional.md` (Platform Specifics).
3. `ringbuffer/prompts/common/cpp/functional.md` (Primary Specification).

**Instructions:**
- **Analyze Diffs:** Compare the current file implementation against the updated specifications.
- **Targeted Edits:** Apply only the changes required to bring the file into compliance with the new spec.
- **Preservation:** Do not rewrite sections of the code that are already compliant and not affected by the spec change.
- **Constraint Check:** Ensure the "maximum 3 functions per file" rule is still maintained. If a change pushes a file over 3 functions, you MUST signal that a new numbered file (e.g., `LoggingOps_2.cpp`) needs to be created.
- **Verification:** Ensure the trailing underscore naming convention for private members is preserved.

**Output:**
- The updated content of the file.
- A brief summary of what was changed and why.
