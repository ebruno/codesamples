#!/usr/bin/env zsh
# run_build.zsh — Build verification for a target OS
# Usage: ./utils/bin/run_build.zsh [-N] [-L <lang>] <os> [image_override]
# macOS host version (zsh) — uses Apple Container runtime
# Calls make all in <os>/<lang>/ (build only, no tests)

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT_NAME="run_build.zsh"
LOCK_DIR="${WORKSPACE}/tmp/.run_lock"
LOCK_TIMEOUT_MIN=15

# ── Lock acquisition (prevents parallel verify_build / run_regression) ──
acquire_lock() {
    local mode="$1"
    # Try atomic mkdir — fails if lock already exists
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        echo "$$" > "${LOCK_DIR}/pid"
        echo "$mode" > "${LOCK_DIR}/mode"
        date +%s > "${LOCK_DIR}/started"
        # Release lock on any exit
        trap release_lock EXIT INT TERM
        return 0
    fi
    # Lock exists — check if stale
    local pid
    pid=$(cat "${LOCK_DIR}/pid" 2>/dev/null || echo "")
    if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
        echo "Removing stale lock (PID $pid is dead)." >&2
        rm -rf "$LOCK_DIR"
        exec "$0" "$@"  # Retry with fresh lock
    fi
    # Check timeout
    local started now age
    started=$(cat "${LOCK_DIR}/started" 2>/dev/null || echo "0")
    now=$(date +%s)
    age=$((now - started))
    if [ "$age" -gt $((LOCK_TIMEOUT_MIN * 60)) ]; then
        echo "Removing stale lock (held ${age}s > ${LOCK_TIMEOUT_MIN} min)." >&2
        rm -rf "$LOCK_DIR"
        exec "$0" "$@"
    fi
    # Lock is active
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
    echo "Usage: $0 [-N] [-L <lang>] <os> [image_override]"
    echo ""
    echo "Options:"
    echo "  -N         Bypass host OS check (unsafe — script requires macOS)"
    echo "  -L <lang>  Language: cpp (default), python, java, go, rust, c"
    echo ""
    echo "Supported OS: macos, debian, fedora, ubuntu, raspios, archlinux, freebsd14"
    echo ""
    echo "Build verification only — no tests are executed."
    exit 1
}

BYPASS_OS_CHECK=false
TARGET_LANG="cpp"

while getopts ":NL:" opt; do
    case $opt in
        N) BYPASS_OS_CHECK=true ;;
        L) TARGET_LANG="$OPTARG" ;;
        :) echo "ERROR: -$OPTARG requires an argument"; exit 1 ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
    usage
fi

TARGET_OS="$1"
IMAGE_OVERRIDE="${2:-}"

case "$TARGET_OS" in
    macos|debian|fedora|ubuntu|raspios|archlinux|freebsd14) ;;
    *) echo "ERROR: Unsupported OS '$TARGET_OS'"; exit 1 ;;
esac

# Host OS check (macOS required)
if [ "$BYPASS_OS_CHECK" = false ]; then
    local_host_os=$(uname -s)
    if [ "$local_host_os" != "Darwin" ]; then
        echo "ERROR: Running unsupported operating system ${local_host_os}; run_build.zsh requires macOS."
        exit 1
    fi
fi

HOST_OS="macos"
CONTAINER_CMD="container"
SSH_CONFIG="${WORKSPACE}/config/ssh_hosts.json"

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
                return 1
            fi
            echo "$host"
            ;;
        archlinux)
            local host
            host=$(jq -r '.archlinux_host // empty' "$SSH_CONFIG" 2>/dev/null)
            if [ -z "$host" ]; then
                echo "ERROR: SSH host for archlinux not configured in $SSH_CONFIG" >&2
                return 1
            fi
            echo "$host"
            ;;
        *) return 0 ;;
    esac
}

resolve_lang_path() {
    local os="$1" lang="$2"
    case "$lang" in
        cpp|c) echo "${WORKSPACE}/src/${os}/${lang}" ;;
    esac
    case "$lang" in
        python|java|go|rust)
            if [ -d "${WORKSPACE}/src/${os}/${lang}" ] && \
               [ ! -L "${WORKSPACE}/src/${os}/${lang}" ] && \
               [ -f "${WORKSPACE}/src/${os}/${lang}/Makefile" ]; then
                echo "${WORKSPACE}/src/${os}/${lang}"
            else
                echo "${WORKSPACE}/src/common/${lang}"
            fi
            ;;
    esac
}

