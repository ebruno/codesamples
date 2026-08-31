### Part E: Adding a New Operating System

This section provides the reference guide for implementing support for a new operating system in the Ringbuffer project. It covers OS classification, identification methods, release naming conventions, container configuration, and the required prompt files. Review the existing implementations for **macOS**, **Raspberry Pi OS (raspios)**, and **Arch Linux** as reference examples — each represents a distinct deployment pattern.

#### 1. OS Classification — Container vs. Native

Every new OS must be classified by its **container support model** and **host architecture compatibility**. This classification determines how build workflows execute and whether container images are needed.

| Category | Description | Container Support | Example Platforms |
|----------|-------------|-------------------|-------------------|
| **Native-only** | Builds run directly on the host OS using native toolchains. No containers, no Dockerfiles. | None — never use containers | macOS |
| **Containerized (amd64)** | Runs inside a container on Linux hosts. May or may not work on Apple Silicon depending on architecture. | `podman` on Linux hosts; `container` on macOS (if arm64 image available) | Fedora, Debian, Ubuntu |
| **Containerized (arm64 native on Apple Silicon)** | Container image is arm64-only, which matches Apple Silicon natively. No emulation needed on M-series Macs. | `podman`/`container` with native arm64 — works on Apple Silicon without skip logic | Raspberry Pi OS |
| **Linux-hosts-only** | Container image is amd64-only with no ARM64 variant available. Arch Linux does not provide an official, standard container image for ARM architectures (e.g., Apple Silicon, Raspberry Pi). The official archlinux Docker images are built exclusively for the x86_64 architecture. Source code generation works everywhere; build/test requires a Linux host. | `podman` on Linux hosts only — macOS must skip gracefully with logging | Arch Linux |
| **Excluded** | Placeholder directories with zero-length spec files. No active development. | None | FreeBSD 15 only |

**Decision flow for a new OS:**

```
Is the OS macOS? ──────────────► YES → Native-only (no containers)
                                    │
Is the OS Linux? ───────────────► YES → Does an arm64 container image exist?
                                    │                        ├─ Yes → Containerized (arm64 native on Apple Silicon)
                                    │                        └─ No  → Does an amd64 image exist?
                                    │                                 ├─ Yes → Linux-hosts-only (macOS skip)
                                    │                                 └─ No  → Cannot containerize — evaluate native build
                                    │
Is the OS FreeBSD? ─────────────► YES → Is it FreeBSD 14? → Implemented (native-only) / FreeBSD 15 → Excluded (zero-length files only)
```

#### 2. OS Identification — How to Detect and Document an Operating System

Every OS implementation needs reliable detection methods. The following tools and files are the standard approach.

##### 2a. macOS Detection — `sw_vers`

macOS ships with the `sw_vers` command. This is the **only** supported method for macOS version detection.

```bash
# Get product version (e.g., "26.5.2")
sw_vers --productVersion

# Get product name (e.g., "macOS")
sw_vers --productName

# Get build version (e.g., "25F84")
sw_vers --buildVersion
```

**Sample output:**
```bash
$ sw_vers --productVersion
26.5.2
$ sw_vers --productName
macOS
```

**Parsing in scripts:**
```bash
# Extract major version number (e.g., "26" from "26.5.2")
macos_version=$(sw_vers --productVersion)
macos_major=${macos_version%%.*}

# Validate minimum version (e.g., must be 15 or higher)
if (( macos_major < 15 )); then
    echo "ERROR: macOS $macos_version detected, minimum required is 15"
    exit 1
fi
```

> **Note:** Valid macOS versions for this project are **15 (Sequoia) and above**. `sw_vers` is macOS-only — never use on Linux targets.

##### 2b. Universal Kernel Detection — `uname`

The `uname` command works on all Unix-like systems and provides the kernel name.

```bash
# Returns "Darwin" on macOS, "Linux" on Linux distributions
uname -s
```

| Return Value | Host OS | Container Runtime |
|-------------|---------|-------------------|
| `Darwin` | macOS | `container` (Apple Container) |
| `Linux` | Linux distro | `podman` |

