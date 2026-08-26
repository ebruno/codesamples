# New Operating System Setup Workflow

**Objective:**
Interactively guide the user through adding a new operating system to the Ringbuffer project. This workflow collects all necessary information, classifies the OS, creates the required directory structure and prompt files, and produces a ready-to-use platform scaffold.

**Inputs:**
1. **OS Name**: The operating system to add (e.g., `fedora`, `debian`, `macos`). This becomes the directory name under `prompts/<os>/` and `src/<os>/`.
2. **Languages** (optional): Comma-separated list of languages to support. Defaults to `cpp` if not specified. Supported: `c`, `cpp`, `java`, `go`, `python`, `rust`.

---

## Session Management Commands

These commands can be entered at **ANY step** (instead of answering the current question):

| Command | Action |
|---------|--------|
| `:q`    | Quit — ask if user wants to save current state, then prompt for description |
| `:wq`   | Quit and save — save session with description, then exit (no extra prompt) |
| `:ls`   | List all sessions for the current OS name (shows filename, step, state, description) |
| `:rm <index>` | Delete a session by its index from the :ls listing |
| `:rm *`   | Delete all sessions for the current OS name |
| `:status` | Show current session state (all collected answers, implementation_state) without advancing |
| `:state <new_state>` | Manually update the implementation state (e.g., `:state functional_implemented`) |
| `:templates` | List all available templates (filename, name, description, source) |
| `:load-template <name>` | Load a template by name (e.g., `:load-template fedora`) — available at any step |
| `:save-template [name]` | Save current session as a new template (see below) |
| `:update-template` | Update the source template with changed fields — only available if session was loaded from a template (see diff below) |
| `:help`   | Show all available session management commands with descriptions |

### :ls Output Format
```
Sessions for '<os_name>':
  [0] new_os_setup_fedora_20260815_143000.json — Step 9/9 — scaffolded — "Fedora 44 with clang" — in_progress — 2026-08-15T14:30:00
  [1] new_os_setup_fedora_20260814_091500.json — Step 7/9 — functional_implemented — "Initial attempt" — abandoned   — 2026-08-14T09:15:00
```

### :templates Output Format
```
Available templates:
  [0] Fedora — RPM-based, dnf package manager, semver versioning (source: fedora)
  [1] Debian — DEB-based, apt package manager, semver versioning (source: debian)
```

### :help Output Format
```
> :help

Session Management Commands:
  :q                  Quit — ask if user wants to save current state
  :wq                 Quit and save — save session with description, then exit
  :ls                 List all sessions for the current OS name
  :rm <index>         Delete a session by its index from the :ls listing
  :rm *               Delete all sessions for the current OS name
  :status             Show current session state without advancing
  :state <new_state>  Update implementation state (e.g., functional_implemented)
  :templates          List all available templates
  :load-template <n>  Load a template by name (e.g., fedora)
  :save-template [n]  Save current session as a new template
  :update-template    Update the source template with changed fields (diff-based)

Enter any command at any step to access these features.
```

### :load-template Output Format
```
> :load-template fedora

Loaded template 'Fedora':
  Classification: containerized_amd64, Package Manager: dnf, Base Image: fedora:44
  Compiler: g++, Default Languages: cpp

All fields populated with template defaults. You can modify any field during the session.
[Session saved: .ringbuffer_sessions/new_os_setup_<os_name>_<timestamp>.json]
```

### :save-template Output Format
```
> :save-template rocky-linux

Save current session as template 'rocky-linux'? (y/n) y
Add a description for this template? [skip] Rocky Linux 9 — RHEL derivative, dnf package manager

Template saved: prompts/common/templates/template_rocky_linux.json
  Template Name: Rocky Linux
  Source Distro: rocky-linux
  Classification: containerized_amd64
  Package Manager: dnf

The template is now available via :templates and can be loaded by other users.
```

