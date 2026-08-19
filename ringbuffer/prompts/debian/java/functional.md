# Java Functional Spec — <OS>

**Note:** Java is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/java/functional.md` as the primary specification.
No platform-specific functional overrides are needed for Java on <OS>.

## Functional Notes
- **Three-stage pipeline**: Independent read, transform, and write stages operating on a shared pool of buffer slots.
- **Status-driven coordination**: Slots transition through states (`readyforread` → `readyfortransform` → `readyforwrite` → `readyforread`).
- **Cooperative cancellation**: Pipeline stages support graceful shutdown via a stop signal.
- **Test matrix**: T001-T007 applies to all implementations.