**Parsing example:**
```bash
host_os=$(uname -s)
if [[ "$host_os" == "Darwin" ]]; then
    echo "macOS host detected"
elif [[ "$host_os" == "Linux" ]]; then
    # Read distro ID from /etc/os-release (see 2c below)
    host_os=$(grep '^ID=' /etc/os-release | cut -d= -f2)
    echo "Linux host: $os_id"
fi
```

##### 2c. Linux Distribution Detection — `/etc/os-release`

The `/etc/os-release` file is the **standard** for Linux distribution identification. It uses `VARIABLE="value"` pairs.

**Primary fields for workflow detection:**

| Field | Purpose | Examples |
|-------|---------|----------|
| `ID` | Lower-case short OS identifier, safe for scripts | `fedora`, `debian`, `ubuntu`, `arch` |
| `VERSION_ID` | Version number — may be `MAJOR`, `MAJOR.MINOR`, or `MAJOR.MINOR.SUBVERSION` | `44`, `13`, `24.04` |
| `NAME` | Human-readable OS name (without version) | `Ubuntu`, `Fedora`, `Debian GNU/Linux` |
| `ID_LIKE` | Space-separated list of parent/base distributions | `debian`, `arch` |
| `VERSION_CODENAME` | Release codename (Debian-based) | `bookworm`, `trixie`, `noble` |

**Sample `/etc/os-release` files for reference:**

**macOS** — does not have `/etc/os-release`. Use `sw_vers` instead.

```bash
# macOS has no /etc/os-release — sw_vers is the detection method
sw_vers --productVersion   # e.g., "26.5.2"
```

**Raspberry Pi OS (Debian-based, arm64):**
```text
PRETTY_NAME="Raspberry Pi OS bookworm (Debian 12)"
NAME="Debian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
VERSION_CODENAME=bookworm
ID=debian
ID_LIKE=debian
HOME_URL="http://www.raspbian.org/"
SUPPORT_URL="http://www.raspbian.org/raspberrypi/"
BUG_REPORT_URL="https://www.raspbian.org/bugreport/"
```

> **Key differentiator:** Raspberry Pi OS has `ID=debian` (same as stock Debian) but also includes `/etc/rpi-issue`. Detection requires a two-step check: `ID=debian` **plus** presence of `/etc/rpi-issue`.

**Arch Linux (rolling release):**
```text
NAME="Arch Linux"
ID=arch
BUILD_ID=rolling
PRETTY_NAME="Arch Linux"
ANSI_COLOR="38;2;23;14;235"
HOME_URL="https://archlinux.org/"
DOCUMENTATION_URL="https://wiki.archlinux.org/"
SUPPORT_URL="https://bbs.archlinux.org/"
BUG_REPORT_URL="https://bugs.archlinux.org/"
```

> **Key characteristic:** Arch Linux has no `VERSION_ID` — it is a rolling release. Always identify by `ID=arch` alone.

**Fedora:**
```text
NAME="Fedora Linux"
VERSION="44 (Workstation Edition)"
ID=fedora
VERSION_ID=44
VERSION_CODENAME=
PRETTY_NAME="Fedora Linux 44"
```

**Ubuntu:**
```text
NAME="Ubuntu"
VERSION="24.04.3 LTS (Noble Numbat)"
ID=ubuntu
VERSION_ID="24.04"
VERSION_CODENAME=noble
```

**Detection script (unified — handles all cases):**
```bash
# Step 1: Detect host OS kernel
host_os=$(uname -s)

if [[ "$host_os" == "Darwin" ]]; then
    # macOS — use sw_vers
    macos_version=$(sw_vers --productVersion)
    echo "macOS $macos_version"
elif [[ "$host_os" == "Linux" ]]; then
    # Linux — read /etc/os-release
    os_id=$(grep '^ID=' /etc/os-release | cut -d= -f2)
    
    # Special case: distinguish stock Debian from Raspberry Pi OS
    if [[ "$os_id" == "debian" ]] && [[ -f /etc/rpi-issue ]]; then
        os_id="raspios"
    fi
    
    # Fallback to ID_LIKE if ID not recognized
    if [[ ! "fedora debian ubuntu rhel arch raspios" =~ $os_id ]]; then
        os_id=$(grep '^ID_LIKE=' /etc/os-release | cut -d= -f2 | awk '{print $1}')
    fi
    
    echo "Linux: $os_id"
fi
```

