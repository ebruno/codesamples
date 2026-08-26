#!/usr/bin/env zsh
# run_regression.zsh — Execute regression tests for a target OS inside its container
# Usage: ./utils/bin/run_regression.zsh [-N] [-L <lang>] <os> verify|build [image_override]
# macOS host version (zsh) — uses Apple Container runtime

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT_NAME="run_regression.zsh"
REGISTRY="${WORKSPACE}/config/toolchains.json"

usage() {
    echo "Usage: $0 [-N] [-L <lang>] <os> verify|build [image_override]"
    echo ""
    echo "Options:"
    echo "  -N         Bypass host OS check (unsafe — script requires macOS)"
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

# ── Host OS check (macOS required) ────────────────────────────────
if [ "$BYPASS_OS_CHECK" = false ]; then
    local_host_os=$(uname -s)
    if [ "$local_host_os" != "Darwin" ]; then
        echo "ERROR: Running unsupported operating system ${local_host_os}; run_regression.zsh requires macOS."
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

# ── Constants ──────────────────────────────────────────────────────
HOST_OS="macos"
CONTAINER_CMD="container"

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
               [ ! -L "${WORKSPACE}/src/${os}/${lang}" ] && \
               [ -d "${WORKSPACE}/src/${os}/${lang}/tests" ]; then
                # OS override exists (real directory with tests/, not symlink)
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
}

# ── Registry helper: read compiler list for <os> + <lang> from JSON ───
get_all_compilers() {
    local os="$1" lang="${2:-cpp}"

    if command -v jq &>/dev/null; then
        jq -r ".[\"${lang}\"][\"${os}\"][] | .name" "$REGISTRY" 2>/dev/null
    elif command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('${REGISTRY}') as f:
    data = json.load(f)
for c in data.get('${lang}', {}).get('${os}', []):
    print(c['name'])
" 2>/dev/null
    else
        echo "ERROR: Neither jq nor python3 available to read registry" >&2
        return 1
    fi
}

