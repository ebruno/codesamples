#!/usr/bin/env bash
# run_linux_ssh.sh — Native build/test runner for Linux distros
# Usage: ./run_linux_ssh.sh [-N] <ringbuffer_path> <os_name> [mode]
#   mode: "cpp" (default, build), "test-cpp",
#         "python-build", "python-test",
#         "java-build", "java-test"
#
# This script runs natively on a Linux host. It does NOT use containers or SSH.
# One script serves all Linux distros (fedora, debian, ubuntu, raspios, archlinux).

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
REGISTRY="${WORKSPACE}/config/toolchains.json"

# ── Parse arguments (handle -N flag) ───────────────────────────────
BYPASS_OS_CHECK=false

while getopts ":N" opt; do
    case $opt in
        N) BYPASS_OS_CHECK=true ;;
        *) echo "ERROR: Unknown option -$OPTARG"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

ringbuffer_path="${1:?Usage: $0 [-N] <ringbuffer_path> <os_name> [mode]}"
os_name="${2:?Usage: $0 [-N] <ringbuffer_path> <os_name> [mode]}"
mode="${3:-cpp}"

# ── Host OS check (Linux required) ────────────────────────────────
if [ "$BYPASS_OS_CHECK" = false ]; then
    local_host_os=$(uname -s)
    if [ "$local_host_os" != "Linux" ]; then
        echo "ERROR: Running unsupported operating system ${local_host_os}; run_linux_ssh.sh requires Linux."
        exit 1
    fi
fi

# ── Validate OS ───────────────────────────────────────────────────
case "$os_name" in
    fedora|debian|ubuntu|raspios|archlinux) ;;
    *) echo "ERROR: Unsupported OS '$os_name'. Supported: fedora, debian, ubuntu, raspios, archlinux"; exit 1 ;;
esac

# ── Validate mode ────────────────────────────────────────────────
case "$mode" in
    cpp|test-cpp|python-build|python-test|java-build|java-test) ;;
    *) echo "ERROR: Unsupported mode '$mode'. Supported: cpp, test-cpp, python-build, python-test, java-build, java-test"; exit 1 ;;
esac

# ── Language path resolution ───────────────────────────────────────
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
                echo "${WORKSPACE}/src/${os}/${lang}"
            else
                echo "${WORKSPACE}/src/common/${lang}"
            fi
            ;;
    esac
}

# ── Registry helper: read compilers for <os> + <lang> from JSON ───
get_compilers() {
    local os="$1" lang="${2:-cpp}"

    if command -v jq &>/dev/null; then
        jq -r ".[\"${lang}\"][\"${os}\"][]?" "$REGISTRY" 2>/dev/null
    elif command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('${REGISTRY}') as f:
    data = json.load(f)
for c in data.get('${lang}', {}).get('${os}', []):
    print(c)
" 2>/dev/null
    else
        echo "ERROR: Neither jq nor python3 available to read registry" >&2
        return 1
    fi
}

# ── C++ build (default) — uses src/<os>/cpp/ per-OS source ────────
if [ "$mode" = "cpp" ]; then
    echo "=== Native build: C++ on $os_name ==="

    os_dir="${WORKSPACE}/src/${os_name}/cpp"
    if [ ! -d "$os_dir" ]; then
        echo "ERROR: $os_dir does not exist."
        exit 1
    fi

    compilers=()
    while IFS= read -r c; do
        [ -n "$c" ] && compilers+=("$c")
    done < <(get_compilers "$os_name" "cpp")

    if [ ${#compilers[@]} -eq 0 ]; then
        echo "ERROR: No compilers found in registry for ${os_name}/cpp"
        exit 1
    fi

    echo "Compilers from registry: ${compilers[*]}"

    for COMPILER in "${compilers[@]}"; do
        echo ""
        echo "============================================="
        echo "Compiler: $COMPILER"
        echo "============================================="
        make -C "$os_dir" clean 2>&1
        CXX="$COMPILER" make -C "$os_dir" all 2>&1
    done

# ── C++ tests — uses src/<os>/cpp/tests/ per-OS test directory ───
elif [ "$mode" = "test-cpp" ]; then
    echo "=== Native test: C++ on $os_name ==="

    os_dir="${WORKSPACE}/src/${os_name}/cpp"
    tests_dir="${os_dir}/tests"

    if [ ! -d "$tests_dir" ]; then
        echo "ERROR: $tests_dir does not exist."
        exit 1
    fi

    compilers=()
    while IFS= read -r c; do
        [ -n "$c" ] && compilers+=("$c")
    done < <(get_compilers "$os_name" "cpp")

    if [ ${#compilers[@]} -eq 0 ]; then
        echo "ERROR: No compilers found in registry for ${os_name}/cpp"
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
        CXX="$COMPILER" make -C "$tests_dir" verify 2>&1
    done

# ── Python build — uses src/common/python/ source, per-OS Makefile ─
elif [ "$mode" = "python-build" ]; then
    echo "=== Native build: Python on $os_name ==="

    os_dir=$(resolve_lang_path "$os_name" "python")
    if [ ! -d "$os_dir" ]; then
        echo "ERROR: $os_dir does not exist."
        exit 1
    fi

    make -C "$os_dir" clean 2>&1
    PYTHON="python3" make -C "$os_dir" all 2>&1

# ── Python tests — uses src/<os>/python/tests/ Makefile ───────────
elif [ "$mode" = "python-test" ]; then
    echo "=== Native test: Python on $os_name ==="

    os_dir=$(resolve_lang_path "$os_name" "python")
    tests_dir="${os_dir}/tests"

    if [ ! -d "$tests_dir" ]; then
        echo "ERROR: $tests_dir does not exist."
        exit 1
    fi

    make -C "$os_dir" clean 2>&1
    make -C "$tests_dir" clean 2>&1
    PYTHON="python3" make -C "$tests_dir" verify 2>&1

# ── Java build — uses src/common/java/ source, per-OS Makefile ────
elif [ "$mode" = "java-build" ]; then
    echo "=== Native build: Java on $os_name ==="

    os_dir=$(resolve_lang_path "$os_name" "java")
    if [ ! -d "$os_dir" ]; then
        echo "ERROR: $os_dir does not exist."
        exit 1
    fi

    make -C "$os_dir" clean 2>&1
    JAVA="javac" make -C "$os_dir" all 2>&1

# ── Java tests — uses src/<os>/java/ Makefile (Maven native) ─────
elif [ "$mode" = "java-test" ]; then
    echo "=== Native test: Java on $os_name ==="

    os_dir=$(resolve_lang_path "$os_name" "java")
    if [ ! -d "$os_dir" ]; then
        echo "ERROR: $os_dir does not exist."
        exit 1
    fi

    make -C "$os_dir" clean 2>&1
    JAVA="javac" make -C "$os_dir" test 2>&1

fi
