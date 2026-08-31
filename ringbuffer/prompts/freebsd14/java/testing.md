# Java Testing — FreeBSD 14

**Note:** Java is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/java/functional.md` and `prompts/common/java/build.md` as the primary specifications.
No platform-specific overrides are needed for Java on FreeBSD 14.

## Execution Notes
- **Build System**: Apache Maven (`pom.xml`) — identical across all platforms.
- **Native only**: FreeBSD is native-only — no containers, Dockerfiles, or `container`/`podman` targets.
- **Java version**: Primary target is Java SE 25, with fallback to 24/23/22/21 as needed.
