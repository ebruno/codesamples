#!/usr/bin/env bash
# run_regression.sh — Execute regression tests for a target OS inside its container
# Usage: ./utils/bin/run_regression.sh [-N] [-L <lang>] <os> verify|build [image_override]
# Linux host version (bash) — uses podman

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT_NAME="run_regression.sh"
REGISTRY="${WORKSPACE}/config/toolchains.json"
LOCK_DIR="${WORKSPACE}/tmp/.run_lock"
LOCK_TIMEOUT_MIN=15

# ── Lock acquisition (prevents parallel verify_build / run_regression) ──
acquire_lock() {
    local mode="$1"
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        echo "$$" > "${LOCK_DIR}/pid"
        echo "$mode" > "${LOCK_DIR}/mode"
        date +%s > "${LOCK_DIR}/started"
        trap release_lock EXIT INT TERM
        return 0
    fi
    local pid
    pid=$(cat "${LOCK_DIR}/pid" 2>/dev/null || echo "")
    if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
        echo "Removing stale lock (PID $pid is dead)." >&2
        rm -rf "$LOCK_DIR"
        exec "$0" "$@"
    fi
    local started now age
    started=$(cat "${LOCK_DIR}/started" 2>/dev/null || echo "0")
    now=$(date +%s)
    age=$((now - started))
    if [ "$age" -gt $((LOCK_TIMEOUT_MIN * 60)) ]; then
        echo "Removing stale lock (held ${age}s > ${LOCK_TIMEOUT_MIN} min)." >&2
        rm -rf "$LOCK_DIR"
        exec "$0" "$@"
    fi
    local holder_mode
    holder_mode=$(cat "${LOCK_DIR}/mode" 2>/dev/null || echo "unknown")
    echo "ERROR: Another run is in progress (PID $pid, $holder_mode, started $(date -r "$started" 2>/dev/null || echo "unknown"))." >&2
    echo "  Wait for it to complete, or run: utils/bin/clean_stale_locks.sh" >&2
    exit 1
}

release_lock() {
    rm -rf "$LOCK_DIR" 2>/dev/null || true
}

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

CONTAINER_IMAGE="ringbuffer_${TARGET_OS}_build"

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

# ── Registry helper: read ALL compilers (including unsupported) ─────────
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

