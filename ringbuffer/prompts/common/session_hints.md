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
| `debian` | Debian GNU/Linux | `11`, `12`, `13`, ... | — |
| `ubuntu` | Ubuntu | `20.04`, `22.04`, `24.04` | debian |
| `rhel` | Red Hat Enterprise Linux | `8`, `9` | fedora |
| `arch` | Arch Linux | rolling (use `NAME`) | — |

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
```

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

## 8. Cross-Reference Summary

> **Host OS detection, macOS versioning, Linux /etc/os-release** → This file (`prompts/common/session_hints.md`)
> **C++ toolchain, binary formats, linking flags** → `prompts/common/cpp/session_hints.md`
> **Source organization, naming conventions, include discipline** → `prompts/common/cpp/functional.md`
> **Build flags, Makefile targets, artifact naming** → `prompts/common/cpp/build.md`
> **Test matrix T001-T007, scripting mandate** → `prompts/common/cpp/testing.md`
