#!/usr/bin/env zsh
# run_regression.zsh — Execute regression tests for a target OS inside its container
# Usage: ./utils/bin/run_regression.zsh [-N] [-L <lang>] <os> verify|build [image_override]
# macOS host version (zsh) — uses Apple Container runtime

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT_NAME="run_regression.zsh"
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

    # Container image: unified _build per OS (built by C++ Makefile)
    local CONTAINER_IMAGE_NAME="ringbuffer_${TARGET_OS}_build"
    if [ -n "$IMAGE_OVERRIDE" ]; then
        CONTAINER_IMAGE_NAME="$IMAGE_OVERRIDE"
    fi
    local CONTAINER_NAME="${CONTAINER_IMAGE_NAME}_running"

    # Check if image exists; any language can build the per-OS container
    echo "Checking for container image: $CONTAINER_IMAGE_NAME"
    if ! "$CONTAINER_CMD" inspect "$CONTAINER_IMAGE_NAME" &>/dev/null; then
        echo "Image not found. Building via src/${TARGET_OS}/cpp/Makefile..."
        make -C "${WORKSPACE}/src/${TARGET_OS}/cpp" TARGET_OS="$TARGET_OS" container 2>&1
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to build container image $CONTAINER_IMAGE_NAME"
            exit 1
        fi
    else
        echo "Image $CONTAINER_IMAGE_NAME found."
    fi

    # Stop and remove any stale container from previous run
    "$CONTAINER_CMD" stop "$CONTAINER_NAME" 2>/dev/null || true
    "$CONTAINER_CMD" rm -f "$CONTAINER_NAME" 2>/dev/null || true

    # Start container via Makefile (Makefiles own container lifecycle)
    echo "Starting container via Makefile..."
    make -C "${WORKSPACE}/src/${TARGET_OS}/cpp" TARGET_OS="$TARGET_OS" start_container 2>&1

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to start container"
        exit 1
    fi

    # Execute commands inside the container
    echo "Executing commands in container..."

    case "$TARGET_LANG" in
        cpp)
            # C++ tests — use per-OS paths
            local os_dir tests_dir
            os_dir="${WORKSPACE}/src/${TARGET_OS}/cpp"
            tests_dir="${os_dir}/tests"

            # Get all compilers from registry (including unsupported)
            local all_compilers=()
            while IFS= read -r c; do
                [ -n "$c" ] && all_compilers+=("$c")
            done < <(get_all_compilers "$TARGET_OS" "cpp")

            if [ ${#all_compilers[@]} -eq 0 ]; then
                echo "No compilers registered for ${TARGET_OS}/cpp — skipping."
                return 0
            fi

            # Report all compilers from registry
            echo "Compilers registered for ${TARGET_OS}/cpp:"
            list_all_compilers "$TARGET_OS" "cpp"

            for COMPILER in "${all_compilers[@]}"; do
                echo ""
                echo "============================================="
                echo "Compiler: $COMPILER"
                echo "============================================="

                if is_compiler_supported "$TARGET_OS" "cpp" "$COMPILER"; then
                    # Clean and verify with specific compiler — delegate to tests Makefile inside container
                    "$CONTAINER_CMD" exec -i "$CONTAINER_NAME" sh -c "cd /app/ringbuffer/src/${TARGET_OS}/cpp/tests && make clean CXX=$COMPILER && make verify CXX=$COMPILER" 2>&1 || echo "  WARNING: $COMPILER verification had errors (check logs)"
                else
                    echo "SKIPPED: $COMPILER is unsupported on ${TARGET_OS}."
                    echo "  See config/toolchains.json for details."
                fi
            done
            ;;
        python)
            # Python — depends on C++ library first
            local os_dir tests_dir
            os_dir=$(resolve_lang_path "$TARGET_OS" "python")
            tests_dir="${os_dir}/tests"
            # Convert workspace-absolute path to container-relative (strip $WORKSPACE/)
            local rel_os_dir="${os_dir#$WORKSPACE/}"
            local rel_tests_dir="${tests_dir#$WORKSPACE/}"

            # Build C++ library first (java and python depend on it)
            echo "Building C++ library..."
            "$CONTAINER_CMD" exec -i "$CONTAINER_NAME" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/cpp clean && make -C src/${TARGET_OS}/cpp all" 2>&1

            # Probe compiler availability if validate-tools.mk exists
            local probe_makefile="${os_dir}/validate-tools.mk"
            if [ -f "$probe_makefile" ]; then
                echo "Running probe-os for ${TARGET_OS}/${TARGET_LANG}..."
                "$CONTAINER_CMD" exec -i "$CONTAINER_NAME" sh -c "cd /app/ringbuffer/${rel_os_dir} && make probe-os" 2>&1
            else
                echo "INFO: ${probe_makefile} not present — probe-os skipped for ${TARGET_OS}/${TARGET_LANG}" >&2
            fi

            # Clean and verify Python tests — use resolve_lang_path for correct dir
            echo "Running Python tests..."
            "$CONTAINER_CMD" exec -i "$CONTAINER_NAME" sh -c "cd /app/ringbuffer/${rel_os_dir} && make clean && cd /app/ringbuffer/${rel_tests_dir} && make clean && make PYTHON=python3 verify" 2>&1
            ;;
        java)
            # Java — depends on C++ library first
            local os_dir tests_dir
            os_dir=$(resolve_lang_path "$TARGET_OS" "java")
            tests_dir="${os_dir}/tests"
            local rel_os_dir="${os_dir#$WORKSPACE/}"
            local rel_tests_dir="${tests_dir#$WORKSPACE/}"

            # Build C++ library first (java depends on it)
            echo "Building C++ library..."
            "$CONTAINER_CMD" exec -i "$CONTAINER_NAME" sh -c "cd /app/ringbuffer && make -C src/${TARGET_OS}/cpp clean && make -C src/${TARGET_OS}/cpp all" 2>&1

            # Probe compiler availability if validate-tools.mk exists
            local probe_makefile="${os_dir}/validate-tools.mk"
            if [ -f "$probe_makefile" ]; then
                echo "Running probe-os for ${TARGET_OS}/${TARGET_LANG}..."
                "$CONTAINER_CMD" exec -i "$CONTAINER_NAME" sh -c "cd /app/ringbuffer/${rel_os_dir} && make probe-os" 2>&1
            else
                echo "INFO: ${probe_makefile} not present — probe-os skipped for ${TARGET_OS}/${TARGET_LANG}" >&2
            fi

            # Clean and verify Java tests — use resolve_lang_path for correct dir
            echo "Running Java tests..."
            local java_output java_rc
            java_output=$("$CONTAINER_CMD" exec -i "$CONTAINER_NAME" sh -c "cd /app/ringbuffer/${rel_os_dir} && make clean && cd /app/ringbuffer/${rel_tests_dir} && make clean && make JAVA=javac verify" 2>&1) || java_rc=$?
            echo "$java_output"
            if [ "${java_rc:-0}" -ne 0 ] && echo "$java_output" | grep -qE "Network is unreachable|Could not resolve host"; then
                echo "Network error detected — attempting recovery..."
                if "${WORKSPACE}/utils/bin/recover_container_network.zsh"; then
                    echo "Restarting container after system recovery..."
                    make -C "${WORKSPACE}/src/${TARGET_OS}/cpp" TARGET_OS="$TARGET_OS" start_container 2>&1
                    echo "Retrying Java tests..."
                    "$CONTAINER_CMD" exec -i "$CONTAINER_NAME" sh -c "cd /app/ringbuffer/${rel_os_dir} && make clean && cd /app/ringbuffer/${rel_tests_dir} && make clean && make JAVA=javac verify" 2>&1
                else
                    echo "WARNING: Network recovery failed — Java tests skipped"
                fi
            fi
            ;;
        *)
            echo "ERROR: Unsupported language '$TARGET_LANG' for container execution"
            exit 1
            ;;
    esac

    cleanup_container "$CONTAINER_NAME"
    echo "Container tests completed successfully."
}