### :update-template Output Format (diff-based)
```
> :update-template

This session was loaded from template 'Fedora'. The following fields have changed:

  Field                | Template Value          | Session Value
  ---------------------|-------------------------|------------------
  compiler             | g++                     | clang++
  prerequisite_packages | [gcc, gcc-c++, make]   | [gcc, gcc-c++, make, strace]

Which changes to apply?
  [1] Apply change 1 only (compiler)
  [2] Apply change 2 only (prerequisite_packages)
  [3] Apply all changes

Enter choice (1-3, or 'q' to cancel): 3

Updating template 'Fedora':
  [1] compiler: g++ → clang++ ✓
  [2] prerequisite_packages: [gcc, gcc-c++, make] → [gcc, gcc-c++, make, strace] ✓

Template 'Fedora' updated. Changes saved to prompts/common/templates/template_fedora.json.
```

**Guard:** `:update-template` is only available when `source_template` is set. If called on a fresh session: "This session was not loaded from a template. Use `:save-template` to create a new one."

---

## Session Storage

**Location:** `<workspace_root>/.ringbuffer_sessions/`
- Hidden directory at workspace root, clearly transient.
- **Gitignored** — added to `.gitignore`.
- **Cleaned by `dist-clean`** — the top-level Makefile's `dist-clean` target removes it.
- Created on first use.

**Filename format:** `new_os_setup_<os_name>_<YYYYMMDD_HHMMSS>.json`
- Example: `new_os_setup_fedora_20260815_143000.json`
- Auto-resume: On startup, scan for matching files and offer the newest first.

**Template storage:** `prompts/common/templates/`
- Git-tracked, one file per family: `template_<family>.json`
- No timestamp — updated in place.

---

## Session JSON Structure

```json
{
  "os_name": "",
  "languages": [],
  "classification": null,
  "os_family": "",
  "detection_method": "",
  "min_macos_version": null,
  "host_detection_command": "",
  "os_id": "",
  "version_model": null,
  "package_manager": "",
  "is_debian_derivative": false,
  "distinguishing_file": "",
  "architecture": null,
  "base_image": "",
  "has_arm64_container": true,
  "additional_packages": [],
  "compiler": "",
  "binary_analysis_tool": null,
  "api_notes": "",
  "session_description": "",
  "source_template": null,
  "is_template": false,
  "template_name": null,
  "template_description": null,
  "implementation_state": "scaffolded",
  "current_step": 0,
  "dry_run": false,
  "timestamp": "2026-08-15T14:30:00-07:00",
  "status": "in_progress"
}
```

**Implementation State Values:**

| State | Meaning | When Set |
|-------|---------|----------|
| `scaffolded` | Prompt files and Dockerfile created by this workflow | After Step 9 completes (normal mode) |
| `functional_implemented` | Source code generated via create_functional.md | Set manually after successful functional generation |
| `build_tested` | Build succeeded via create_build.md | Set manually after successful build |
| `regression_passed` | T001–T007 tests passed via create_regression.md | Set manually after successful regression |
| `officially_supported` | Added to README.md Supported Platforms and .bionic classification table | Set manually after all tests pass and docs updated |

**State transitions:** `scaffolded → functional_implemented → build_tested → regression_passed → officially_supported`

---

## Interactive Session Flow

This workflow is **interactive**. At each step, present the question to the user and wait for their response before proceeding. If a reasonable default can be inferred, suggest it but still ask for confirmation.

### Step 0 — Startup: Session Recovery + Template Loading

**At the very beginning of the workflow, BEFORE asking any questions:**

