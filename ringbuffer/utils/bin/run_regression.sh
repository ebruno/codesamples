#!/usr/bin/env bash
# run_regression.sh — Execute regression tests for a target OS inside its container
# Usage: ./utils/bin/run_regression.sh [-N] [-L <lang>] <os> verify|build [image_override]
# Linux host version (bash) — uses podman

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT_NAME="run_regression.sh"
REGISTRY="${WORKSPACE}/config/toolchains.json"

usage() {
    echo "Usage: $0 [-N] [-L <lang>] <os> verify|build [image_override]"
    echo ""
    echo "Options:"
    echo "  -N         Bypass host OS check (unsafe — script requires Linux)"
    echo "  -L <lang>  Language: cpp (default), python, java, go, rust"
    echo ""
    echo "Actions:"
    echo "  verify   — Run full regression test matrix (T001-T007)"
    echo "  build    — Build library only"
    echo ""
    echo "Supported OS: macos, debian, fedora, ubuntu, raspios, archlinux, freebsd14"
    exit 1
}

# ── Parse arguments (handle -N and -L flags) ───────────────────────
BYPASS_OS_CHECK=false
TARGET_LANG="cpp"  # Default language

while getopts ":NL:" opt; do
    case $opt in
        N) BYPASS_OS_CHECK=true ;;
        L) TARGET_LANG="$OPTARG" ;;
        :) echo "ERROR: -$OPTARG requires an argument"; exit 1 ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -lt 2 ]; then
    usage
fi

TARGET_OS="$1"
ACTION="$2"
IMAGE_OVERRIDE="${3:-}"

# ── Host OS check (Linux required) ────────────────────────────────
if [ "$BYPASS_OS_CHECK" = false ]; then
    local_host_os=$(uname -s)
    if [ "$local_host_os" != "Linux" ]; then
        echo "ERROR: Running unsupported operating system ${local_host_os}; run_regression.sh requires Linux."
        exit 1
    fi
fi

# ── Validate OS/action ────────────────────────────────────────────
case "$TARGET_OS" in
    macos|debian|fedora|ubuntu|raspios|archlinux|freebsd14) ;;
    *) echo "ERROR: Unsupported OS '$TARGET_OS'"; exit 1 ;;
esac

case "$ACTION" in
    verify|build) ;;
    *) echo "ERROR: Unsupported action '$ACTION'. Use 'verify' or 'build'"; exit 1 ;;
esac

# ── Detect host OS and pick container CLI ──────────────────────────
if [ "$BYPASS_OS_CHECK" = true ]; then
    # When bypassing, detect actual host for container CLI selection
    if [ "$(uname -s)" = "Darwin" ]; then
        HOST_OS="macos"
        CONTAINER_CMD="container"
    else
        HOST_OS=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 || echo "linux")
        CONTAINER_CMD="podman"
    fi
else
    HOST_OS=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 || echo "linux")
    CONTAINER_CMD="podman"
fi

if [ "$ACTION" = "verify" ]; then
    CONTAINER_IMAGE="ringbuffer_${TARGET_OS}_test"
else
    CONTAINER_IMAGE="ringbuffer_${TARGET_OS}_build"
fi

# ── SSH hosts config path ──────────────────────────────────────────
SSH_CONFIG="${WORKSPACE}/config/ssh_hosts.json"

# ── Validate SSH host only for the target OS being processed ───────
get_ssh_host() {
    local os="$1"

    if [ ! -f "$SSH_CONFIG" ]; then
        echo "ERROR: SSH hosts config not found at $SSH_CONFIG" >&2
        return 1
    fi

    case "$os" in
        freebsd14)
            local host
            host=$(jq -r '.freebsd_host // empty' "$SSH_CONFIG" 2>/dev/null)
            if [ -z "$host" ]; then
                echo "ERROR: SSH host for freebsd14 not configured in $SSH_CONFIG" >&2
                echo "  Add \"freebsd_host\": \"user@host\" to $SSH_CONFIG" >&2
                return 1
            fi
            echo "$host"
            ;;
        archlinux)
            local host
            host=$(jq -r '.archlinux_host // empty' "$SSH_CONFIG" 2>/dev/null)
            if [ -z "$host" ]; then
                echo "ERROR: SSH host for archlinux not configured in $SSH_CONFIG" >&2
                echo "  Add \"archlinux_host\": \"user@host\" to $SSH_CONFIG" >&2
                return 1
            fi
            echo "$host"
            ;;
        *)
            # No SSH host needed for this OS (uses containers or native)
            return 0
            ;;
    esac
}

