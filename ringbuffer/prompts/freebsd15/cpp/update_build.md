# Update Build System - FreeBSD 15

**Objective:** Update the build configuration to reflect changes in the source tree or build specifications.

**Inputs:**
1. The current build file (e.g., `Makefile` or `CMakeLists.txt`).
2. The current list of files in `src/freebsd15/cpp`.
3. `ringbuffer/prompts/freebsd15/cpp/build.md`.

**Instructions:**
- **Source Sync:** If new `.cpp` or `.hpp` files have been added to the source tree, add them to the build targets.
- **Cleanup:** Remove references to any files that have been deleted.
- **Flag Update:** If `build.md` has updated compiler flags or optimization levels, apply them to the build script.
- **Validation:** Ensure the build script still produces the target binary with the correct visibility settings (`-fvisibility=hidden`).

**State Management:**
- **Spec Hash Update:** Update the hash of the platform-specific `build.md` in `.gen_state.json` upon completion.

**Documentation Synchronization:**
- **README Update:** If the build or testing changes affect the high-level project status (e.g., a platform is now "WIP" instead of "TBS"), use `ringbuffer/prompts/common/generate_toplevel_readme.md` to update the top-level `README.md`.

**Output:**
- The updated build file.