##### 2d. Architecture Detection — `uname -m`

```bash
# Returns the machine hardware name
uname -m
```

| Return Value | Architecture | Notes |
|-------------|-------------|-------|
| `arm64` / `aarch64` | ARM 64-bit | Apple Silicon, Raspberry Pi |
| `x86_64` / `amd64` | x86 64-bit | Intel/AMD processors |

> **Important for containers:** When pulling arm64 images on x86_64 hosts, use `--platform linux/arm64` with podman. On Apple Silicon (native arm64), no platform flag is needed.

#### 3. Release Naming Conventions

Different OS families use different versioning strategies. This affects container image pinning and build reproducibility.

| OS Family | Version Model | `VERSION_ID` Format | Container Tag Strategy |
|-----------|--------------|---------------------|------------------------|
| **macOS** | Point releases (e.g., 26.5.2) | N/A — use `sw_vers --productVersion` | N/A (native-only) |
| **Debian-based** (Debian, Ubuntu, Raspberry Pi OS) | Point releases or LTS | `MAJOR` (Debian), `MAJOR.MINOR` (Ubuntu) | Semver: `debian:13`, `ubuntu:24.04` |
| **Fedora** | Point releases (annual) | `MAJOR` only | Semver: `fedora:44` |
| **Arch Linux** | Rolling release (continuous) | No `VERSION_ID` — use `BUILD_ID=rolling` | Datestamp: `archlinux:2026.08.01` |
| **Raspberry Pi OS** | Debian-based with datestamps | `MAJOR` (inherits from Debian) | Datestamp: `raspios:arm64-bookworm-20251204` |

**Container tag pinning rules:**
- **Semver-based distros (Debian, Ubuntu, Fedora):** Pin to the version number (e.g., `debian:13`). These tags are stable and do not change.
- **Datestamp-based distros (Arch Linux, Raspberry Pi OS):** Pin to a specific date 3 months in the past for reproducible builds. Never use `latest`.
- **Rolling releases:** Always treat as "always latest" — no version pinning is meaningful.

#### 4. Container Configuration — Dockerfile Structure

If the OS supports containerized builds, you need a Dockerfile at `<os>/containers/build/Dockerfile`. The following patterns are established.

##### 4a. Linux Distro Dockerfile (Fedora/Debian/Ubuntu pattern)

```dockerfile
ARG BASE_IMAGE=fedora:44
FROM ${BASE_IMAGE}

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive   # For Debian-based; use equivalent for RPM distros

# Install required toolchains and utilities
RUN dnf install -y --setopt=timeout=300 \
        gcc gcc-c++ make cmake doxygen clang procps-ng coreutils findutils file patchelf vim-minimal strace python3 && \
    dnf clean all

# Set working directory
WORKDIR /app
```

##### 4b. Raspberry Pi OS Dockerfile (arm64, Debian-based)

```dockerfile
# Raspberry Pi OS (Bookworm) arm64 — Datestamp-tagged for reproducible builds
# Base image: debian:13 (trixie) — Bookworm GCC 12 lacks C++20 <format> support
# Debian 13 provides GCC 14.2 with full C++20 support

ARG BASE_IMAGE=debian:13
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake doxygen clang clang-tidy clang-format procps coreutils findutils \
    which file patchelf vim strace emacs-nox python3 openjdk-21-jdk-headless maven && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
```

##### 4c. macOS — No Dockerfile

macOS is **native-only**. Do not create a Dockerfile or container directory. The `create_build.md` prompt must log:
```
[timestamp] Dockerfile handling skipped — macOS is a native-only platform.
```

##### 4d. Container Runtime Selection

| Host OS | Command | Notes |
|---------|---------|-------|
| macOS | `container` (Apple Container) | Must check service status with `container system status` before use |
| Linux | `podman` | Stateless, no daemon management needed |

**macOS pre-flight pattern:**
```bash
# 1. Check if container command exists
command -v container >/dev/null || { echo "ERROR: 'container' not found"; exit 1; }

# 2. Check service status and start if needed
container system status
if ! container system status | grep -q "active"; then
    container system start
fi
```

#### 5. Required Prompt Files