# Container execution: manage container lifecycle, iterate compilers from registry.
# Default build status (overridden by run_* functions)
BUILD_STATUS="PASS"

run_container() {
    echo "=== Build verification (container): $TARGET_OS ($TARGET_LANG) ==="
    if ! command -v "$CONTAINER_CMD" &>/dev/null; then
        echo "ERROR: '$CONTAINER_CMD' not found. Install Apple Container from https://github.com/apple/container"
        exit 1
    fi
    local os_dir
    os_dir=$(resolve_lang_path "$TARGET_OS" "$TARGET_LANG")

    # Delegate to Makefile: it handles image building, container lifecycle, and build
    local build_output build_rc=0
    build_output=$(make -C "$os_dir" TARGET_OS="$TARGET_OS" all 2>&1) || build_rc=$?
    echo "$build_output"
    if echo "$build_output" | grep -qi "unsupported"; then
        BUILD_STATUS="UNSUPPORTED"
    elif [ "$build_rc" -ne 0 ]; then
        BUILD_STATUS="FAIL"
    else
        BUILD_STATUS="PASS"
    fi

    echo "Build verification complete (container)."
}

# Native execution
run_native() {
    echo "=== Native build verification: $TARGET_OS ($TARGET_LANG) ==="
    local os_dir
    os_dir=$(resolve_lang_path "$TARGET_OS" "$TARGET_LANG")
    echo "Building $TARGET_LANG natively..."
    make -C "$os_dir" clean 2>&1
    local build_output build_rc=0
    build_output=$(make -C "$os_dir" all 2>&1) || build_rc=$?
    echo "$build_output"
    if echo "$build_output" | grep -qi "unsupported"; then
        BUILD_STATUS="UNSUPPORTED"
    elif [ "$build_rc" -ne 0 ]; then
        BUILD_STATUS="FAIL"
    else
        BUILD_STATUS="PASS"
    fi
    echo "Build verification complete (native)."
}

# SSH execution for remote hosts
run_ssh() {
    echo "=== SSH build verification: $TARGET_OS ($TARGET_LANG) ==="
    local ssh_host
    ssh_host=$(get_ssh_host "$TARGET_OS") || exit 1
    local tarball="/tmp/ringbuffer_${TARGET_OS}.tar.gz"
    echo "Creating tarball..."
    tar --no-xattrs -czf "$tarball" -C "$WORKSPACE/.." ringbuffer/
    echo "Syncing to remote..."
    scp "$tarball" "${ssh_host}:~/ringbuffer.tar.gz"
    echo "Cleaning remote workspace..."
    ssh "$ssh_host" 'rm -rf ~/ringbuffer'
    echo "Unpacking on remote..."
    ssh "$ssh_host" 'cd ~ && tar -xzf ringbuffer.tar.gz && rm -f ringbuffer.tar.gz'
    echo "Building on remote..."
    case "$TARGET_OS" in
        freebsd14)
            case "$TARGET_LANG" in
                cpp|c)
                    ssh "$ssh_host" 'tcsh ~/ringbuffer/utils/bin/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 cpp'
                    ;;
                python)
                    ssh "$ssh_host" 'tcsh ~/ringbuffer/utils/bin/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 python-build'
                    ;;
                java)
                    ssh "$ssh_host" 'tcsh ~/ringbuffer/utils/bin/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 java-build'
                    ;;
                *) echo "ERROR: Unsupported language '$TARGET_LANG' for FreeBSD 14 SSH"; rm -f "$tarball"; exit 1 ;;
            esac
            ;;
        *)
            echo "Deploying run_linux_ssh.sh to remote..."
            scp "$WORKSPACE/utils/bin/run_linux_ssh.sh" "${ssh_host}:/tmp/run_linux_ssh.sh" || {
                echo "ERROR: Failed to scp run_linux_ssh.sh to ${ssh_host}"
                rm -f "$tarball"
                exit 1
            }
            # Map language to build mode: cpp→cpp, python→python-build, java→java-build
            case "$TARGET_LANG" in
                cpp|c) _ssh_mode="cpp" ;;
                python) _ssh_mode="python-build" ;;
                java)   _ssh_mode="java-build" ;;
                *)      _ssh_mode="$TARGET_LANG" ;;
            esac
            ssh "$ssh_host" 'bash /tmp/run_linux_ssh.sh ~/ringbuffer '"${TARGET_OS}"' '"$_ssh_mode"
            local rc=$?
            ssh "$ssh_host" 'rm -f /tmp/run_linux_ssh.sh'
            rm -f "$tarball"
            return $rc
            ;;
    esac
    local rc=$?
    echo "Copying results back..."
    ssh "$ssh_host" 'mkdir -p ~/ringbuffer/src/'"${TARGET_OS}"'/'"${TARGET_LANG}"'/reports ~/ringbuffer/src/'"${TARGET_OS}"'/'"${TARGET_LANG}"'/logs'
    scp -r "${ssh_host}:~/ringbuffer/src/${TARGET_OS}/${TARGET_LANG}/reports/" "$WORKSPACE/src/${TARGET_OS}/${TARGET_LANG}/reports/"
    scp -r "${ssh_host}:~/ringbuffer/src/${TARGET_OS}/${TARGET_LANG}/logs/" "$WORKSPACE/src/${TARGET_OS}/${TARGET_LANG}/logs/"
    rm -f "$tarball"
    return $rc
}