# ── Language path resolution ───────────────────────────────────────
# Returns the base directory for a given OS + language.
# Handles: per-OS (cpp, c) and common (python, java, go, rust).
# OS overrides: if src/<os>/<lang>/ exists and is a real directory (not symlinked), use it.
# Otherwise fall back to src/common/<lang>/ for common languages.
resolve_lang_path() {
    local os="$1" lang="$2"

    # Per-OS languages always use src/<os>/<lang>/
    case "$lang" in
        cpp|c) echo "${WORKSPACE}/src/${os}/${lang}" ;;
    esac

    # Common languages: check for OS override first, then fall back to common
    case "$lang" in
        python|java|go|rust)
            if [ -d "${WORKSPACE}/src/${os}/${lang}" ] && \
               [ ! -L "${WORKSPACE}/src/${os}/${lang}" ]; then
                # OS override exists (real directory, not symlink)
                echo "${WORKSPACE}/src/${os}/${lang}"
            else
                # No override — use common
                echo "${WORKSPACE}/src/common/${lang}"
            fi
            ;;
    esac
}

# ── Registry helper: list ALL compilers for <os> + <lang> (to stderr) ──
list_all_compilers() {
    local os="$1" lang="${2:-cpp}"

    if command -v jq &>/dev/null; then
        jq -r ".[\"${lang}\"][\"${os}\"][] | \"  \\(.name) (min_version: \\(.min_version)) - \\(if .supported then \"SUPPORTED\" else \"UNSUPPORTED: \\(.description)\" end)\"" "$REGISTRY" 2>/dev/null >&2
    elif command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('${REGISTRY}') as f:
    data = json.load(f)
for c in data.get('${lang}', {}).get('${os}', []):
    status = 'SUPPORTED' if c.get('supported') else f\"UNSUPPORTED: {c.get('description', 'unknown')}\"
    print(f'  {c[\"name\"]} (min_version: {c.get(\"min_version\", \"?\")}) - {status}')
" 2>/dev/null >&2
    else
        echo "ERROR: Neither jq nor python3 available to read registry" >&2
    fi
}

# ── Registry helper: read supported compilers for <os> + <lang> from JSON ───
get_compilers() {
    local os="$1" lang="${2:-cpp}"

    # C/C++ use CXX variable
    if [ "$lang" = "cpp" ] || [ "$lang" = "c" ]; then
        if command -v jq &>/dev/null; then
            jq -r ".[\"${lang}\"][\"${os}\"][] | select(.supported == true) | .name" "$REGISTRY" 2>/dev/null
        elif command -v python3 &>/dev/null; then
            python3 -c "
import json, sys
with open('${REGISTRY}') as f:
    data = json.load(f)
for c in data.get('${lang}', {}).get('${os}', []):
    if c.get('supported'):
        print(c['name'])
" 2>/dev/null
        else
            echo "ERROR: Neither jq nor python3 available to read registry" >&2
            return 1
        fi
    else
        # Non-CXX languages (python, java, go, rust) — return the interpreter/compiler
        local compilers=""
        if command -v jq &>/dev/null; then
            compilers=$(jq -r ".[\"${lang}\"][\"${os}\"][] | select(.supported == true) | .name" "$REGISTRY" 2>/dev/null)
        elif command -v python3 &>/dev/null; then
            compilers=$(python3 -c "
import json, sys
with open('${REGISTRY}') as f:
    data = json.load(f)
for c in data.get('${lang}', {}).get('${os}', []):
    if c.get('supported'):
        print(c['name'])
" 2>/dev/null)
        fi

        if [ -n "$compilers" ]; then
            echo "$compilers"
        else
            # No registry entry — use the standard interpreter name
            case "$lang" in
                python) echo "python3" ;;
                java)   echo "javac" ;;
                go)     echo "go" ;;
                rust)   echo "rustc" ;;
            esac
        fi
    fi
}

