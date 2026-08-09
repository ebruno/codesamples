**Temporary Workspace Lifecycle:**
1. **Initialization**: Create the `ringbuffer/tmp` directory as the very first action before starting any other task.
2. **Usage**: Ensure all temporary files and scripts generated during the process are stored exclusively within `ringbuffer/tmp`.
3. **Cleanup**: Recursively delete the `ringbuffer/tmp` directory and all its contents immediately upon completion of all tasks associated with this prompt.

Please implement the Ringbuffer for macOS. 

**Directives:**
1. Use `ringbuffer/prompts/macos/cpp/functional.md` for platform-specific requirements.
2. Use `ringbuffer/prompts/common/cpp/functional.md` as the primary architectural and functional specification.

**Immediate Requirements:**
- **Logging:** Before creating any source files, initialize the logging system at `ringbuffer/src/macos/cpp/logs/` and create `functional.log` with the first entry.
- **Source Tree:** Implement the full set of files defined in the **File Mapping Table** of the common specification. 
- **Strict Compliance:** Adhere strictly to the "maximum 3 functions per file" rule and the trailing underscore naming convention for private members.
- **Location:** All generated source code and the `LICENSE` file must be placed in `ringbuffer/src/macos/cpp`.
- **State Tracking:** Upon completion, create a `.gen_state.json` file in `ringbuffer/src/macos/cpp` containing the SHA-256 hashes of the prompts used and the fingerprints of all generated files to support future incremental updates.

Perform the 'Final Verification Step' self-audit before finishing to ensure absolute compliance with the interface and architectural constraints.
