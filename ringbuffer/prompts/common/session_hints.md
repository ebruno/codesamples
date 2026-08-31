# Common Session Hints — Ringbuffer Project

**When to read:** When working on any workflow step that involves OS detection, container execution, or environment setup.
This file provides a quick-reference card for cross-platform operations shared across all languages and platforms.

---

## 1. Host OS Detection

### `uname -s`

Returns the operating system kernel name:

```bash
# Returns "Darwin" on macOS, "Linux" on Linux distributions
uname -s
```

| Return Value | Host OS | Container Runtime |
|-------------|---------|-------------------|
| `Darwin` | macOS | `container` (Apple Container) |
| `Linux` | Linux distro | `podman` |

### Parsing Example

```bash
# Detect host OS
host_os=$(uname -s)

if [[ "$host_os" == "Darwin" ]]; then
    echo "macOS host detected"
elif [[ "$host_os" == "Linux" ]]; then
    # Read distro ID from /etc/os-release
    host_os=$(grep '^ID=' /etc/os-release | cut -d= -f2)
    echo "Linux host: $host_os"
fi
```

---

## 2. macOS Version Detection

### `sw_vers` Command

macOS ships with the `sw_vers` command for querying system version information.

```bash
# Get product version only (e.g., "26.5.2")
sw_vers --productVersion

# Full output (ProductName, ProductVersion, BuildVersion)
sw_vers

# Help
sw_vers -h  # Usage: sw_vers [--help|--productName|--productVersion|--productVersionExtra|--buildVersion]
```

### Key Subcommands

| Flag | Output Example | Use Case |
|------|---------------|----------|
| `--productVersion` | `26.5.2` | Version number for container image tags, build versions |
| `--productName` | `macOS` | Human-readable name |
| `--buildVersion` | `25F84` | Exact build number (rarely needed) |
| `--productVersionExtra` | — | Extra version metadata (usually empty) |

### Parsing Example

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

### Notes
- `sw_vers` is only available on macOS — do not use on Linux targets
- Valid macOS versions for this project: **15 (Sequoia) and above**

---

## 3. Linux OS Identification (`/etc/os-release`)

The `/etc/os-release` file is a standard configuration file in Linux that stores operating system identification data. It uses `VARIABLE="value"` pairs to provide a uniform way for scripts and programs to query system details across distributions.

### Primary Fields for Workflow Detection

| Field | Purpose | Examples |
|-------|---------|----------|
| `ID` | Lower-case short OS identifier, safe for script use | `fedora`, `debian`, `ubuntu`, `rhel`, `arch` |
| `VERSION_ID` | Version number — may be `MAJOR.MINOR` or `MAJOR.MINOR.SUBVERSION` | `44`, `13`, `24.04`, `9.6.1` |
| `NAME` | Human-readable OS name (without version) | `Ubuntu`, `Fedora`, `Debian GNU/Linux` |
| `ID_LIKE` | Space-separated list of parent/base distributions | `debian`, `rhel fedora centos`, `arch` |

### Detection Strategy

1. **Primary:** Read `ID=` for direct OS identification
2. **Fallback:** If `ID` is not recognized, check `ID_LIKE=` for parent distribution hints
   - e.g., Ubuntu has `ID=ubuntu` but `ID_LIKE=debian` — useful for derivative detection
3. **Version:** Read `VERSION_ID=` for version number (may need parsing for MAJOR.MINOR vs MAJOR.MINOR.SUBVERSION)

### Known IDs

| ID | NAME | Typical VERSION_ID | ID_LIKE |
|----|------|-------------------|---------|
| `fedora` | Fedora Linux | `40`, `41`, `42`, ... | — |
| `debian` (stock) | Debian GNU/Linux | `11`, `12`, `13`, ... | — |
| `debian` (Raspberry Pi OS) | Debian GNU/Linux | `12` (bookworm), `11` (bullseye) | — |
| `ubuntu` | Ubuntu | `20.04`, `22.04`, `24.04` | debian |
| `rhel` | Red Hat Enterprise Linux | `8`, `9` | fedora |
| `arch` | Arch Linux | rolling (see subsection below) | arch |