# ── Registry helper: check if a specific compiler is supported ──────
is_compiler_supported() {
    local os="$1" lang="${2:-cpp}" compiler="$3"

    if command -v jq &>/dev/null; then
        local supported
        supported=$(jq -r ".[\"${lang}\"][\"${os}\"][] | select(.name == \"${compiler}\") | .supported" "$REGISTRY" 2>/dev/null)
        [ "$supported" = "true" ] && return 0 || return 1
    elif command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('${REGISTRY}') as f:
    data = json.load(f)
for c in data.get('${lang}', {}).get('${os}', []):
    if c.get('name') == '${compiler}':
        sys.exit(0 if c.get('supported') else 1)
sys.exit(1)
" 2>/dev/null
        return $?
    else
        echo "ERROR: Neither jq nor python3 available to read registry" >&2
        return 1
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
    done < <(get_all_compilers "$TARGET_OS" "$TARGET_LANG")

    if [ ${#compilers[@]} -eq 0 ]; then
        echo "No compilers registered for ${TARGET_OS}/${TARGET_LANG} — skipping."
        return 0
    fi

    # Report all compilers (supported and unsupported)
    echo "Compilers registered for ${TARGET_OS}/${TARGET_LANG}:"
    list_all_compilers "$TARGET_OS" "$TARGET_LANG"

    for COMPILER in "${compilers[@]}"; do
        echo ""
        echo "============================================="
        echo "Compiler/Interpreter: $COMPILER"
        echo "============================================="

        # Check if compiler is supported (for cpp/c which have per-compiler support flags)
        case "$TARGET_LANG" in
            cpp|c)
                if ! is_compiler_supported "$TARGET_OS" "$TARGET_LANG" "$COMPILER"; then
                    echo "SKIPPED: $COMPILER is unsupported on ${TARGET_OS}."
                    echo "  See config/toolchains.json for details."
                    continue
                fi
                ;;
        esac

        make -C "$os_dir" clean 2>&1
        make -C "$tests_dir" clean 2>&1

        # Set the right variable based on language and probe per-compiler
        case "$TARGET_LANG" in
            cpp|c)
                make -C "$tests_dir" CXX="$COMPILER" probe-os 2>&1 || { echo "SKIP: $COMPILER failed probe check" >&2; continue; }
                make -C "$tests_dir" CXX="$COMPILER" verify 2>&1 ;;
            python)
                # Probe compiler availability if validate-tools.mk exists (skip if missing)
                local probe_makefile="${os_dir}/validate-tools.mk"
                if [ -f "$probe_makefile" ]; then
                    make -C "${os_dir}" -f validate-tools.mk PYTHON="$COMPILER" probe-os 2>&1 || { echo "SKIP: $COMPILER failed probe check" >&2; continue; }
                else
                    echo "INFO: ${probe_makefile} not present — probe-os skipped for ${TARGET_OS}/${TARGET_LANG}" >&2
                fi
                # Pass DISTRO_ID so Makefile.linux can resolve the correct C++ source dir
                make -C "$tests_dir" DISTRO_ID="$TARGET_OS" PYTHON="$COMPILER" verify 2>&1
                ;;
            java)
                # Probe compiler availability if validate-tools.mk exists (skip if missing)
                local probe_makefile="${os_dir}/validate-tools.mk"
                if [ -f "$probe_makefile" ]; then
                    make -C "${os_dir}" -f validate-tools.mk JAVA="$COMPILER" probe-os 2>&1 || { echo "SKIP: $COMPILER failed probe check" >&2; continue; }
                else
                    echo "INFO: ${probe_makefile} not present — probe-os skipped for ${TARGET_OS}/${TARGET_LANG}" >&2
                fi
                make -C "$tests_dir" JAVA="$COMPILER" verify 2>&1 ;;
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
    done < <(get_all_compilers "$TARGET_OS" "$TARGET_LANG")

    if [ ${#compilers[@]} -eq 0 ]; then
        echo "No compilers registered for ${TARGET_OS}/${TARGET_LANG} — skipping."
        make -C "$os_dir" stop_container 2>&1 || true
        return 0
    fi

    # Report all compilers (supported and unsupported)
    echo "Compilers registered for ${TARGET_OS}/${TARGET_LANG}:"
    list_all_compilers "$TARGET_OS" "$TARGET_LANG"

    # Derive running container name from image name (image: ringbuffer_<os>_test → container: ringbuffer_<os>_test_running)
    local RUNNING_CONTAINER="${CONTAINER_IMAGE}_running"

    for COMPILER in "${compilers[@]}"; do
        echo ""
        echo "============================================="
        echo "Compiler/Interpreter: $COMPILER"
        echo "============================================="

        # Check if compiler is supported (for cpp/c which have per-compiler support flags)
        case "$TARGET_LANG" in
            cpp|c)
                if ! is_compiler_supported "$TARGET_OS" "$TARGET_LANG" "$COMPILER"; then
                    echo "SKIPPED: $COMPILER is unsupported on ${TARGET_OS}."
                    echo "  See config/toolchains.json for details."
                    continue
                fi
                ;;
        esac

        # Set the right variable based on language — use make -C with absolute paths
        case "$TARGET_LANG" in
            cpp|c)
                $CONTAINER_CMD exec -e CONTAINER_CMD="$CONTAINER_CMD" "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/cpp/tests clean 2>&1
                $CONTAINER_CMD exec -e CXX="$COMPILER" -e CONTAINER_CMD="$CONTAINER_CMD" "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/cpp/tests probe-os 2>&1 || { echo "SKIP: $COMPILER failed probe check" >&2; continue; }
                $CONTAINER_CMD exec -e CXX="$COMPILER" -e CONTAINER_CMD="$CONTAINER_CMD" "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/cpp/tests verify 2>&1 ;;
            python)
                # Probe compiler availability if validate-tools.mk exists (skip if missing)
                local probe_makefile="/app/ringbuffer/src/${TARGET_OS}/${TARGET_LANG}/validate-tools.mk"
                if [ -f "$probe_makefile" ]; then
                    $CONTAINER_CMD exec -e PYTHON="$COMPILER" "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/${TARGET_LANG} -f validate-tools.mk probe-os 2>&1 || { echo "SKIP: $COMPILER failed probe check" >&2; continue; }
                else
                    echo "INFO: ${probe_makefile} not present — probe-os skipped for ${TARGET_OS}/${TARGET_LANG}" >&2
                fi
                $CONTAINER_CMD exec "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/cpp clean 2>&1
                $CONTAINER_CMD exec "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/common/python/tests clean 2>&1
                $CONTAINER_CMD exec -e PYTHON="$COMPILER" -e DISTRO_ID="$TARGET_OS" "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/common/python/tests verify 2>&1 ;;
            java)
                # Probe compiler availability if validate-tools.mk exists (skip if missing)
                local probe_makefile="/app/ringbuffer/src/${TARGET_OS}/${TARGET_LANG}/validate-tools.mk"
                if [ -f "$probe_makefile" ]; then
                    $CONTAINER_CMD exec -e JAVA="$COMPILER" "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/${TARGET_LANG} -f validate-tools.mk probe-os 2>&1 || { echo "SKIP: $COMPILER failed probe check" >&2; continue; }
                else
                    echo "INFO: ${probe_makefile} not present — probe-os skipped for ${TARGET_OS}/${TARGET_LANG}" >&2
                fi
                $CONTAINER_CMD exec "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/common/java/tests clean 2>&1
                local java_output java_rc
                java_output=$($CONTAINER_CMD exec -e JAVA="$COMPILER" "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/common/java/tests verify 2>&1) || java_rc=$?
                echo "$java_output"
                if [ "${java_rc:-0}" -ne 0 ] && echo "$java_output" | grep -qE "Network is unreachable|Could not resolve host"; then
                    echo "Network error detected — attempting recovery..."
                    "${WORKSPACE}/utils/bin/recover_container_network.sh" && {
                        echo "Retrying Java tests after network recovery..."
                        $CONTAINER_CMD exec -e JAVA="$COMPILER" "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/common/java/tests verify 2>&1
                    } || echo "WARNING: Java tests failed after network recovery"
                fi ;;
            *)      $CONTAINER_CMD exec "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/${TARGET_LANG}/tests clean 2>&1
                    $CONTAINER_CMD exec "$RUNNING_CONTAINER" make -C /app/ringbuffer/src/${TARGET_OS}/${TARGET_LANG}/tests verify 2>&1 ;;
        esac
    done

    # Cleanup: always use src/<os>/cpp/ which owns container targets
    echo "Cleaning up container..."
    make -C "${WORKSPACE}/src/${TARGET_OS}/cpp" TARGET_OS="$TARGET_OS" stop_container 2>&1 || true
    make -C "${WORKSPACE}/src/${TARGET_OS}/cpp" TARGET_OS="$TARGET_OS" remove_container 2>&1 || true
    # Fallback: direct CLI cleanup for any remaining containers
    local prefix="ringbuffer_${TARGET_OS}"
    for c in $("$CONTAINER_CMD" ps -a --format '{{.Names}}' 2>/dev/null); do
        case "$c" in ${prefix}*)
            "$CONTAINER_CMD" stop "$c" 2>/dev/null || true
            "$CONTAINER_CMD" rm -f "$c" 2>/dev/null || true
            ;;
        esac
    done
    echo "Container cleaned up."
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
            rc=$?
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
            # Map language to mode: cpp→test-cpp, java→java-test, python→python-test
            case "$TARGET_LANG" in
                cpp|c)
                    if [ "$ACTION" = "verify" ]; then _ssh_mode="test-cpp"; else _ssh_mode="cpp"; fi
                    ;;
                python)
                    if [ "$ACTION" = "verify" ]; then _ssh_mode="python-test"; else _ssh_mode="python-build"; fi
                    ;;
                java)
                    if [ "$ACTION" = "verify" ]; then _ssh_mode="java-test"; else _ssh_mode="java-build"; fi
                    ;;
                *) _ssh_mode="${ACTION}" ;;
            esac
            ssh "$ssh_host" 'bash /tmp/run_linux_ssh.sh '"${TARGET_OS}"' '"$_ssh_mode"
            rc=$?
            ssh "$ssh_host" 'rm -f /tmp/run_linux_ssh.sh'
            ;;
    esac

    # Step 6: SCP results back from remote — use resolve_lang_path for correct src dir
    echo "Copying results back..."
    local remote_lang_dir
    remote_lang_dir=$(resolve_lang_path "$TARGET_OS" "$TARGET_LANG")
    local remote_rel="${remote_lang_dir#$WORKSPACE/}"
    local remote_src_dir="${remote_rel}/tests"
    ssh "$ssh_host" 'mkdir -p ~/ringbuffer/'"${remote_src_dir}"'/reports ~/ringbuffer/'"${remote_src_dir}"'/logs'
    scp -r "${ssh_host}:~/ringbuffer/${remote_src_dir}/reports/" "$WORKSPACE/${remote_src_dir}/reports/" 2>/dev/null || echo "  (no reports to copy)"
    scp -r "${ssh_host}:~/ringbuffer/${remote_src_dir}/logs/" "$WORKSPACE/${remote_src_dir}/logs/" 2>/dev/null || echo "  (no logs to copy)"
    # Java: also fetch Maven surefire-reports (target/surefire-reports/)
    if [ "$TARGET_LANG" = "java" ]; then
        local maven_reports="${remote_rel}/target/surefire-reports"
        ssh "$ssh_host" 'mkdir -p ~/ringbuffer/'"${maven_reports}"
        mkdir -p "$WORKSPACE/${remote_rel}/target"
        scp -r "${ssh_host}:~/ringbuffer/${maven_reports}" "$WORKSPACE/${remote_rel}/target/" 2>/dev/null || echo "  (no Maven reports to copy)"
    fi

    rm -f "$tarball"
    return $rc
}