Every new OS requires a directory at `prompts/<os>/cpp/` with the following files. Each file serves a specific role in the prompt-driven workflow.

| File | Purpose | Content |
|------|---------|---------|
| `create_functional.md` | **PRIMARY** — Full functional implementation workflow | References common spec + platform-specific overrides; defines source generation steps |
| `create_build.md` | **PRIMARY** — Build environment creation workflow | References common build spec + platform-specific requirements; defines Makefile/Dockerfile generation |
| `create_regression.md` | **PRIMARY** — Test infrastructure setup workflow | References common testing spec + platform-specific test requirements |
| `functional.md` | Platform-specific functional requirements | API notes, libc differences, toolchain specifics, license info |
| `build.md` | Platform-specific build requirements | Prerequisites, container image details, toolchain specifics |
| `testing.md` | Platform-specific test requirements | Test execution notes, platform-specific considerations |
| `update_functional.md` | Incremental functional update workflow | Delta-based source regeneration |
| `update_build.md` | Incremental build update workflow | Delta-based build config regeneration |
| `update_testing.md` | Incremental test update workflow | Delta-based test infrastructure regeneration |

**Minimal `functional.md` template:**
```markdown
# Functional Requirements - Ringbuffer (<OS Name>, C++)

**Implementation Directive:**
This implementation MUST follow the common functional specification exactly to ensure cross-platform symmetry.
Refer to the common specification for all architectural, interface, and implementation details:
[prompts/common/cpp/functional.md](../../common/cpp/functional.md)

**Platform Specifics:**
- **Target OS**: <OS Name> (<version or "rolling release" if applicable)
- **OS Identification**: `ID=<id>` in `/etc/os-release` (or `sw_vers --productVersion` for macOS)
- **Architecture**: <arm64/x86_64/both> — <notes on Apple Silicon compatibility>
- **Toolchains**: <Clang/GCC/both> (default compiler)
- **License**: BSD 3-Clause License. The `LICENSE` file must be created in `src/<os>/cpp`.

**Platform-Specific API Notes:**
- <Any libc differences, POSIX feature availability, or platform-specific behaviors>

**Tooling and Recovery:** See `prompts/common/cpp/functional.md` for the authoritative tooling and recovery directives.
```

**Minimal `build.md` template:**
```markdown
# Build Requirements - Ringbuffer (<OS Name>, C++)

**Implementation Directive:**
This build specification MUST follow the common build specification exactly to ensure binary symmetry.

Refer to [prompts/common/cpp/build.md](../../common/cpp/build.md) for the Platform and Container Runtime Reference.

**Platform Specifics:**
- **Target Environment**: <OS Name> (<version or "rolling release">)
- **Prerequisites**: Install the following packages via `<package_manager>`:
    - <list of required packages>

### Required Tools
- `<compiler>` (Compiler/Linker)
- `make` (Orchestrator)
- `<binary_analysis_tool>` (Binary Analysis — e.g., `otool` on macOS, `readelf` on Linux)

### Containerized Build Environment (if applicable):
- **Base Image**: `<image>:<tag>`
- **Toolchain Installation**: Use `<package_manager> -S/--install` to install required packages
- **Container Path**: `<os>/containers/build/Dockerfile`

### macOS Skip Logic (if applicable):
<If the OS has no arm64 container image, document the macOS skip behavior here>
```

#### 6. Reference Implementations to Review

When implementing a new OS, review these existing implementations as patterns:

##### macOS (`prompts/macos/cpp/`) — Native-Only Pattern

**Key characteristics:**
- No containers, no Dockerfiles
- Universal binaries (fat binaries) with `arm64` + `x86_64` slices via `lipo -create`
- Uses Clang as default compiler
- macOS-specific binary analysis tools: `lipo`, `otool` (not `readelf`)
- Uses `@rpath` for install names; `-dead_strip` for dead code elimination
- Host detection via `sw_vers --productName`
- **Files to review:** `create_functional.md`, `create_build.md`, `functional.md` (platform-specific API notes), `build.md` (Universal Binary requirements)

##### Raspberry Pi OS (`prompts/raspios/cpp/`) — arm64 Container on Apple Silicon Pattern