> **Note:** Both stock Debian and Raspberry Pi OS share `ID=debian` in `/etc/os-release`. They are distinguished by the presence of `/etc/rpi-issue` (see `debian` and `raspios` subsections below).

### `arch` — Arch Linux (Rolling Release)

Arch Linux is a rolling-release distribution and does **not** use traditional point-release version numbers. This affects both OS identification and container image selection.

#### `/etc/os-release` specifics
- `ID=arch` (primary identifier)
- `ID_LIKE=arch` (self-referential — unlike Ubuntu which has `ID_LIKE=debian`)
- No meaningful `VERSION_ID` — always treat as rolling
- `NAME="Arch Linux"`

#### Detection strategy for Arch
1. Identify by `ID=arch` alone — do **not** rely on `VERSION_ID`
2. Use `NAME` for human-readable identification
3. For container images, use datestamp tags (see Section 4A)

#### Key differences from point-release distros
| Aspect | Point-Release (Fedora/Debian/Ubuntu) | Arch Linux |
|--------|--------------------------------------|------------|
| Version model | Fixed point releases (e.g., 40, 13, 24.04) | Rolling — continuous updates |
| `VERSION_ID` | Stable, meaningful number | Not reliable; varies by install date |
| ISO naming | Version-based (e.g., "Fedora 40") | Datestamp-based (e.g., `2026.08.01`) |
| Package freshness | Bundled at release; backported security fixes | Always latest from upstream repos |
| Container pinning | Pin to version number (e.g., `ubuntu:24.04`) | Pin to datestamp (e.g., `archlinux:2026.08.01`) |

#### macOS Limitation (Apple Silicon)
**Arch Linux container images are amd64-only.** There is no ARM64 Arch Linux container available on Docker Hub. This affects development on Apple Silicon Macs:

- **Source code generation**: Supported on all platforms (including macOS) — does not require containers
- **Build and test**: Requires a Linux host with `podman` or `docker` that can run amd64 containers
- **Container scripts**: The `archlinux_container.sh/zsh` scripts detect macOS and skip gracefully with a logged message when `--pull` is requested
- **Makefile container target**: Must include macOS skip logic that logs the limitation and exits successfully (not as an error)

When running Arch Linux workflows on macOS, the scripts MUST log:
```
[timestamp] Arch Linux container build/test SKIPPED on macOS (Apple Silicon) — no ARM64 container available.
[timestamp] Source code generation is supported; build/test requires a Linux host with podman/docker.
```

### `debian` — Stock Debian (Reference Platform)

Stock Debian is the reference Linux platform for this project. It uses standard Debian package repositories and official Docker Hub images.

#### `/etc/os-release` specifics
- `ID=debian` (primary identifier)
- `VERSION_ID="13"` for Debian 13 (Bookworm), `"12"` for Bookworm, etc.
- `VERSION_CODENAME=bookworm` (or trixie, bullseye)
- `NAME="Debian GNU/Linux"`

#### Key characteristics
- **Architecture**: amd64 (primary), arm64, and other architectures available
- **Package repos**: `deb.debian.org` only (no Raspberry Pi Foundation mirrors)
- **Container image**: Official Docker Hub — `debian:<version>` (e.g., `debian:13`)
- **Container pinning**: Pin to version number (e.g., `debian:13`)
- **No `/etc/rpi-issue`**: This file does NOT exist on stock Debian

#### Detection strategy for Stock Debian
1. Check `ID=debian` in `/etc/os-release`
2. Verify absence of `/etc/rpi-issue` — if it does NOT exist, this is stock Debian
3. Read `VERSION_ID=` for the Debian version number (12, 13, etc.)
4. For container images, use the official `debian:<version>` tag

---

### `raspios` — Raspberry Pi OS (Debian-based)

Raspberry Pi OS is built directly on top of upstream Debian arm64 packages. It shares `ID=debian` in `/etc/os-release`, so a **two-step detection** is required to distinguish it from stock Debian.

#### `/etc/os-release` specifics
- `ID=debian` (same as stock Debian — NOT sufficient alone)
- `VERSION_ID="12"` (or whatever Bookworm/Bullseye version)
- `VERSION_CODENAME=bookworm` (or bullseye, trixie)
- `NAME="Debian GNU/Linux"`