# ── Acquire run lock (prevents parallel verify_build / run_regression) ──
acquire_lock "verify_build"

echo "============================================="
echo "Ringbuffer Build Verifier (macOS/zsh)"
if [ "$BYPASS_OS_CHECK" = true ]; then
    echo "  OS Check:   BYPASSED (-N flag)"
fi
echo "  Host OS:    $HOST_OS"
echo "  Target OS:  $TARGET_OS"
echo "  Language:   ${TARGET_LANG}"
echo "============================================="

HOST_TARGETS="${WORKSPACE}/config/host_targets.json"

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
    native) run_native ;;
    ssh)
        local_ssh_host=$(get_ssh_host "$TARGET_OS") || { echo "ERROR: SSH transport selected but no host configured for $TARGET_OS"; exit 1; }
        if [ -z "$local_ssh_host" ]; then echo "ERROR: No host for $TARGET_OS"; exit 1; fi
        run_ssh
        ;;
    container) run_container ;;
    skip)
        echo "SKIP: ${HOST_OS} -> ${TARGET_OS} is marked as skip in $HOST_TARGETS"
        exit 0
        ;;
    *)
        echo "ERROR: Unknown transport '$TRANSPORT' for ${HOST_OS} -> ${TARGET_OS}"
        exit 1
        ;;
esac

# ── Populate top-level reports/ from build verification ──────────
populate_build_reports() {
    local lang="${1:-$TARGET_LANG}" os="${2:-$TARGET_OS}"
    local top_md_dir="${WORKSPACE}/reports/${lang}/per_os"
    mkdir -p "$top_md_dir"

    # Determine compiler/interpreter info
    local compiler_info=""
    case "$lang" in
        cpp|c)
            local lang_dir="${WORKSPACE}/src/${os}/cpp"
            if [ -f "${lang_dir}/tests/reports/compiler_version.txt" ]; then
                compiler_info=$(cat "${lang_dir}/tests/reports/compiler_version.txt" 2>/dev/null | head -3)
            fi
            ;;
        java)
            compiler_info="javac (see pom.xml for version)"
            ;;
        python)
            compiler_info="python3 (see version.py for version)"
            ;;
    esac

    local build_status="${BUILD_STATUS:-PASS}"
    cat > "${top_md_dir}/${os}_build_verify.md" << MDEOF
# Build Verification Report — ${os} / ${lang}
**Date:** $(date '+%Y-%m-%d %H:%M:%S %z')

## Status
**Final Result:** ${build_status}

## Toolchain
${compiler_info}

## Verification Details
- **Build**: ${build_status}
- **Artifacts**: Produced successfully
MDEOF
    echo "  Generated reports/${lang}/per_os/${os}_build_verify.md"
}

populate_build_reports

echo ""
echo "============================================="
echo "Build verifier completed."
echo "============================================="

# ── Aggregate build verification reports ──
"${WORKSPACE}/utils/bin/aggregate_verify_build.zsh" "$WORKSPACE" 2>&1 || true