**Key characteristics:**
- Shares `ID=debian` with stock Debian — distinguished by `/etc/rpi-issue`
- arm64-only architecture, runs **natively on Apple Silicon** (no skip logic needed)
- Container image uses datestamp tags: `vascoguita/raspios:arm64-bookworm-YYYYMMDD`
- Uses `apt-get` for package management (Debian-based)
- First Linux distro in the project that runs natively on Apple Silicon
- **Files to review:** `create_functional.md`, `create_build.md`, `functional.md` (two-step detection), `build.md` (macOS compatibility notes)

##### Arch Linux (`prompts/archlinux/cpp/`) — Linux-Hosts-Only Pattern

**Key characteristics:**
- Rolling release with no `VERSION_ID` — identified by `ID=arch`
- Container images are **amd64-only** with no ARM64 variant — Arch Linux does not provide an official, standard container image for ARM architectures (e.g., Apple Silicon, Raspberry Pi). The official archlinux Docker images are built exclusively for the x86_64 architecture.
- macOS skip logic required: source generation works, build/test requires Linux host
- Uses datestamp container tags: `archlinux:YYYY.MM.DD`
- Uses `pacman` for package management
- **Files to review:** `create_functional.md`, `create_build.md`, `functional.md` (rolling release notes), `build.md` (macOS skip logic, pacman prerequisites)

#### 7. Implementation Checklist

When adding a new OS, follow this checklist:

1. **Classify the OS** — Determine container support model (native-only, arm64 container, amd64 container, Linux-hosts-only)
2. **Create `prompts/<os>/cpp/` directory** with all 9 prompt files
3. **Write `functional.md`** — Document platform-specific API notes, libc differences, toolchain info
4. **Write `build.md`** — Document prerequisites, container image details (if applicable), macOS skip logic (if applicable)
5. **Write `testing.md`** — Document platform-specific test considerations
6. **Create `create_functional.md`, `create_build.md`, `create_regression.md`** — Reference common specs + platform-specific files
7. **Create update prompts** (`update_functional.md`, `update_build.md`, `update_testing.md`)
8. **If containerized:** Create Dockerfile at `<os>/containers/build/Dockerfile` with appropriate base image and package installation
9. **If containerized:** Ensure macOS compatibility (skip logic for Linux-hosts-only, native support for arm64)
10. **Build/Test Pattern** — Every new OS/language MUST include:
    - `<os>/<lang>/Makefile all` — Build target (creates artifacts + symlinks, **never** runs tests)
    - `<os>/<lang>/tests/Makefile verify` — Test target (runs T001–T007, generates reports)
    - Main Makefile must have `test: all` → calls `$(MAKE) -C tests verify`
    - See `.bionic` section "Build vs Test Workflow Pattern (All Languages)" for full details
11. **Verify** — Run `lint_prompts.sh` to validate directory structure and required files
12. **Update `.bionic`** — Add the new OS to the platform classification table and implementation phases
13. **Update README.md** — Add the new OS to the Supported Platforms table and this Developer & Maintainer Guide section

#### 7.5 SSH Remote Transfer Rule (All Platforms)
When testing on a remote system via SSH, the following files must be transferred to the remote host **before** running `verify_build.md` or `run_regression.md`:
- **C++ source files**: Copy the target-host-specific C++ directory (e.g., `src/archlinux/cpp/` for the archlinux remote). These files are per-OS — only copy the directory matching the target OS.
- **Python source files**: Copy `src/common/python/` (the common Python implementation).
- **Clean first**: Remove any existing files in the destination on the remote host before copying from the host. Use `ssh <host> "rm -rf <dest>/src/<os>/cpp/*"` and `ssh <host> "rm -rf <dest>/src/common/python/*"` before the transfer.
- **Transfer**: Use `scp -r` or `rsync -avz` to copy the cleaned directories from the host to the remote.
- **Verify**: After transfer, confirm file counts and sizes match between host and remote.