#### `/etc/rpi-issue` — The Differentiator
Raspberry Pi OS includes a file at `/etc/rpi-issue` that stock Debian does **not** have:
```
Raspberry Pi reference 2024-11-19
Generated using pi-gen, https://github.com/RPi-Distro/pi-gen, 891df1e21ed2b6099a2e6a13e26c91dea44b34d4, stage4
```

#### Detection strategy for Raspberry Pi OS
1. Check `ID=debian` in `/etc/os-release`
2. Verify presence of `/etc/rpi-issue` — if it exists, this is Raspberry Pi OS
3. Read `VERSION_CODENAME=` for the Debian codename (bookworm, bullseye, trixie)
4. For container images, use datestamp-tagged arm64 variants (see Section 4B)

#### Detection script (unified — handles both stock Debian and Raspios)
```bash
os_id=$(grep '^ID=' /etc/os-release | cut -d= -f2)

if [ "$os_id" = "debian" ]; then
    if [ -f /etc/rpi-issue ]; then
        host_os="raspios"
    else
        host_os="debian"
    fi
fi
```

#### Key differences from stock Debian
| Aspect | Stock Debian | Raspberry Pi OS |
|--------|-------------|-----------------|
| `ID` in os-release | `debian` | `debian` (same) |
| `/etc/rpi-issue` | Does not exist | Exists — confirms Pi OS |
| Architecture | amd64, arm64, etc. | **arm64 only** (for this project) |
| Package repos | `deb.debian.org` | `archive.raspberrypi.com/debian` + `deb.debian.org` |
| Container pinning | Pin to version (e.g., `debian:13`) | Pin to datestamp (e.g., `arm64-bookworm-YYYYMMDD`) |
| macOS compatibility | N/A (not in project) | **Works natively on Apple Silicon** — no skip needed |

#### macOS Compatibility (Apple Silicon)
Raspberry Pi OS containers are **arm64-only**, which is the native architecture of Apple Silicon Macs. This means:

- **No skip logic needed** — containers run natively on Apple Silicon
- No `--platform linux/arm64` flag required when building on arm64 hosts
- This is the **first Linux distro in this project that runs natively on Apple Silicon**
- On x86_64 hosts (Intel Macs, x86 Linux), use `--platform linux/arm64` with podman

#### Comparison with other distros on macOS
| Distro | Apple Silicon Support | Skip Needed? |
|--------|----------------------|-------------|
| Arch Linux | amd64-only — no ARM64 image | **Yes** |
| Raspberry Pi OS | arm64 native — runs directly | **No** |

### Parsing Example

```bash
# Extract ID
os_id=$(grep '^ID=' /etc/os-release | cut -d= -f2)

# Extract VERSION_ID
os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2)

# Fallback to ID_LIKE if ID not recognized
if [[ ! "fedora debian ubuntu rhel arch" =~ $os_id ]]; then
    os_id=$(grep '^ID_LIKE=' /etc/os-release | cut -d= -f2 | awk '{print $1}')
fi

# Distinguish stock Debian from Raspberry Pi OS (both have ID=debian)
if [ "$os_id" = "debian" ] && [ -f /etc/rpi-issue ]; then
    os_id="raspios"
fi
```

---

## 4A. Arch Linux Container Tag Conventions

Arch Linux container images use **datestamp-based tags** instead of semver version numbers. This is fundamentally different from point-release distros and must be handled specially in Dockerfiles.

#### Datestamp Tags (`YYYY.MM.DD`)
The primary pinning strategy for Arch containers:
- Format: `docker.io/archlinux:<YYYY.MM.DD>` (e.g., `archlinux:2026.08.01`)
- Mirrors the ISO/snapshot release cadence — represents the synchronized state of all Arch package mirrors on that date
- **Always pin to a specific datestamp** for reproducible builds — never use `latest`
- Example Dockerfile `FROM` line:
  ```dockerfile
  FROM docker.io/archlinux:2026.08.01
  ```

#### `latest` Tag Behavior
- Points dynamically to the most recent container image build pushed by Arch's release pipeline
- **Changes daily** — pulling `latest` on different days yields different package sets and kernel/userspace versions
- **Not suitable for reproducible builds** — avoid in Dockerfiles for this project
- Useful only for interactive development or testing against the absolute latest packages

