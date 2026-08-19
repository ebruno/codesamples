# C++ Testing — FreeBSD 14

**Note:** This is a placeholder pointing to the authoritative FreeBSD C++ testing spec.
For actual implementation details, see `prompts/freebsd/cpp/build.md` (generic FreeBSD 14.x/15.x spec) and `prompts/common/cpp/testing.md` (common requirements).

## Testing Notes
- All seven tests (T001-T007) must pass on FreeBSD 14.
- T005 (fatal error mode) expects exit code 1; all others expect exit code 0.
- Dynamic library testing is not possible on FreeBSD 14 due to RPATH limitation — use static library only.
- JUnit XML reports should be generated at `reports/cpp/per_os/freebsd14_regression_report_junit.xml`.