# ── Native execution (host matches target) ────────────────────────
run_native() {
    echo "=== Native execution: $ACTION on $TARGET_OS ($TARGET_LANG) ==="

    local os_dir tests_dir
    os_dir=$(resolve_lang_path "$TARGET_OS" "$TARGET_LANG")
    tests_dir="${os_dir}/tests"

    if [ ! -d "$tests_dir" ]; then
        echo "ERROR: $tests_dir does not exist."
        exit 1
    fi

    local -a compilers=()
    while IFS= read -r c; do
        [ -n "$c" ] && compilers+=("$c")
    done < <(get_compilers "$TARGET_OS" "$TARGET_LANG")

    if [ ${#compilers[@]} -eq 0 ]; then
        echo "ERROR: No supported compilers found for ${TARGET_OS}/${TARGET_LANG}"
        exit 1
    fi

    echo "Compilers from registry: ${compilers[*]}"

    # List all compilers (supported and unsupported) to stderr
    echo "Available compilers for ${TARGET_OS}/${TARGET_LANG}:"
    list_all_compilers "$TARGET_OS" "$TARGET_LANG"

    for COMPILER in "${compilers[@]}"; do

        make -C "$os_dir" clean 2>&1
        make -C "$tests_dir" clean 2>&1

        # Set the right variable based on language
        case "$TARGET_LANG" in
            cpp|c)  CXX="$COMPILER" make -C "$tests_dir" verify 2>&1 ;;
            python)
                # Pass DISTRO_ID so Makefile.linux can resolve the correct C++ source dir
                DISTRO_ID="$TARGET_OS" PYTHON="$COMPILER" make -C "$tests_dir" verify 2>&1
                ;;
            java)   JAVA="$COMPILER" make -C "$tests_dir" verify 2>&1 ;;
            *)      make -C "$tests_dir" verify 2>&1 ;;
        esac
    done
}

# ── Container execution (cross-OS from Linux host) ────────────────
run_container() {
    echo "=== Container execution: $ACTION on $TARGET_OS ($TARGET_LANG) ==="

    if ! command -v "$CONTAINER_CMD" &>/dev/null; then
        echo "ERROR: '$CONTAINER_CMD' not found in PATH."
        exit 1
    fi

    local os_dir
    os_dir=$(resolve_lang_path "$TARGET_OS" "$TARGET_LANG")

    # Always clean up any stale container from previous runs before starting fresh
    echo "Cleaning up any stale container..."
    make -C "$os_dir" stop_container 2>&1 || true
    make -C "$os_dir" remove_container 2>&1 || true

    echo "Ensuring container image exists (via Makefile)..."
    make -C "$os_dir" container 2>&1 || { echo "ERROR: Failed to ensure image"; exit 1; }

    echo "Starting persistent container..."
    make -C "$os_dir" start_container 2>&1 || { echo "ERROR: Failed to start container"; exit 1; }

    local -a compilers=()
    while IFS= read -r c; do
        [ -n "$c" ] && compilers+=("$c")
    done < <(get_compilers "$TARGET_OS" "$TARGET_LANG")

    if [ ${#compilers[@]} -eq 0 ]; then
        echo "ERROR: No supported compilers found for ${TARGET_OS}/${TARGET_LANG}"
        make -C "$os_dir" stop_container 2>&1 || true
        exit 1
    fi

    echo "Compilers from registry: ${compilers[*]}"

    # List all compilers (supported and unsupported) to stderr
    echo "Available compilers for ${TARGET_OS}/${TARGET_LANG}:"
    list_all_compilers "$TARGET_OS" "$TARGET_LANG"

    # Derive running container name from image name (image: ringbuffer_<os>_test → container: ringbuffer_<os>_test_running)
    local RUNNING_CONTAINER="${CONTAINER_IMAGE}_running"

    for COMPILER in "${compilers[@]}"; do
        echo ""
        echo "============================================="
        echo "Compiler/Interpreter: $COMPILER"
        echo "============================================="

        # Set the right variable based on language — use make -C with absolute paths
        case "$TARGET_LANG" in
            cpp|c)  $CONTAINER_CMD exec -e CONTAINER_CMD="$CONTAINER_CMD" "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/cpp/tests clean 2>&1
                    $CONTAINER_CMD exec -e CXX="$COMPILER" -e CONTAINER_CMD="$CONTAINER_CMD" "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/cpp/tests verify 2>&1 ;;
            python) $CONTAINER_CMD exec "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/cpp clean 2>&1
                    $CONTAINER_CMD exec "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/common/python/tests clean 2>&1
                    $CONTAINER_CMD exec -e PYTHON="$COMPILER" -e DISTRO_ID="$TARGET_OS" "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/common/python/tests verify 2>&1 ;;
            java)   $CONTAINER_CMD exec "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/common/java/tests clean 2>&1
                    $CONTAINER_CMD exec -e JAVA="$COMPILER" "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/common/java/tests verify 2>&1 ;;
            *)      $CONTAINER_CMD exec "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/${TARGET_LANG}/tests clean 2>&1
                    $CONTAINER_CMD exec "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/${TARGET_LANG}/tests verify 2>&1 ;;
        esac
    done

    echo "Stopping container..."
    make -C "$os_dir" stop_container 2>&1 || true
    echo "Removing container..."
    make -C "$os_dir" remove_container 2>&1 || true

    echo "Container stopped and removed. Image $CONTAINER_IMAGE remains."
}