#### Base vs. Specialized Containers
- `archlinux:<datestamp>` — Full base image with common tools
- `archlinux:base:<datestamp>` — Minimal base (no extra packages)
- `archlinux:devel:<datestamp>` — Development-focused with compilers and build tools pre-installed
- For this project, use the full base image and install only required packages via `pacman`

#### Pinning Recommendation for This Project
| Scenario | Recommended Tag | Reason |
|----------|----------------|--------|
| Reproducible builds (Dockerfile) | `archlinux:YYYY.MM.DD` (specific date) | Deterministic package state |
| CI/CD pipeline | `archlinux:YYYY.MM.DD` (pinned to a known-good date) | Reproducible test results |
| Interactive development | `archlinux:latest` | Always up-to-date |

#### Comparison with Point-Release Distro Container Tags
| Distro | Tag Format | Example | Pinning Strategy |
|--------|-----------|---------|------------------|
| Ubuntu | `ubuntu:<MAJOR.MINOR>` | `ubuntu:24.04` | Stable semver |
| Fedora | `fedora:<MAJOR>` | `fedora:40` | Stable semver |
| Debian | `debian:<STABLE>` | `debian:13` | Stable semver |
| Arch Linux | `archlinux:<YYYY.MM.DD>` | `archlinux:2026.08.01` | Datestamp |

---

## 4B. Raspberry Pi OS Container Tag Conventions

Raspberry Pi OS uses **datestamp-based tags** for reproducible builds, similar to Arch Linux but with a different tag format.

#### Tag Format (`arm64-<codename>-YYYYMMDD`)
The primary pinning strategy for Raspios containers:
- Format: `vascoguita/raspios:arm64-<codename>-YYYYMMDD` (e.g., `vascoguita/raspios:arm64-bookworm-20251204`)
- The `arm64-` prefix ensures the correct architecture is pulled
- The codename (`bookworm`, `bullseye`, `trixie`) matches the Debian release
- The datestamp (`YYYYMMDD`) represents a specific Pi OS build date
- **Always pin to a specific datestamp** for reproducible builds — never use `latest`
- Example Dockerfile `FROM` line:
  ```dockerfile
  FROM docker.io/vascoguita/raspios:arm64-bookworm-20251204
  ```

#### Fallback Tag (Codename-only)
If the datestamp tag is not available, fall back to the codename-based arm64 tag:
- Format: `vascoguita/raspios:arm64-<codename>` (e.g., `vascoguita/raspios:arm64-bookworm`)
- This tag is maintained but less precise than datestamp tags
- Example Dockerfile `FROM` line:
  ```dockerfile
  FROM docker.io/vascoguita/raspios:arm64-bookworm
  ```

#### `latest` Tag Behavior
- Points dynamically to the most recent container image build
- **Changes periodically** — pulling `latest` on different days may yield different package sets
- **Not suitable for reproducible builds** — avoid in Dockerfiles for this project
- Useful only for interactive development or testing against the absolute latest packages

#### Pinning Recommendation for This Project
| Scenario | Recommended Tag | Reason |
|----------|----------------|--------|
| Reproducible builds (Dockerfile) | `arm64-<codename>-YYYYMMDD` (specific date, 3 months prior) | Deterministic package state |
| CI/CD pipeline | `arm64-<codename>-YYYYMMDD` (pinned to a known-good date) | Reproducible test results |
| Interactive development | `arm64-<codename>` (codename-only) | Always up-to-date for the codeline |

#### Image Tag Resolution (Makefile / Build Script)
The `container` target MUST resolve the correct tag at runtime:

```bash
# Read codename from /etc/os-release
VERSION_CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2)

# Calculate 3 months ago (same as Arch Linux pattern)
THREE_MONTHS_AGO=$(date -d "3 months ago" +%Y%m%d 2>/dev/null || \
                   date -v-3m +%Y%m%d)

# Try datestamp first (reproducible), fall back to codename
CONTAINER_IMAGE="vascoguita/raspios:arm64-${VERSION_CODENAME}-${THREE_MONTHS_AGO}"
if ! podman pull --quiet "$CONTAINER_IMAGE" 2>/dev/null; then
    CONTAINER_IMAGE="vascoguita/raspios:arm64-${VERSION_CODENAME}"
fi
```