# ── Populate top-level reports/ from per-OS test reports ──────────
populate_top_reports() {
    local lang="${1:-$TARGET_LANG}" os="${2:-$TARGET_OS}"
    local lang_dir
    lang_dir=$(resolve_lang_path "$os" "$lang")
    local top_junit_dir="${WORKSPACE}/reports/${lang}/per_os/junit"
    local top_md_dir="${WORKSPACE}/reports/${lang}/per_os"
    mkdir -p "$top_junit_dir" "$top_md_dir"

    local junit_src=""

    # Check language-specific report locations
    case "$lang" in
        java)
            # Java uses Maven — reports in target/surefire-reports/
            local maven_reports="${lang_dir}/target/surefire-reports"
            if [ -d "$maven_reports" ]; then
                junit_src=$(find "$maven_reports" -name "TEST-*.xml" 2>/dev/null | head -1)
            fi
            ;;
        *)
            # C++, Python — reports in tests/reports/
            local tests_reports="${lang_dir}/tests/reports"
            if [ -d "$tests_reports" ]; then
                junit_src=$(find "$tests_reports" -name "*_regression_report_junit.xml" -o -name "regression_report_junit.xml" 2>/dev/null | head -1)
            fi
            ;;
    esac

    # Copy JUnit XML to top-level reports/<lang>/per_os/junit/
    if [ -n "$junit_src" ] && [ -f "$junit_src" ]; then
        cp "$junit_src" "${top_junit_dir}/${os}_regression_report_junit.xml" 2>/dev/null && \
            echo "  Copied to reports/${lang}/per_os/junit/${os}_regression_report_junit.xml" || true
    fi

    # Look for an existing .md report in tests/reports/ (C++/Python only)
    local md_src=""
    local tests_reports="${lang_dir}/tests/reports"
    if [ -d "$tests_reports" ]; then
        md_src=$(find "$tests_reports" -name "*_regression.md" -o -name "regression_report.md" 2>/dev/null | head -1)
    fi
    if [ -n "$md_src" ] && [ -f "$md_src" ]; then
        cp "$md_src" "${top_md_dir}/${os}_regression.md" 2>/dev/null || true
    else
        # Generate basic .md from JUnit if no .md was produced by test harness
        local top_junit="${top_junit_dir}/${os}_regression_report_junit.xml"
        if [ -f "$top_junit" ]; then
            local total failures
            total=$(grep -o 'tests="[0-9]*"' "$top_junit" | head -1 | grep -o '[0-9]*' || echo "?")
            failures=$(grep -o 'failures="[0-9]*"' "$top_junit" | head -1 | grep -o '[0-9]*' || echo "?")
            cat > "${top_md_dir}/${os}_regression.md" << MDEOF