A. **Session Recovery Check**
   1. Scan `.ringbuffer_sessions/` for files matching `new_os_setup_<os_name>_*.json`
   2. If any exist, sort by timestamp (newest first) and offer each:
      ```
      Found session for '<os_name>': <filename> (Step N/9, state: <state>, description: '<desc>', last updated <timestamp>). Load it? (y/n)
      ```
   3. If user loads a session:
      - Restore all fields from JSON (including dry_run flag and implementation_state)
      - Print: "Loaded session from <timestamp>. Current step: Step N — <description> (state: <implementation_state>)"
      - Re-present the current step's question (user can change their answer)
      - Jump to that step and continue
   4. If no sessions found or user declines all: proceed as fresh session

B. **Template Loading Check** (only if no session found)
   1. Scan `prompts/common/templates/` for all template files
   2. If any exist, present them:
      ```
      No existing session found for '<os_name>'. Would you like to start from a template? (y/n)
      ```
   3. If yes:
      ```
      Available templates:
        [0] Fedora — RPM-based, dnf package manager, semver versioning (source: fedora)
        [1] Debian — DEB-based, apt package manager, semver versioning (source: debian)

      Choose a template (0-1) or press Enter to skip:
      ```
   4. If user selects a template:
      - Load the template JSON into session fields
      - Set `source_template = "<template_name>"`
      - Print: "Loaded template '<name>' — all fields populated with defaults. You can modify any field during the session."
      - Proceed to Step 0b with template defaults pre-filled

C. **Dry-Run Question** (fresh sessions only, or after template load)
   ```
   Would you like to run in dry-run mode? (y/n) [default: n]
   ```
   - If yes: set `dry_run = true`, continue collecting answers without creating files
   - If no: normal mode

---

### Step 0b — OS Name and Language Selection

**Ask the user:**
```
What operating system would you like to add?

Enter the OS name (this will be used as the directory name, e.g., "fedora", "debian", "macos"):
```

- Validate: The name should be lowercase, no spaces (use hyphens if needed).
- Default language: `cpp` (unless the user specifies otherwise).

**Language Selection:**
```
Which languages should this OS support? Enter a comma-separated list. [default: cpp]
```

If languages array is pre-populated from template (e.g., `["cpp"]`):
```
Languages from template: <comma-separated list>. Change? (y/n) [default: n]
```

**Confirm:** "You're adding support for `<os>` with languages: <comma-separated list>. Proceed?"

---

### Step 1 — OS Classification

Present the classification table and ask the user to choose:

```
How will this OS be built? Choose one:

  [1] Native-only     — Builds directly on the host. No containers, no Dockerfiles.
                          (Example: macOS)

  [2] Containerized   — Runs inside a container. Works on Apple Silicon natively
                          if the image is arm64.
                          (Example: Fedora, Debian, Ubuntu)

  [3] Linux-hosts-only — Container image is amd64-only. Source generation works
                          everywhere; build/test requires a Linux host with podman/docker.
                          (Example: Arch Linux)

  [4] Excluded         — Placeholder only, zero-length files. No active development.
                          (Example: FreeBSD 14/15)

Enter your choice (1-4):
```

**Classification decisions:**
- If **Native-only**: No Dockerfile needed. macOS-style build with native toolchain.
- If **Containerized**: Need a Dockerfile at `src/<os>/<lang>/containers/Dockerfile`.
- If **Linux-hosts-only**: Need macOS skip logic in build prompts.
- If **Excluded**: Create only zero-length placeholder files; do NOT create Dockerfile or container directory.

---

### Step 2 — OS Identification

Ask the user for identification details:

```
How is this operating system identified?

a) macOS — Use `sw_vers --productVersion`
b) Linux — Read from `/etc/os-release` (ID= field)
c) Other — Describe the detection method

Enter your choice (a/b/c):
```

**If macOS:**
- Ask for minimum supported version: "What is the minimum macOS version? (default: 15)"
- Ask for host detection command: "Host detection command? (default: `sw_vers --productName`)"