#### Comparison with Point-Release Distro Container Tags
| Distro | Tag Format | Example | Pinning Strategy |
|--------|-----------|---------|------------------|
| Ubuntu | `ubuntu:<MAJOR.MINOR>` | `ubuntu:24.04` | Stable semver |
| Fedora | `fedora:<MAJOR>` | `fedora:40` | Stable semver |
| Debian | `debian:<STABLE>` | `debian:13` | Stable semver |
| Arch Linux | `archlinux:<YYYY.MM.DD>` | `archlinux:2026.08.01` | Datestamp |
| Raspberry Pi OS | `raspios:arm64-<codename>-YYYYMMDD` | `raspios:arm64-bookworm-20251204` | Datestamp |

---

## 4. Container Runtime Quick-Reference

### macOS Host (Apple Container)

macOS uses the `container` command (Apple Container), NOT Docker or podman.

| Subcommand | Purpose | Example |
|-----------|---------|---------|
| `container run` | Run a container | `container run --rm -v $(pwd):/app <image> sh -c "..."` |
| `container build` / `container image build` | Build an image from Dockerfile | `container build -t <name> -f Dockerfile .` |
| `container images` / `container image list` | List images | `container image list \| grep <name>` |
| `container system status` | Show container services status | Check if daemon is running |
| `container system version` | Show container runtime version | `container system version` |

### Linux Host (Podman)

Linux uses `podman` — NOT Docker. Podman is stateless, no daemon management needed.

| Subcommand | Purpose | Example |
|-----------|---------|---------|
| `podman run` | Run a container | `podman run --rm -v $(pwd):/app <image> sh -c "..."` |
| `podman build` / `podman image build` | Build an image from Dockerfile | `podman build -t <name> -f Dockerfile .` |
| `podman images` / `podman image list` | List images | `podman image list \| grep <name>` |

---

## 5. Apple Container Service Management

The `container` daemon does NOT start automatically on macOS. Always check and start the service before any container operations.

### Service Commands

```bash
# Check status (returns active/inactive)
container system status

# Start the daemon
container system start

# Show runtime version
container system version
```

### Pre-flight Pattern (for workflow prompts)

```bash
# 1. Check if container command exists
command -v container >/dev/null || { echo "ERROR: 'container' not found"; exit 1; }

# 2. Check service status
container system status

# 3. Start if not running
if ! container system status | grep -q "active"; then
    container system start
    # Wait for readiness, verify again
fi

# 4. If service fails to start
if ! container system status | grep -q "active"; then
    echo "ERROR: Apple Container daemon failed to start."
    echo "Try running manually: container system start"
    exit 1
fi
```

---

## 6. Memory Calculation for Container Limits (macOS)

When running containers from macOS, calculate memory limits based on available system memory.

### `vm_stat` Parsing

```bash
# Get vm_stat output (page-based memory accounting)
vm_output=$(vm_stat)

# Extract page size from first line (e.g., "Pages free:            1234")
page_size=$(echo "$vm_output" | head -1 | grep -oP '\d+' | head -1)

# Extract Pages free and Pages inactive
pages_free=$(echo "$vm_output" | grep "Pages free:" | awk '{print $3}')
pages_inactive=$(echo "$vm_output" | grep "Pages inactive:" | awk '{print $3}')

# Calculate total available bytes
total_bytes=$(( (pages_free + pages_inactive) * page_size ))

# Convert to GiB
total_gib=$(( total_bytes / 1073741824 ))

# Set container memory limit: 50% of available, capped at 3 GB
memory_limit=$(( total_gib / 2 ))
if (( memory_limit > 3 )); then
    memory_limit=3
fi

# Use in container run: -m ${memory_limit}g
```

---

## 7. Timestamp Format

All timestamps in logs and reports MUST include timezone offset:

```
[YYYY-MM-DD HH:MM:SS +/-HHMM]
```

### Command

```bash
# Works on both macOS (BSD date) and Linux (GNU date)
date '+%Y-%m-%d %H:%M:%S %z'
```

### Example Output

```
[2026-08-12 19:13:45 -0700] Build verification started
```

---

## 7A. Script Language Selection — When to Use tcsh vs Python