# ── SSH execution for remote hosts (freebsd14, archlinux, etc.) ───
run_ssh() {
    echo "=== SSH execution: $ACTION on $TARGET_OS ($TARGET_LANG) ==="

    local ssh_host
    ssh_host=$(get_ssh_host "$TARGET_OS") || exit 1

    local tarball="/tmp/ringbuffer_${TARGET_OS}.tar.gz"
    local os_dir tests_dir
    os_dir=$(resolve_lang_path "$TARGET_OS" "$TARGET_LANG")
    tests_dir="${os_dir}/tests"

    # Step 1: Create tarball from workspace root
    echo "Creating tarball..."
    tar -czf "$tarball" -C "$WORKSPACE/.." ringbuffer/

    # Step 2: SCP to remote home directory
    echo "Syncing to remote..."
    scp "$tarball" "${ssh_host}:~/ringbuffer.tar.gz"

    # Step 3: SSH delete on remote (clean slate — emulates clean git checkout)
    echo "Cleaning remote workspace..."
    ssh "$ssh_host" 'rm -rf ~/ringbuffer'

    # Step 4: SSH unpack on remote at ~/ringbuffer
    echo "Unpacking on remote..."
    ssh "$ssh_host" 'cd ~ && tar -xzf ringbuffer.tar.gz && rm -f ringbuffer.tar.gz'

    # Step 5: Run regression on remote — select runner based on target OS default shell
    echo "Running regression on remote..."
    case "$TARGET_OS" in
        freebsd14)
            # FreeBSD uses tcsh as default shell — use run_freebsd_native_or_ssh.tcsh with language-specific mode
            # Map action to mode: verify → <lang>-test, build → <lang>-build
            case "$TARGET_LANG" in
                cpp|c)
                    if [ "$ACTION" = "verify" ]; then
                        ssh "$ssh_host" 'tcsh ~/ringbuffer/utils/bin/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 test-cpp'
                    else
                        ssh "$ssh_host" 'tcsh ~/ringbuffer/utils/bin/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 cpp'
                    fi
                    ;;
                python)
                    if [ "$ACTION" = "verify" ]; then
                        ssh "$ssh_host" 'tcsh ~/ringbuffer/utils/bin/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 python-test'
                    else
                        ssh "$ssh_host" 'tcsh ~/ringbuffer/utils/bin/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 python-build'
                    fi
                    ;;
                java)
                    if [ "$ACTION" = "verify" ]; then
                        ssh "$ssh_host" 'tcsh ~/ringbuffer/utils/bin/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 java-test'
                    else
                        ssh "$ssh_host" 'tcsh ~/ringbuffer/utils/bin/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 java-build'
                    fi
                    ;;
                *)
                    echo "ERROR: Unsupported language '$TARGET_LANG' for FreeBSD 14 SSH"
                    rm -f "$tarball"
                    exit 1
                    ;;
            esac
            ;;
        *)
            # Linux distros (archlinux, etc.) use bash as default shell — use run_linux_ssh.sh
            # SCP the script to remote and verify it exists before running
            echo "Deploying run_linux_ssh.sh to remote..."
            scp "$WORKSPACE/utils/bin/run_linux_ssh.sh" "${ssh_host}:/tmp/run_linux_ssh.sh"
            if [ $? -ne 0 ]; then
                echo "ERROR: Failed to scp run_linux_ssh.sh to ${ssh_host}"
                rm -f "$tarball"
                exit 1
            fi
            ssh "$ssh_host" 'bash /tmp/run_linux_ssh.sh '"${TARGET_OS}"' '"${ACTION}"
            local rc=$?
            ssh "$ssh_host" 'rm -f /tmp/run_linux_ssh.sh'
            return $rc
            ;;
    esac
    local rc=$?

    # Step 6: SCP results back from remote
    echo "Copying results back..."
    ssh "$ssh_host" 'mkdir -p ~/ringbuffer/src/'"${TARGET_OS}"'/'"${TARGET_LANG}"'/reports ~/ringbuffer/src/'"${TARGET_OS}"'/'"${TARGET_LANG}"'/logs'
    scp -r "${ssh_host}:~/ringbuffer/src/${TARGET_OS}/${TARGET_LANG}/reports/" "$WORKSPACE/src/${TARGET_OS}/${TARGET_LANG}/reports/"
    scp -r "${ssh_host}:~/ringbuffer/src/${TARGET_OS}/${TARGET_LANG}/logs/" "$WORKSPACE/src/${TARGET_OS}/${TARGET_LANG}/logs/"

    rm -f "$tarball"
    return $rc
}