# Regression Report — ${os} / ${lang}
**Date:** $(date '+%Y-%m-%d %H:%M:%S %z')

## Test Results
| Tests | Passed | Failed |
| :--- | :--- | :--- |
| ${total} | $((total - failures)) | ${failures} |
MDEOF
            echo "  Generated reports/${lang}/per_os/${os}_regression.md"
        elif [ -f "${lang_dir}/../UNSUPPORTED.md" ] || [ -f "${lang_dir}/UNSUPPORTED.md" ]; then
            # Platform is unsupported — generate an UNSUPPORTED report
            local unsupported_reason=""
            if [ -f "${lang_dir}/UNSUPPORTED.md" ]; then
                unsupported_reason=$(head -1 "${lang_dir}/UNSUPPORTED.md")
                unsupported_reason="${unsupported_reason#\# }"
            elif [ -f "${lang_dir}/../UNSUPPORTED.md" ]; then
                unsupported_reason=$(head -1 "${lang_dir}/../UNSUPPORTED.md")
                unsupported_reason="${unsupported_reason#\# }"
            fi
            cat > "${top_md_dir}/${os}_regression.md" << MDEOF
# Regression Report — ${os} / ${lang}
**Date:** $(date '+%Y-%m-%d %H:%M:%S %z')

## Status
**Final Result:** UNSUPPORTED

## Reason
${unsupported_reason}

## Test Results
| Tests | Passed | Failed |
| :--- | :--- | :--- |
| 0 | 0 | 0 |

Tests skipped (platform unsupported).
MDEOF
            echo "  Generated reports/${lang}/per_os/${os}_regression.md (UNSUPPORTED)"
        fi
    fi
}

# ── Main dispatch ─────────────────────────────────────────────────
# ── Acquire run lock (prevents parallel verify_build / run_regression) ──
acquire_lock "run_regression"

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
            # macOS target requires macOS host — always OK since HOST_OS is already validated above
            run_native
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

# Populate top-level reports/ from per-OS test reports
populate_top_reports

# ── Aggregate JUnit reports ──
"${WORKSPACE}/utils/bin/aggregate_junit.sh" "$WORKSPACE" 2>&1 || true

# ── Aggregate regression reports ──
"${WORKSPACE}/utils/bin/aggregate_regression.sh" "$WORKSPACE" 2>&1 || true

exit $?