The project generates utility scripts in four shell variants (Bash, Zsh, Tcsh, Bourne) for **test data generation** and similar utilities that must run on all platforms including FreeBSD. However, not every utility needs a tcsh variant.

### Rule of Thumb

| Script Purpose | Needs tcsh? | Reason |
|----------------|-------------|--------|
| **Test data generation** (`generate_test_data.*`) | ✅ Yes | Runs on FreeBSD (no containers), needs all 4 shell variants |
| **Test data validation** (`verify_test_data.*`) | ✅ Yes | Runs on FreeBSD, needs all 4 shell variants |
| **JUnit report generation** (`generate_junit_report.*`) | ✅ Yes | Runs on FreeBSD, needs all 4 shell variants |
| **Binary symmetry verification** (`verify_binary_symmetry.*`) | ✅ Yes | Runs on FreeBSD, needs all 4 shell variants |
| **Prompt linting** (`lint_prompts.*`) | ✅ Yes | Runs on FreeBSD, needs all 4 shell variants |
| **Container management** (`archlinux_container.*`) | ❌ No | FreeBSD has no container support — only bash, zsh, python needed |
| **GIF to MP4 conversion** (`gif_to_mp4.sh`) | ❌ No | macOS/Linux only, no FreeBSD usage |

### Why This Matters

- **FreeBSD** is an excluded platform (zero-length spec files, no active development) but the test infrastructure scripts must still be runnable on it for completeness.
- **Arch Linux** uses containers (Docker/Podman) — container management scripts only need bash, zsh, and python. No tcsh variant is needed because FreeBSD (the only platform that would use tcsh) has no container support.
- **Python** is always allowed as a helper module (importable, not just CLI) regardless of platform. It's used for JSON parsing in Docker Hub API calls where shell-native JSON support doesn't exist.

### Script File Naming Convention

| Variant | Extension | Shebang |
|---------|-----------|--------|
| Bash | `.sh` | `#!/usr/bin/env bash` |
| Zsh | `.zsh` | `#!/usr/bin/env zsh` |
| Tcsh | `.tcsh` | `#!/usr/bin/env tcsh` |
| Bourne | `_bin_sh.sh` | `#!/usr/bin/env sh` |

When a script does **not** need tcsh, omit the `.tcsh` file. The python version is always included as a module helper.

---

## 7C. SSH Automation for FreeBSD — Practical Lessons

When working with FreeBSD systems over SSH (e.g., `ssh ebruno@10.10.41.244`), the following lessons apply:

### Shell Compatibility
- **FreeBSD uses tcsh as default shell** — bash syntax (like `for` loops, `[[ ]]`) fails
- **Solution:** Write Python scripts locally, SCP them to the remote system, and execute via `python3 /tmp/script.py`
- **Never use inline bash** with SSH to FreeBSD — tcsh interprets the commands and fails on bash-specific syntax

### Output Redirection
- **`2>&1` with pipes causes "Ambiguous output redirect" errors** in tcsh
- **Solution:** Use separate commands or write to files first, then process locally
- Example: Instead of `ssh host "cmd 2>&1 | grep error"`, use:
  ```bash
  ssh host "cmd > /tmp/output.txt 2> /tmp/error.txt"
  # Then process locally
  ```

### Binary Output Handling
- **XOR transform (T007) produces binary output** that cannot be decoded as UTF-8
- **Solution:** When using Python subprocess via SSH, use `errors='replace'` in decode calls:
  ```python
  r = subprocess.run(cmd, shell=True, capture_output=True, timeout=120)
  out = r.stdout.decode('utf-8', errors='replace').strip()
  err = r.stderr.decode('utf-8', errors='replace').strip()
  ```

### Privilege Escalation
- **FreeBSD uses `doas` instead of `sudo`** for privilege escalation
- Example: `doas mount -t procfs proc /proc`
- Scripts that need root must use `doas`, not `sudo`

### Procfs for OpenJDK
- **OpenJDK 25 requires `/proc` mounted** on FreeBSD
- Mount with: `doas mount -t procfs proc /proc`
- Add to `/etc/fstab` for persistence: `proc /proc procfs rw 0 0`

