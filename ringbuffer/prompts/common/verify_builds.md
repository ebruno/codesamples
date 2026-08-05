# Build Verification Workflow

**Objective:** 
Ensure the C++ implementation and its associated tests build successfully across all supported operating systems.

**Process:**
For each OS directory in `ringbuffer/src/` (e.g., debian, fedora, macos), perform the following:

1. **Library Build**:
   - **Navigate**: `cd ringbuffer/src/<os>`
   - **Execute**: 
     `container run --rm -v $(pwd):/app ringbuffer-<os>-build sh -c "cd /app/cpp && make clean && make"`
   - **Evaluate**: If this fails, analyze logs, apply fixes to the workspace, and repeat this step. If successful, proceed to the Test Build.

2. **Test Application Build**:
   - **Navigate**: `cd ringbuffer/src/<os>`
   - **Execute**: 
     `container run --rm -v $(pwd):/app ringbuffer-<os>-build sh -c "cd /app/cpp/tests && make clean && make"`
   - **Verify**: Confirm that both `test001_staticlib` and `test001_dynamiclib` were created in the `bin/` directory.
   - **Evaluate**: If this fails, analyze logs, apply fixes to the workspace (either in the library or the test source), and repeat the entire process from Step 1 (as library changes affect tests).

**Reporting:**
Provide a final summary including:
- Build status (Success/Failure) for the **Library** and **Tests** on each platform.
- A list of any files modified and a brief explanation of the fixes applied.
