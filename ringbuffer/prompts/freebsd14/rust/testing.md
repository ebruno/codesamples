# Rust Testing — FreeBSD 14

**Note:** Rust is a platform-insensitive language. Test code is identical across all platforms.
Use `prompts/common/rust/testing.md` as the primary specification for testing requirements.
No platform-specific test overrides are needed for Rust on FreeBSD 14.

## Testing Notes
- All seven tests (T001-T007) must pass on FreeBSD 14.
- T005 (fatal error mode) expects exit code 1; all others expect exit code 0.
- Dynamic library testing is not possible on FreeBSD 14 due to RPATH limitation — use static library only.
- JUnit XML reports should be generated at `reports/rust/per_os/freebsd14_regression_report_junit.xml`.
