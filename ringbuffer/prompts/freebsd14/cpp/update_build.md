# Update Build System - FreeBSD 14

**Objective:** Update the build configuration to reflect changes in the source tree or build specifications.

**Inputs:**
1. The current build file (e.g., `Makefile` or `CMakeLists.txt`).
2. The current list of files in `src/freebsd14/cpp`.
3. `ringbuffer/prompts/freebsd14/cpp/build.md`.

**Instructions:**
- **Source Sync:** If new `.cpp` or `.hpp` files have been added to the source tree, add them to the build targets.
- **Cleanup:** Remove references to any files that have been deleted.
- **Flag Update:** If `build.md` has updated compiler flags or optimization levels, apply them to the build script.
- **Validation:** Ensure the build script still produces the target binary with the correct visibility settings (`-fvisibility=hidden`).

**State Management:**
- **Spec Hash Update:** Update the hash of the platform-specific `build.md` in `.gen_state.json` upon completion.

**Output:**
- The updated build file.