# ── Cleanup container ──────────────────────────────────────────────
cleanup_container() {
    echo "Cleaning up container..."
    # Try Makefile targets first
    make -C "${WORKSPACE}/src/${TARGET_OS}/cpp" TARGET_OS="$TARGET_OS" stop_container 2>&1 || true
    make -C "${WORKSPACE}/src/${TARGET_OS}/cpp" TARGET_OS="$TARGET_OS" remove_container 2>&1 || true
    # Fallback: stop/remove any remaining containers for this OS
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
                *) _ssh_mode="test-${TARGET_LANG}" ;;
            esac
            ssh "$ssh_host" 'bash /tmp/run_linux_ssh.sh ~/ringbuffer '"${TARGET_OS}"' '"$_ssh_mode"
            rc=$?
            ssh "$ssh_host" 'rm -f /tmp/run_linux_ssh.sh'
            ;;
    esac

    # Step 6: SCP results back from remote — use resolve_lang_path for correct src dir
    echo "Copying results back..."
    local remote_lang_dir
    remote_lang_dir=$(resolve_lang_path "$TARGET_OS" "$TARGET_LANG")
    # Convert workspace path to remote-relative path: strip $WORKSPACE/ prefix
    local remote_rel="${remote_lang_dir#$WORKSPACE/}"
    # Reports/logs are in tests/ subdirectory
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

                # Get all compilers from registry (including unsupported)
                local compilers=()
                while IFS= read -r c; do
                    [ -n "$c" ] && compilers+=("$c")
                done < <(get_all_compilers "$TARGET_OS" "cpp")

                if [ ${#compilers[@]} -eq 0 ]; then
                    echo "No compilers registered for ${TARGET_OS}/cpp — skipping."
                    return 0
                fi

                # Report all compilers from registry
                echo "Compilers registered for ${TARGET_OS}/cpp:"
                list_all_compilers "$TARGET_OS" "cpp"

                for COMPILER in "${compilers[@]}"; do
                    echo ""
                    echo "============================================="
                    echo "Compiler: $COMPILER"
                    echo "============================================="

                    if ! is_compiler_supported "$TARGET_OS" "cpp" "$COMPILER"; then
                        echo "SKIPPED: $COMPILER is unsupported on ${TARGET_OS}."
                        echo "  See config/toolchains.json for details."
                        continue
                    fi

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
                probe_makefile="${os_dir}/validate-tools.mk"
                if [ -f "$probe_makefile" ]; then
                    echo "Running probe-os for ${TARGET_OS}/${TARGET_LANG}..."
                    make -C "${os_dir}" probe-os 2>&1
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
                probe_makefile="${os_dir}/validate-tools.mk"
                if [ -f "$probe_makefile" ]; then
                    echo "Running probe-os for ${TARGET_OS}/${TARGET_LANG}..."
                    make -C "${os_dir}" probe-os 2>&1
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

# Populate top-level reports/ from per-OS test reports
populate_top_reports

# ── Aggregate JUnit reports ──
"${WORKSPACE}/utils/bin/aggregate_junit.zsh" "$WORKSPACE" 2>&1 || true

# ── Aggregate regression reports ──
"${WORKSPACE}/utils/bin/aggregate_regression.zsh" "$WORKSPACE" 2>&1 || true

echo ""
echo "============================================="
echo "Regression runner completed."
echo "============================================="
