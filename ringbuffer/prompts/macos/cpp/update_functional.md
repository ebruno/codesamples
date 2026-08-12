# Update Functional Implementation - macOS

**Objective:** Synchronize an existing source file with the updated functional specifications while minimizing unnecessary churn.

**Inputs:**
1. The current content of the target file.
2. `prompts/macos/cpp/functional.md` (Platform Specifics).
3. `prompts/common/cpp/functional.md` (Primary Specification).

**Instructions:**
- **Analyze Diffs:** Compare the current file implementation against the updated specifications.
- **Targeted Edits:** Apply only the changes required to bring the file into compliance with the new spec.
- **Preservation:** Do not rewrite sections of the code that are already compliant and not affected by the spec change.
- **Constraint Check:** Ensure the "maximum 3 functions per file" rule is still maintained. If a change pushes a file over 3 functions, you MUST signal that a new numbered file (e.g., `LoggingOps_2.cpp`) needs to be created.
- **Verification:** Ensure the trailing underscore naming convention for private members is preserved.

**State Management:**
- **Fingerprint Update:** After successfully updating a file, you MUST update its corresponding hash in `.gen_state.json`.
- **Spec Hash Update:** Update the hash of `common/cpp/functional.md` and the platform-specific `functional.md` in `.gen_state.json` to mark the synchronization as complete.
- **Manual Override Detection:** If you detect that the current file differs from the stored fingerprint but the specification has NOT changed, this is a **Manual Override**. You must report this to the user and ask whether to overwrite the change or absorb it into the specification.

**Documentation Synchronization:**
- **Generator Audit:** Review `prompts/common/generate_toplevel_readme.md` to determine if the README generation logic needs updating to reflect new project standards or requirements.
- **README Update:** If the project state has changed (e.g., a version bump in `version.mk`, a new feature added to the spec, or a platform status change), execute the workflow in `prompts/common/generate_toplevel_readme.md` to update the top-level `README.md`.

**Output:**
- The updated content of the file.
- A brief summary of what was changed and why.