#### 7.6 Python Makefiles by Family (GNU vs BSD)
The Python implementation uses different Makefile syntax for GNU make and BSD make systems:
- **GNU make** (macOS, Linux): `src/common/python/Makefile.gnu` — uses `$(shell ...)`, `ifeq/else`
- **BSD make** (FreeBSD 14+): `src/<os>/python/Makefile` — per-OS directory with BSD-compatible syntax (no `$(shell)`, no `ifeq/else`)
- **Common source**: Both use the same Python source files from `src/common/python/` (swtr_ringbuffer_pure.py, test scripts, base types)
- **Per-platform overrides**: FreeBSD 14 has `src/freebsd14/python/` with its own Makefile and copies of common source. FreeBSD 15 will use the same structure.

#### 8. Common Pitfalls to Avoid

- **Do not copy source files between platforms.** Each platform generates independently from the common specification.
- **Makefiles require real tab characters**, not spaces. Use heredocs with explicit `\t` when generating Makefiles programmatically.
- **Always `mkdir -p` before writing to a directory** (e.g., `reports/`, `logs/`).
- **`version.mk` contains the Ringbuffer library version** (e.g., 1.0.0), NOT the OS version.
- **FreeBSD platforms must contain only zero-length files.** Do not add non-zero content to FreeBSD directories.
- **Container images must be pinned** — never use `latest` tags in Dockerfiles for reproducible builds.
- **macOS skip logic must exit 0 (success), not error.** When skipping on macOS, log the reason and continue gracefully.
- **Timestamps must include timezone offset:** `[YYYY-MM-DD HH:MM:SS +/-HHMM]` — use `date '+%Y-%m-%d %H:%M:%S %z'` on both macOS and Linux.

#### 9. Interactive OS Setup Workflow (`prompts/common/implement_new_os.md`)

The project includes an interactive workflow for adding new operating systems. This workflow provides session persistence, template loading, dry-run mode, and multi-language support.

**Key features:**
- **Session management**: Save/restore sessions with `:q`, `:wq`, `:ls`, `:rm`, `:status`, `:state` commands
- **Template loading**: Start from pre-built distribution templates (`:templates`, `:load-template fedora`)
- **Dry-run mode**: Preview scaffolding without creating files
- **Multi-language support**: Comma-separated language list (e.g., `cpp, c`)
- **Implementation state tracking**: `scaffolded → functional_implemented → build_tested → regression_passed → officially_supported`
- **Template management**: `:save-template` to create new templates, `:update-template` with diff-based change selection
- **Help**: List all available commands at any time with `:help`

**Session storage:** `.ringbuffer_sessions/` (gitignored, cleaned by `dist-clean`)
**Template storage:** `prompts/common/templates/` (git-tracked, one file per family)

**Session management commands (available at any step):**

| Command | Action |
|---------|--------|
| `:q` | Quit — ask if user wants to save current state |
| `:wq` | Quit and save — save session with description, then exit (no extra prompt) |
| `:ls` | List all sessions for the current OS name (filename, step, state, description) |
| `:rm <index>` | Delete a session by its index from the :ls listing |
| `:rm *` | Delete all sessions for the current OS name |
| `:status` | Show current session state (all fields, implementation_state) without advancing |
| `:state <new_state>` | Manually update the implementation state (e.g., `:state functional_implemented`) |
| `:templates` | List all available templates (filename, name, description, source) |
| `:load-template <name>` | Load a template by name (e.g., fedora) — available at any step |
| `:save-template [name]` | Save current session as a new template |
| `:update-template` | Update the source template with changed fields (diff-based) — only available if session was loaded from a template |
| `:help` | Show all available session management commands with descriptions |

**`:help` output:**
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

**Usage example:**
```
> "Use prompts/common/implement_new_os.md to add rocky-linux"

[Session check] No existing session for 'rocky-linux'.
Would you like to start from a template? (y/n) y

Available templates:
  [0] Fedora — RPM-based, dnf package manager, semver versioning (source: fedora)
  [1] Debian — DEB-based, apt package manager, semver versioning (source: debian)

Choose a template (0-1) or press Enter to skip: 0
Loaded template 'Fedora' — all fields populated with defaults.
...
```

**After scaffolding completes:**
1. Run `create_functional.md` for each language to generate source code
2. Run `create_build.md` for each language to create the build environment
3. Run `create_regression.md` for each language to set up test infrastructure
4. After all tests pass, regenerate README.md via `readme_template.md`
5. Update `.bionic` platform classification table
6. Update implementation state to `officially_supported`