# ── Main dispatch ─────────────────────────────────────────────────
echo "============================================="
echo "Ringbuffer Regression Runner (Linux/bash)"
if [ "$BYPASS_OS_CHECK" = true ]; then
    echo "  OS Check:   BYPASSED (-N flag)"
fi
echo "  Host OS:    $HOST_OS"
echo "  Target OS:  $TARGET_OS"
echo "  Language:   ${TARGET_LANG}"
echo "  Action:     $ACTION"
echo "============================================="

# ── Routing via host_targets.json (single source of truth) ─────────
HOST_TARGETS="${WORKSPACE}/config/host_targets.json"

if [ ! -f "$HOST_TARGETS" ]; then
    echo "ERROR: Routing config not found at $HOST_TARGETS"
    exit 1
fi

# Look up transport for this host→target pair
TRANSPORT=$(jq -r ".[\"${HOST_OS}\"].targets[] | select(.target == \"${TARGET_OS}\") | .transports[0] // empty" "$HOST_TARGETS" 2>/dev/null)

if [ -z "$TRANSPORT" ]; then
    echo "ERROR: No routing entry found for ${HOST_OS} → ${TARGET_OS} in $HOST_TARGETS"
    exit 1
fi

case "$TRANSPORT" in
    native)
        if [ "$TARGET_OS" = "macos" ]; then
            # macOS target requires macOS host (may need -N bypass)
            if [ "$BYPASS_OS_CHECK" = true ] && [ "$(uname -s)" = "Darwin" ]; then
                run_native
            else
                echo "ERROR: macOS target requires macOS host. Use -N to bypass."
                exit 1
            fi
        else
            # Native only works if host matches target (e.g., fedora on fedora)
            run_native
        fi
        ;;
    ssh)
        # SSH requires a configured host in ssh_hosts.json
        local_ssh_host=$(get_ssh_host "$TARGET_OS") || {
            echo "ERROR: SSH transport selected but no host configured for $TARGET_OS"
            exit 1
        }
        if [ -z "$local_ssh_host" ]; then
            echo "ERROR: SSH transport selected but no host configured for $TARGET_OS"
            exit 1
        fi
        run_ssh
        ;;
    container)
        run_container
        ;;
    skip)
        echo "SKIP: ${HOST_OS} → ${TARGET_OS} is marked as skip in $HOST_TARGETS"
        exit 0
        ;;
    *)
        echo "ERROR: Unknown transport '$TRANSPORT' for ${HOST_OS} → ${TARGET_OS}"
        exit 1
        ;;
esac

exit $?