# ── Container execution ────────────────────────────────────────────
run_container() {
    echo "=== Container execution: $ACTION on $TARGET_OS ($TARGET_LANG) ==="

    # Check if container runtime is available
    if ! command -v "$CONTAINER_CMD" &>/dev/null; then
        echo "ERROR: '$CONTAINER_CMD' not found. Install Apple Container from https://github.com/apple/container"
        exit 1
    fi

    # Resolve paths
    local os_dir tests_dir workspace_dir
    os_dir=$(resolve_lang_path "$TARGET_OS" "$TARGET_LANG")
    tests_dir="${os_dir}/tests"

    # Determine workspace directory for mounting
    if [ "$TARGET_OS" = "common" ]; then
        # For common language tests, mount from project root
        workspace_dir="${WORKSPACE}"
    else
        workspace_dir="${WORKSPACE}"
    fi

    # Determine container image name
    local CONTAINER_IMAGE_NAME
    if [ -n "$IMAGE_OVERRIDE" ]; then
        CONTAINER_IMAGE_NAME="$IMAGE_OVERRIDE"
    elif [ "$ACTION" = "verify" ]; then
        CONTAINER_IMAGE_NAME="ringbuffer_${TARGET_OS}_test"
    else
        CONTAINER_IMAGE_NAME="ringbuffer_${TARGET_OS}_build"
    fi

    # Check if image exists, build if not
    echo "Checking for container image: $CONTAINER_IMAGE_NAME"
    if ! "$CONTAINER_CMD" inspect "$CONTAINER_IMAGE_NAME" &>/dev/null; then
        echo "Image not found. Building..."
        make -C "$os_dir" TARGET_OS="$TARGET_OS" build_image 2>&1
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to build container image $CONTAINER_IMAGE_NAME"
            exit 1
        fi
    else
        echo "Image $CONTAINER_IMAGE_NAME found."
    fi

    # Check if container is already running
    local RUNNING_CONTAINER=""
    RUNNING_CONTAINER=$("$CONTAINER_CMD" ps --filter "ancestor=$CONTAINER_IMAGE_NAME" --format '{{.Names}}' 2>/dev/null | head -1)

    if [ -z "$RUNNING_CONTAINER" ]; then
        # Start a new container in detached mode
        echo "Starting container..."
        "$CONTAINER_CMD" run --detach \
            --name "ringbuffer_${TARGET_OS}_test_running" \
            -v "${workspace_dir}:/app/ringbuffer" \
            --cpus 4 \
            --memory 1024m \
            "$CONTAINER_IMAGE_NAME" \
            tail -f /dev/null 2>&1

        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to start container"
            exit 1
        fi
        RUNNING_CONTAINER="ringbuffer_${TARGET_OS}_test_running"
    else
        echo "Container $RUNNING_CONTAINER already running."
    fi

    # Execute commands inside the container
    echo "Executing commands in container..."

    case "$TARGET_LANG" in
        cpp)
            # C++ tests — use per-OS paths
            local os_dir tests_dir
            os_dir="${WORKSPACE}/src/${TARGET_OS}/cpp"
            tests_dir="${os_dir}/tests"

            # Get compilers from registry
            local compilers=()
            while IFS= read -r c; do
                [ -n "$c" ] && compilers+=("$c")
            done < <(get_compilers "$TARGET_OS" "cpp")

            if [ ${#compilers[@]} -eq 0 ]; then
                echo "ERROR: No supported compilers found for ${TARGET_OS}/cpp"
                exit 1
            fi

            echo "Compilers from registry: ${compilers[*]}"

            for COMPILER in "${compilers[@]}"; do
                echo ""
                echo "============================================="
                echo "Compiler: $COMPILER"
                echo "============================================="

                # Clean and verify with specific compiler — use cd + exec, no bash -c
                "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/cpp clean" 2>&1
                "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/cpp/tests clean" 2>&1
                "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/cpp/tests CXX=$COMPILER verify" 2>&1
            done
            ;;
        python)
            # Python — depends on C++ library first
            local os_dir tests_dir
            os_dir=$(resolve_lang_path "$TARGET_OS" "python")
            tests_dir="${os_dir}/tests"

            # Build C++ library first (java and python depend on it)
            echo "Building C++ library..."
            "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/cpp clean" 2>&1

            # Probe compiler availability if validate-tools.mk exists (abort on failure, skip if missing)
            local probe_makefile="${WORKSPACE}/src/${TARGET_OS}/${TARGET_LANG}/validate-tools.mk"
            if [ -f "$probe_makefile" ]; then
                echo "Running probe-os for ${TARGET_OS}/${TARGET_LANG}..."
                "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/${TARGET_LANG} probe-os" 2>&1
            else
                echo "INFO: ${probe_makefile} not present — probe-os skipped for ${TARGET_OS}/${TARGET_LANG}" >&2
            fi

            # Clean and verify Python tests
            echo "Running Python tests..."
            "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/python clean" 2>&1
            "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/python/tests clean" 2>&1
            "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/python/tests PYTHON=python3 verify" 2>&1
            ;;
        java)
            # Java — depends on C++ library first
            local os_dir tests_dir
            os_dir=$(resolve_lang_path "$TARGET_OS" "java")
            tests_dir="${os_dir}/tests"

            # Build C++ library first (java depends on it)
            echo "Building C++ library..."
            "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/cpp clean" 2>&1

            # Probe compiler availability if validate-tools.mk exists (abort on failure, skip if missing)
            local probe_makefile="${WORKSPACE}/src/${TARGET_OS}/${TARGET_LANG}/validate-tools.mk"
            if [ -f "$probe_makefile" ]; then
                echo "Running probe-os for ${TARGET_OS}/${TARGET_LANG}..."
                "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/${TARGET_LANG} probe-os" 2>&1
            else
                echo "INFO: ${probe_makefile} not present — probe-os skipped for ${TARGET_OS}/${TARGET_LANG}" >&2
            fi

            # Clean and verify Java tests
            echo "Running Java tests..."
            "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/java clean" 2>&1
            "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/java/tests clean" 2>&1
            "$CONTAINER_CMD" exec "$RUNNING_CONTAINER" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/java/tests JAVA=javac verify" 2>&1
            ;;
        *)
            echo "ERROR: Unsupported language '$TARGET_LANG' for container execution"
            exit 1
            ;;
    esac

    echo "Container tests completed successfully."
}

