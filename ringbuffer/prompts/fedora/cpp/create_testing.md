Please implement the full testing suite for the Ringbuffer on Fedora.

**Directives:**
- Use `ringbuffer/prompts/fedora/cpp/testing.md` as the primary platform-specific directive.
- Follow all requirements in `ringbuffer/prompts/common/cpp/testing.md` for common C++ testing specifications.

**Scope of Work:**
1. **Environment Setup**: Create the container configuration (`Dockerfile`) as specified for Fedora 44.
2. **Directory Structure**: Establish the `tests/` directory structure within `ringbuffer/src/fedora/cpp/tests`, ensuring all directories contain the `.required_directory` marker.
3. **Data Generation**: Implement the four required shell scripts (`.zsh`, `.sh`, `.tcsh`, `_bin_sh.sh`) to and generate the zig-zag space pattern test files (`test001.txt` to `test005.txt`).
4. **Test Program**: Implement the `test001` program with the full CLI interface, supporting both static and dynamic linking.
5. **Build System**: Create a `Makefile` that supports `clean` and `dist-clean` targets, and handles the specific linking requirements (rpath for dynamic, direct path for static).
6. **Verification**:
    - Perform artifact verification using `file`, `readelf`, `size`, and `nm`.
    - Execute all scenarios in the **Test Matrix (T001-T007)** and verify the results against expected outcomes.
7. **Documentation**: Create a comprehensive `README.md` in the tests directory.

**Deployment Path:**
All artifacts must be placed in: `ringbuffer/src/fedora/cpp/tests`

**Definition of Done:**
The task is complete when all binaries are compiled, all test data is generated, all Test Matrix scenarios are verified, and the documentation is complete and accurate.