**If Linux:**
- Ask for the OS identifier: "What is the `ID=` value in `/etc/os-release`? (e.g., 'fedora', 'debian', 'arch')"
- Ask for the version model: "What is the versioning model?"
  - [1] Point release (e.g., `VERSION_ID=44`) — semver-based
  - [2] Rolling release (no `VERSION_ID`) — always latest
  - [3] Datestamp-based (e.g., `archlinux:2026.08.01`)
- Ask for the package manager: "Which package manager?" (apt, dnf, pacman, zypper)
- If Debian-based: "Is this a derivative that shares an ID with another OS? (e.g., Raspberry Pi OS shares `ID=debian`)"
  - If yes: "What is the distinguishing file? (e.g., `/etc/rpi-issue`)"

**If Other:**
- Ask the user to describe the detection method and file paths.

---

### Step 3 — Architecture and Container Image

```
What architecture does this OS target?

  [1] arm64 (aarch64) — Apple Silicon, Raspberry Pi
  [2] x86_64 (amd64) — Intel/AMD processors
  [3] Both (universal/fat binary)

Enter your choice (1-3):
```

**If Containerized or Linux-hosts-only:**

Ask for container image details:
```
What is the base container image?

Format: <registry>/<image>:<tag>

Examples:
  - fedora:44
  - debian:13
  - ubuntu:24.04
  - archlinux:2026.08.01
  - vascoguita/raspios:arm64-bookworm-20251204

Enter the base image (or 'none' if native-only):
```

**If Linux-hosts-only:** Ask: "Does this OS have an ARM64 container image available?"
- If no → Document macOS skip logic.

---

### Step 4 — Toolchain Details

```
What compiler/toolchain should be used by default?

Examples:
  - clang++ (macOS default)
  - g++ / gcc (Linux default)
  - clang (alternative on Linux)

Enter the default compiler:
```

Ask for binary analysis tools:
```
What binary analysis tool is used on this platform?

  [1] otool — macOS (Mach-O)
  [2] readelf — Linux (ELF)
  [3] file — Universal fallback

Enter your choice (1-3):
```

---

### Step 5 — Platform-Specific API Notes and Additional Packages

For C/C++ implementations, ask about platform-specific behaviors:

```
Are there any platform-specific API or libc differences?

Examples:
  - macOS: F_FULLFSYNC instead of fsync(), @rpath install names, BSD libc
  - Linux: Standard POSIX, glibc version considerations
  - Embedded: Limited libc features

Describe any platform-specific notes (or press Enter to skip):
```

**Additional Packages:**
```
Would you like to specify additional packages beyond the defaults? (y/n) [default: n]

If yes:
  → "Enter additional package names, separated by whitespace or commas. Press Enter on an empty line to finish."
  - Example input: "doxygen strace, python3"
  - Parse into individual package names, store in additional_packages array
  - These are appended to the template's prerequisite_packages for Dockerfile and build.md generation
```

---

### Step 6 — Create the Scaffold

Once all information is collected, create the following for **each language** in the languages array:

**Directory structure (per language):**
```
prompts/<os>/<lang>/
├── create_functional.md
├── create_build.md
├── create_regression.md
├── functional.md
├── build.md
├── testing.md
├── update_functional.md
├── update_build.md
└── update_testing.md
```

**If containerized (per language):**
```
src/<os>/<lang>/containers/
└── Dockerfile
```

**If excluded:** Create zero-length files only.

---

### Step 7 — Generate Prompt Files (per language)

Generate each prompt file using the collected information. Use these templates:

#### `functional.md` — Platform-Specific Functional Requirements
```markdown
# Functional Requirements - Ringbuffer (<OS Name>, <Language>)

**Implementation Directive:**
This implementation MUST follow the common functional specification exactly to ensure cross-platform symmetry.
Refer to the common specification for all architectural, interface, and implementation details:
[prompts/common/<lang>/functional.md](../../common/<lang>/functional.md)

**Platform Specifics:**
- **Target OS**: <OS Name> (<version description>)
- **OS Identification**: <detection method, e.g., ID=<id> in /etc/os-release or sw_vers --productVersion>
- **Architecture**: <arm64/x86_64/both> — <Apple Silicon compatibility notes if applicable>
- **Toolchains**: <default compiler> (primary), <fallback compilers if any>
- **License**: BSD 3-Clause License. The `LICENSE` file must be created in `src/<os>/<lang>/`.

**Platform-Specific API Notes:**
- <Any libc differences, POSIX feature availability, or platform-specific behaviors>

**Tooling and Recovery:** See `prompts/common/<lang>/functional.md` for the authoritative tooling and recovery directives.
```

#### `build.md` — Platform-Specific Build Requirements
```markdown
# Build Requirements - Ringbuffer (<OS Name>, <Language>)

**Implementation Directive:**
This build specification MUST follow the common build specification exactly to ensure binary symmetry.

Refer to [prompts/common/<lang>/build.md](../../common/<lang>/build.md) for the Platform and Container Runtime Reference.

**Platform Specifics:**
- **Target Environment**: <OS Name> (<version description>)
- **Prerequisites**: Install the following packages via `<package_manager>`:
    - <list of required packages>

## Required Tools
- `<compiler>` (Compiler/Linker)
- `make` (Orchestrator)
- `<binary_analysis_tool>` (Binary Analysis)

## Containerized Build Environment (<classification>):
<If containerized:>
- **Base Image**: <image>:<tag>
- **Toolchain Installation**: Use `<package_manager>` to install required packages
- **Container Path**: `src/<os>/<lang>/containers/Dockerfile`

<If Linux-hosts-only:>
## macOS Skip Logic
This OS container images are <architecture>-only. On Apple Silicon (M-series) Macs, there is no <architecture> container available. The `container` target in the Makefile MUST detect macOS and skip gracefully:

```makefile
ifeq ($(UNAME_S),Darwin)
    @echo "[<os>] Skipping container build on macOS — <OS name> containers are <architecture>-only."
    @echo "[<os>] Source code generation is supported; build/test requires a Linux host."
    @exit 0
endif
```

When running on macOS, the script MUST log to `build.log`:
```
[timestamp] <OS name> container build skipped on macOS (Apple Silicon) — no <architecture> container available.
[timestamp] Source code generation is supported; build/test requires a Linux host with podman/docker.
```

<If native-only:>
## Host Detection
- **Host Detection**: Verify the host OS using <detection command>.
- **Container Prohibition**: This platform is native-only. No containerized builds are supported.
```

#### `create_functional.md` — Primary Functional Implementation Workflow
```markdown
**Temporary Workspace**: See `prompts/common/<lang>/functional.md` for the authoritative temporary workspace directives.

**Workflow Precedence:** This file is the **PRIMARY** execution document. The common workflow (`prompts/common/implement_functional.md`) provides version resolution and structure reference only.

# Functional Implementation Workflow — <OS Name>

**Objective:** Implement the <Language> Ringbuffer library for <OS Name> by strictly following the specifications defined in `prompts/common/<lang>/functional.md` and platform-specific requirements in `prompts/<os>/<lang>/functional.md`.

**Directives:**
1. Use `prompts/<os>/<lang>/functional.md` for platform-specific requirements.
2. Use `prompts/common/<lang>/functional.md` as the primary architectural and functional specification.

**Version Context:** <version detection method, e.g., "Detect from sw_vers --productVersion on macOS" or "Read VERSION_ID from /etc/os-release">

0. **Environment Setup**:
   - Use the version resolved by `prompts/common/implement_functional.md` Step 0.
   - Log initialization with start timestamp, action description, and resolved <OS> version.

1. **Header Implementation**:
   - Implement primary headers following `prompts/common/<lang>/functional.md`. Apply platform-specific overrides from `prompts/<os>/<lang>/functional.md`.
   - Ensure the Mandatory Public Interface and Hierarchy requirements are met.

2. **Implementation & Logic**:
   - Implement operational files following the File Mapping Table in `prompts/common/<lang>/functional.md`.
   - Strictly adhere to the Function Distribution rule (maximum 3 functions per file).
   - Implement Include Discipline (primary header first, then alphabetical standard headers).

3. **Documentation**:
   - Create the `README.md` in the source directory describing build instructions for <OS Name>.

4. **Final Self-Audit**:
   - Verify Interface Match, Hierarchy Match, Thread Safety, File Distribution, Include Order, and Naming conventions.

5. **Finalize Logs**:
   - Append completion entry to `functional.log` with elapsed time.

**Immediate Requirements:**
- Source code must be placed in `src/<os>/<lang>/`.
- Create `.gen_state.json` with SHA-256 hashes of prompts and generated files.
- Generate source code independently from the common specification — do NOT copy from other platforms.

**Reporting:**
Generate implementation report at `src/<os>/<lang>/reports/implementation_report.md`.
```

