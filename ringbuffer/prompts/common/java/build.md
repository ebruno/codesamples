# Build Requirements — Ringbuffer (Java)

**Implementation Directive:**
This build specification MUST be followed exactly to ensure consistency across platforms. Platform-specific deviations are permitted only for JDK version requirements and native library access.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/java/build.md`) conflict with common specs (`prompts/common/java/build.md`), the platform-specific spec takes precedence for JDK version and native library details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

## Language Standards
- **Primary Version**: Java SE 25 (JDK 25)
- **Fallback Versions** (in priority order): Java SE 24, Java SE 23, Java SE 22, Java SE 21, Java SE 20, Java SE 19, Java SE 18, Java SE 17
- **Minimum Supported**: Java SE 17 (LTS) — all implementations MUST be compatible with this version
- **Encoding**: UTF-8

## Build System: Maven
All Java builds MUST use Apache Maven as the build system. The project root for each platform MUST contain a `pom.xml` file.

### Maven Configuration
- **Group ID**: `com.swtr`
- **Artifact ID**: `ringbuffer`
- **Packaging**: `jar` (with shaded/uber-jar for distribution)
- **Java Version**: Platform-specific minimum JDK version (see platform spec). Common default: Java SE 25.
- **Encoding**: UTF-8

### Required Maven Dependencies
No external dependencies are required for the core ringbuffer library. The `pom.xml` MUST NOT include any third-party dependencies in the common spec. Platform-specific native access (e.g., JNI for file descriptor I/O) may add platform-scoped dependencies.

### Required Maven Plugins
The `pom.xml` MUST include the following plugins:

1. **maven-compiler-plugin**: Configure source and target to the platform-specific Java version. Example configuration:
   ```xml
   <plugin>
       <groupId>org.apache.maven.plugins</groupId>
       <artifactId>maven-compiler-plugin</artifactId>
       <version>3.13.0</version>
       <configuration>
           <release>25</release>
           <encoding>UTF-8</encoding>
       </configuration>
   </plugin>
   ```
2. **maven-jar-plugin**: Configure the main class for the executable JAR (if applicable).
3. **maven-shade-plugin**: Create an uber-jar with all dependencies shaded (for distribution).

### Required Maven Targets
The following Maven targets MUST be supported:

| Target | Description |
|--------|-------------|
| `mvn compile` | Compile all Java source files |
| `mvn package` | Build the JAR (including shade) |
| `mvn test-compile` | Compile test sources |
| `mvn test` | Run all tests |
| `mvn clean` | Remove the `target/` directory |

### Artifact Naming
The built JAR MUST follow Maven conventions: `<artifactId>-<version>.jar`. The version is defined in `pom.xml` as `${project.version}`.

### Source Directory Structure
```
src/common/java/
├── pom.xml                          # Maven build configuration
└── swtr/                            # Package directory (package swtr;)
    ├── BufferStatus.java
    ├── ChecksumAlgorithm.java
    ├── LogLevel.java
    ├── RingBuffer.java
    ├── TransformFunction.java
    ├── ErrorHandler.java
    ├── BufferSlot.java
    └── SwtrRingBuffer.java
```

### Test Directory Structure
```
src/common/java/
├── pom.xml
└── swtr/
    ├── (main sources as above)
    └── test/                        # Test sources under swtr/test/
        └── TestRingbuffer.java      # Single test file, CLI dispatches to T001-T007
```

### Build Process
1. **Compile**: `mvn compile` — compiles all Java source files to `target/classes/`.
2. **Package**: `mvn package` — creates the JAR in `target/`.
3. **Test**: `mvn test` — runs the test suite and generates reports in `target/surefire-reports/`.
4. **Clean**: `mvn clean` — removes the `target/` directory.

### Platform-Specific Considerations
- **macOS**: Use the native JDK (e.g., Homebrew `openjdk` or Oracle JDK). No container support.
- **Linux**: Use the platform-appropriate JDK package (e.g., `openjdk-25-jdk` on Ubuntu, `java-25-openjdk` on Fedora).
- **Container builds**: If building in a container, the Dockerfile MUST install the required JDK before running Maven.

### Temporary Workspace
- All temporary files MUST be placed in `target/` (Maven convention) or a `tmp/` directory.
- Do NOT create temporary files in the project root or source directories.

### Build Process Logging
- Create a directory at `src/common/java/logs/`.
- Log build actions to `build.log` in the format: `[YYYY-MM-DD HH:MM:SS +/-HHMM] <Action Description>`.
- Append to existing log files; do NOT overwrite.

### Scope Boundary — Build Phase Only
The purpose of this prompt is to compile the library and produce artifacts in `target/`. **Your task ends once the JAR file exists.**

You MUST NOT:
- Run `mvn test` or any testing workflow
- Generate test data, compile test binaries, or execute any tests
- Proceed to verification, reporting, or test matrix execution

**Directory Scope Restriction:**
- **NEVER create, modify, or delete any files inside the `tests/` directory.** This directory is managed exclusively by testing-related prompts. Build-only prompts must treat it as read-only.

### Excluded Platforms
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development.
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/`.
