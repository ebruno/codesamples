# Java Build — FreeBSD 14

**Note:** Java is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/java/build.md` and `prompts/common/java/functional.md` as the primary specifications.
No platform-specific build overrides are needed for Java on FreeBSD 14.

## Build Notes
- **Build System**: Apache Maven (`pom.xml`) — identical across all platforms.
- **Native only**: FreeBSD is native-only — no containers, Dockerfiles, or `container`/`podman` targets.
- **Java version**: Primary target is Java SE 25, with fallback to 24/23/22/21 as needed.