#### `create_build.md` — Primary Build Environment Creation Workflow
```markdown
**Temporary Workspace**: See `prompts/common/<lang>/build.md` for the authoritative temporary workspace directives.

**Workflow Precedence:** This file is the **PRIMARY** execution document. The common workflow (`prompts/common/implement_build.md`) provides image resolution and structure reference only.

Please configure the build system for the Ringbuffer on <OS Name>.

**Directives:**
1. Use `prompts/<os>/<lang>/build.md` for platform-specific requirements.
2. Use `prompts/common/<lang>/build.md` as the primary build specification.

**Immediate Requirements:**
- Logging: Every build step MUST be recorded in `src/<os>/<lang>/logs/build.log`.
- Configuration: Create the build configuration in `src/<os>/<lang>/`.
- Documentation: Create the `specs/` subdirectory with build.md, testing_requirements.md, and artifacts.md.
- Versioning: The build system MUST source `version.mk` for versioned artifact names.

**Dockerfile Handling**:
<If containerized:>
- Before creating the Dockerfile, check if `.dockerfile_created_by_step0` exists. If it does, augment the existing Dockerfile — do NOT rewrite or replace it.
- Execute `make container` after creating the build configuration to verify image creation.

<If Linux-hosts-only:>
- macOS Skip: On Apple Silicon Macs, the `container` target MUST detect macOS and skip gracefully with a logged message.

<If native-only:>
- Dockerfile Handling: <OS Name> builds are native-only and do not use Dockerfiles. Log: `[timestamp] Dockerfile handling skipped — <OS Name> is a native-only platform.`

**Verification Criteria:**
Before finishing, verify and log:
1. **Architecture**: Use `<binary_analysis_tool>` on library files.
2. **Cleanliness**: Verify the `clean` target removes build artifacts using the `$(RM)` macro.
3. **Artifact Verification**: Confirm expected libraries exist in `lib/`.

**Reporting:**
Generate build creation report at `src/<os>/<lang>/reports/build_creation_report.md`.
```

#### `create_regression.md` — Primary Test Infrastructure Setup Workflow
```markdown
**Temporary Workspace**: See `prompts/common/<lang>/testing.md` for the authoritative temporary workspace directives.

**Workflow Precedence:** This file is the **PRIMARY** execution document. The common workflow (`prompts/common/implement_regression.md`) provides structure reference only.

Please set up the test infrastructure for the Ringbuffer on <OS Name>.

**Directives:**
1. Use `prompts/<os>/<lang>/testing.md` for platform-specific test requirements.
2. Use `prompts/common/<lang>/testing.md` as the primary testing specification.

**Immediate Requirements:**
- Logging: Every test setup step MUST be recorded in `src/<os>/<lang>/logs/build.log`.
- Test infrastructure: Create test binaries, input data, and expected outputs for the T001-T007 test matrix.
- Deploy utility scripts to `src/<os>/<lang>/tests/utils/bin/`.

**Reporting:**
Generate test infrastructure report at `src/<os>/<lang>/reports/test_creation_report.md`.
```