# ── Cleanup container ──────────────────────────────────────────────
cleanup_container() {
    local RUNNING_CONTAINER=""
    RUNNING_CONTAINER=$("$CONTAINER_CMD" ps --filter "ancestor=ringbuffer_${TARGET_OS}_test:latest" --format '{{.Names}}' 2>/dev/null | head -1)

    if [ -n "$RUNNING_CONTAINER" ]; then
        echo "Stopping container..."
        make -C "$os_dir" TARGET_OS="$TARGET_OS" stop_container 2>&1 || true
        echo "Removing container..."
        make -C "$os_dir" TARGET_OS="$TARGET_OS" remove_container 2>&1 || true

        echo "Container stopped and removed. Image $CONTAINER_IMAGE remains."
    fi
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
    tar --no-xattrs -czf "$tarball" -C "$WORKSPACE/.." ringbuffer/

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
            ssh "$ssh_host" 'bash /tmp/run_linux_ssh.sh ~/ringbuffer '"${TARGET_OS}"' test-'"${TARGET_LANG}"
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
echo "Ringbuffer Regression Runner (macOS/zsh)"
if [ "$BYPASS_OS_CHECK" = true ]; then
    echo "  OS Check:   BYPASSED (-N flag)"
fi
echo "  Host OS:    $HOST_OS"
echo "  Target OS:  $TARGET_OS"
echo "  Language:   ${TARGET_LANG}"
echo "  Action:     $ACTION"
echo "============================================="

# ── Read build workflow document for routing rules ────────────────
echo ""
echo "Loading build workflow from rules/regression-runner-spec.md..."
if [ -f "${WORKSPACE}/rules/regression-runner-spec.md" ]; then
    echo "  ✓ Loaded rules/regression-runner-spec.md"
else
    echo "  WARNING: rules/regression-runner-spec.md not found — using built-in routing"
fi

# ── Host-to-Target Routing ────────────────────────────────────────
HOST_TARGETS="${WORKSPACE}/config/host_targets.json"

# Determine transport method (native, container, ssh, skip)
get_transport() {
    local host="$1" target="$2"

    if [ ! -f "$HOST_TARGETS" ]; then
        echo "ERROR: Host targets config not found at $HOST_TARGETS" >&2
        return 1
    fi

    if command -v jq &>/dev/null; then
        local transport
        transport=$(jq -r ".[\"${host}\"].targets[] | select(.target == \"${target}\") | .transports[0] // empty" "$HOST_TARGETS" 2>/dev/null)
        if [ -z "$transport" ]; then
            transport="native"
        fi
        echo "$transport"
    elif command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('${HOST_TARGETS}') as f:
    data = json.load(f)
targets = data.get('${host}', {}).get('targets', [])
for t in targets:
    if t.get('target') == '${target}':
        print(t['transports'][0])
        sys.exit(0)
print('native')
" 2>/dev/null
    else
        echo "ERROR: Neither jq nor python3 available to read host targets" >&2
        return 1
    fi
}

TRANSPORT=$(get_transport "$HOST_OS" "$TARGET_OS") || exit 1
echo "Transport: $TRANSPORT (from host_targets.json)"

case "$TRANSPORT" in
    native)
        echo "Running natively on $HOST_OS..."

        # Resolve paths for native execution
        os_dir=$(resolve_lang_path "$TARGET_OS" "$TARGET_LANG")
        tests_dir="${os_dir}/tests"

        case "$TARGET_LANG" in
            cpp)
                # C++ native — use per-OS paths
                os_dir="${WORKSPACE}/src/${TARGET_OS}/cpp"
                tests_dir="${os_dir}/tests"

                # Get compilers from registry
                local compilers=()
                while IFS= read -r c; do
                    [ -n "$c" ] && compilers+=("$c")
                done < <(get_compilers "$TARGET_OS" "cpp")

                if [ ${#compilers[@]} -eq 0 ]; then
                    echo "ERROR: No supported compilers found for ${TARGET_OS}/cpp"
                    exit 1
                fi

                echo "Compilers from registry: ${compilers[*]}"

                for COMPILER in "${compilers[@]}"; do
                    echo ""
                    echo "============================================="
                    echo "Compiler: $COMPILER"
                    echo "============================================="

                    make -C "$os_dir" clean 2>&1
                    make -C "$tests_dir" clean 2>&1
                    make -C "$tests_dir" CXX="$COMPILER" verify 2>&1
                done
                ;;
            python)
                # Python native — depends on C++ library first
                os_dir=$(resolve_lang_path "$TARGET_OS" "python")
                tests_dir="${os_dir}/tests"

                # Build C++ library first (java and python depend on it)
                echo "Building C++ library..."
                make -C "${WORKSPACE}/src/${TARGET_OS}/cpp" clean 2>&1

                # Probe compiler availability if validate-tools.mk exists (abort on failure, skip if missing)
                probe_makefile="${WORKSPACE}/src/${TARGET_OS}/${TARGET_LANG}/validate-tools.mk"
                if [ -f "$probe_makefile" ]; then
                    echo "Running probe-os for ${TARGET_OS}/${TARGET_LANG}..."
                    make -C "${WORKSPACE}/src/${TARGET_OS}/${TARGET_LANG}" probe-os 2>&1
                else
                    echo "INFO: ${probe_makefile} not present — probe-os skipped for ${TARGET_OS}/${TARGET_LANG}" >&2
                fi

                # Clean and verify Python tests
                echo "Running Python tests..."
                make -C "$os_dir" clean 2>&1
                make -C "$tests_dir" clean 2>&1
                PYTHON="python3" make -C "$tests_dir" verify 2>&1
                ;;
            java)
                # Java native — depends on C++ library first
                os_dir=$(resolve_lang_path "$TARGET_OS" "java")
                tests_dir="${os_dir}/tests"

                # Build C++ library first (java depends on it)
                echo "Building C++ library..."
                make -C "${WORKSPACE}/src/${TARGET_OS}/cpp" clean 2>&1

                # Probe compiler availability if validate-tools.mk exists (abort on failure, skip if missing)
                probe_makefile="${WORKSPACE}/src/${TARGET_OS}/${TARGET_LANG}/validate-tools.mk"
                if [ -f "$probe_makefile" ]; then
                    echo "Running probe-os for ${TARGET_OS}/${TARGET_LANG}..."
                    make -C "${WORKSPACE}/src/${TARGET_OS}/${TARGET_LANG}" probe-os 2>&1
                else
                    echo "INFO: ${probe_makefile} not present — probe-os skipped for ${TARGET_OS}/${TARGET_LANG}" >&2
                fi

                # Clean and verify Java tests
                echo "Running Java tests..."
                make -C "$os_dir" clean 2>&1
                make -C "$tests_dir" clean 2>&1
                JAVA="javac" make -C "$tests_dir" verify 2>&1
                ;;
            *)
                echo "ERROR: Unsupported language '$TARGET_LANG' for native execution"
                exit 1
                ;;
        esac
        ;;
    ssh)
        # SSH transport — requires configured host in ssh_hosts.json
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

echo ""
echo "============================================="
echo "Regression runner completed."
echo "============================================="