### Recommended Workflow Pattern
```python
# 1. Write script locally
# 2. SCP to remote
scp script.py user@freebsd:/tmp/script.py
# 3. Execute via SSH
ssh user@freebsd "python3 /tmp/script.py"
# 4. Copy results back
scp user@freebsd:/path/to/results ./local/path/
```

---

## 7B. Interactive OS Setup — Session Management and Templates

When using `prompts/common/implement_new_os.md` to add a new operating system, the workflow uses an interactive session with persistence, templates, and dry-run mode.

### Session Storage
- **Location:** `.ringbuffer_sessions/` (workspace root, gitignored)
- **Filename format:** `new_os_setup_<os_name>_<YYYYMMDD_HHMMSS>.json`
- **Auto-resume:** On startup, the workflow scans for matching files and offers the newest first
- **Cleanup:** Removed by `dist-clean` target in top-level Makefile

### Session JSON Fields (Key Fields)
| Field | Type | Description |
|-------|------|-------------|
| `os_name` | string | OS directory name (e.g., "fedora", "debian") |
| `languages` | array | Languages to support (e.g., ["cpp", "c"]) |
| `classification` | string | OS classification (native_only, containerized_amd64, etc.) |
| `source_template` | string | Template name if loaded from one (e.g., "fedora") |
| `implementation_state` | string | Lifecycle state: scaffolded → functional_implemented → build_tested → regression_passed → officially_supported |
| `dry_run` | bool | Whether dry-run mode is enabled |
| `session_description` | string | User-provided description for the session |

### Template Storage
- **Location:** `prompts/common/templates/` (git-tracked)
- **Filename format:** `template_<family>.json` (no timestamp, updated in place)
- **Example files:** `template_fedora.json`, `template_debian.json`

### Template JSON Structure
```json
{
  "is_template": true,
  "template_name": "Fedora",
  "template_description": "RPM-based, dnf package manager, semver versioning",
  "source_distro": "fedora",
  "classification": "containerized_amd64",
  "os_family": "redhat",
  "package_manager": "dnf",
  "base_image": "fedora:44",
  "compiler": "g++",
  "default_languages": ["cpp"],
  "prerequisite_packages": ["gcc", "make", ...]
}
```

### Session Management Commands (available at any step)
| Command | Action |
|---------|--------|
| `:q` | Quit — ask if user wants to save current state |
| `:wq` | Quit and save — save session with description, then exit |
| `:ls` | List all sessions for the current OS name |
| `:rm <index>` | Delete a session by its index from the :ls listing |
| `:rm *` | Delete all sessions for the current OS name |
| `:status` | Show current session state without advancing |
| `:state <new_state>` | Manually update the implementation state |
| `:templates` | List all available templates |
| `:load-template <name>` | Load a template by name (e.g., fedora) |
| `:save-template [name]` | Save current session as a new template |
| `:update-template` | Update the source template with changed fields (diff-based) |
| `:help` | Show all available session management commands |

### Workflow Steps (with Session Integration)
1. **Step 0** — Startup: session recovery check → template loading (if no session) → dry-run question
2. **Step 0b** — OS name and language selection (comma-separated list)
3. **Steps 1–8** — Collect OS details, with template defaults shown as context
4. **Step 9** — Final summary with implementation state and next steps

### After Scaffolding Completes
The OS scaffolding is fully functional without documentation updates. Once the OS passes all tests:
1. Update implementation state: `:state regression_passed`
2. Regenerate README.md: "Use prompts/common/templates/readme_template.md to regenerate the top-level README.md"
3. Update .bionic platform classification table (manually or via agent)
4. Update implementation state: `:state officially_supported`

---

## 8. Cross-Reference Summary

> **Host OS detection, macOS versioning, Linux /etc/os-release (incl. Arch rolling release)** → This file (`prompts/common/session_hints.md`)
> **Arch Linux container tag conventions (datestamp-based)** → Section 4A of this file
> **C++ toolchain, binary formats, linking flags** → `prompts/common/cpp/session_hints.md`
> **Source organization, naming conventions, include discipline** → `prompts/common/cpp/functional.md`
> **Build flags, Makefile targets, artifact naming** → `prompts/common/cpp/build.md`
> **Test matrix T001-T007, scripting mandate** → `prompts/common/cpp/testing.md`