#### Update Prompts (update_functional.md, update_build.md, update_testing.md)
Generate these as delta-update wrappers that reference the corresponding `create_*` prompt and add `.gen_state.json` delta detection logic.

---

### Step 8 — Generate Dockerfile (If Containerized, per language)

Generate the Dockerfile at `src/<os>/<lang>/containers/Dockerfile`:
```dockerfile
ARG BASE_IMAGE=<image>:<tag>
FROM ${BASE_IMAGE}

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive   # Adjust for RPM distros

# Install required toolchains and utilities
RUN <package_manager> install -y <prerequisite_packages + additional_packages> && \
    <cleanup command>

# Set working directory
WORKDIR /app
```

---

### Step 9 — Final Verification and Summary

After all files are created (or dry-run summary printed), present a summary to the user:

```
=== New OS Setup Complete ===

OS Name:        <os>
Languages:      <comma-separated list>
Classification: <native-only | containerized | linux-hosts-only | excluded>
Base Image:     <image>:<tag> (or N/A)

Files Created (per language):
  prompts/<os>/<lang>/ (9 prompt files × <N> languages)
  src/<os>/<lang>/containers/Dockerfile (<if containerized, × <N> languages>)

Implementation State: scaffolded
  → The OS scaffolding is complete. Next steps to reach 'officially_supported':

    1. functional_implemented — Run create_functional.md for each language
       → "Use prompts/<os>/<lang>/create_functional.md to generate source code"

    2. build_tested — Run create_build.md for each language
       → "Use prompts/<os>/<lang>/create_build.md to create the build environment"

    3. regression_passed — Run create_regression.md for each language
       → "Use prompts/<os>/<lang>/create_regression.md to set up test infrastructure"

    4. officially_supported — After all tests pass:
       → "Use prompts/common/templates/readme_template.md to regenerate README.md"
       → Update .bionic platform classification table manually or via agent

To update the implementation state, use: :state <new_state>
```

---

## Error Handling

- **OS name conflicts**: If `prompts/<os>/` already exists, ask the user: "An OS named '<os>' already exists. Do you want to overwrite? (y/n)"
- **Invalid classification**: If the user selects a classification that conflicts with their other answers (e.g., "native-only" but provides a container image), flag the inconsistency and ask for clarification.
- **Missing common spec**: If `prompts/common/<lang>/functional.md` or `build.md` does not exist for the requested language, inform the user: "Common spec files for <lang> are not yet available. This OS can be added as a placeholder, but source generation will fail until the common specs are created."
- **FreeBSD exclusion**: If the user tries to add FreeBSD 14 or 15, remind them: "FreeBSD is an excluded platform. Only zero-length placeholder files are allowed."

---

## Session Recovery and Template Management

### Session Resume
When a session is loaded:
1. All previously collected answers are restored from JSON
2. The agent **re-presents** the current step's question (so the user can change their answer)
3. The agent prints: "Loaded session from <timestamp>. Current step: Step N — <description>"
4. The user can answer, type `:q`/`:wq`, or even change their mind about the OS name (which would start a new session)

**Edge case — OS name changed:** If the user changes `os_name` after loading, the old session file is renamed to `<old_os_name>.json.bak` and a new one is created for the new name.

### Template Loading
When a template is loaded, ALL fields are populated from the template. The user can modify any field during the interactive flow:

