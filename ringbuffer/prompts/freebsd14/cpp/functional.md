# C++ Functional — FreeBSD 14

**Note:** This is a placeholder pointing to the authoritative FreeBSD C++ functional spec.
For actual implementation details, see `prompts/freebsd/cpp/build.md` (generic FreeBSD 14.x/15.x spec) and `prompts/common/cpp/functional.md` (common requirements).

## Functional Notes
- The C++ implementation follows the common spec: three-stage pipeline (read → transform → write) with status-driven coordination.
- Error handling uses C++ callbacks for cooperative cancellation.
- Version reporting: detect `clang++ --version` at runtime, log to functional.log and build.log.