| Field | Populated from Template? | User Can Modify? |
|-------|-------------------------|------------------|
| `os_name` | No — set by user input at Step 0 | Yes (it's the first thing asked) |
| `classification` | Yes | Yes — Step 1 re-presents the question with template default pre-filled |
| `os_family` | Yes | Yes — Step 2 re-presents the question with template default pre-filled |
| `os_id` | Yes (e.g., "fedora", "debian") | Yes — Step 2 re-presents with template default |
| `version_model` | Yes (e.g., "semver", "datestamp") | Yes |
| `package_manager` | Yes (e.g., "dnf", "apt") | Yes — Step 2 re-presents with template default |
| `architecture` | Yes (e.g., "x86_64") | Yes — Step 3 re-presents with template default |
| `base_image` | Yes (e.g., "fedora:44") | Yes — Step 3 re-presents with template default |
| `compiler` | Yes (e.g., "g++") | Yes — Step 4 re-presents with template default |
| `binary_analysis_tool` | Yes (e.g., "readelf") | Yes — Step 4 re-presents with template default |
| `prerequisite_packages` | Yes (array from template) | Yes — Step 5 additional packages appends to this list |
| `api_notes` | Yes (from template) | Yes — Step 5 re-presents with template default |
| `languages` | Yes (from template's default_languages) | Yes — Step 0b re-presents with template defaults |

**How modifications are presented:** When a step question is re-presented after loading a template, the current value (from the template) is shown as context:

```
--- Step 1: OS Classification ---
Current (from template): Containerized (amd64)

How will this OS be built? Choose one:
  [1] Native-only     ...
  [2] Containerized   ...

Enter your choice (1-4): 
```

### :update-template Behavior
When `:update-template` is called, the agent shows a diff of all changed fields and asks which changes to apply:
- Options: `[1]` Apply change 1 only, `[2]` Apply change 2 only, ..., `[N]` Apply all changes
- User can select individual changes or "all" to apply everything
- Only the selected changes are written to the template file

---

## Dry-Run Mode

When dry-run is enabled, the agent:

| Action | Normal Mode | Dry-Run Mode |
|--------|------------|--------------|
| Collect answers | Yes | Yes (same) |
| Save session file | Yes | Yes — **session is always saved** so dry-run can be resumed later |
| Print step prompts | Yes | Yes (same) |
| Create `prompts/<os>/<lang>/` files | Creates actual files | Prints: `[DRY-RUN] Would create prompts/<os>/<lang>/functional.md` for each language |
| Create Dockerfiles | Creates actual file per language | Prints: `[DRY-RUN] Would create src/<os>/<lang>/containers/Dockerfile` for each language |
| Final summary | Shows created files, implementation state | Shows `[DRY-RUN] Would create X files total across <N> languages` |
| Post-setup deferred docs (README/.bionic) | Explained in summary, not asked at scaffolding time | Skipped (no files were created) |

---

## Reference Files to Review Before Execution

Before generating any files, the agent should read these reference implementations:
- `prompts/macos/cpp/` — Native-only pattern (no containers, universal binaries)
- `prompts/raspios/cpp/` — arm64 container on Apple Silicon pattern (two-step Debian detection)
- `prompts/archlinux/cpp/` — Linux-hosts-only pattern (amd64 container, macOS skip logic)
- `prompts/common/session_hints.md` — OS detection and container runtime reference
- `README.md` Part E — Full "Adding a New Operating System" guide

---

## Notes

- All generated prompt files must follow the naming and structure conventions established by existing OS implementations.
- The `functional.md` and `build.md` files are the primary platform-specific overrides — they contain all OS-specific details.
- The `create_*.md` files are the PRIMARY execution documents that reference both common specs and platform-specific overrides.
- Update prompts (`update_*.md`) follow the same structure as `create_*.md` but add `.gen_state.json` delta detection for incremental regeneration.
- Session files in `.ringbuffer_sessions/` are gitignored and cleaned by `dist-clean`.
- Template files in `prompts/common/templates/` are git-tracked and updated in place (no timestamps).
- The `readme_template.md` workflow handles README regeneration after an OS reaches `officially_supported` state.
- `.bionic` platform classification table should be updated manually or via agent after an OS reaches `officially_supported` state.
