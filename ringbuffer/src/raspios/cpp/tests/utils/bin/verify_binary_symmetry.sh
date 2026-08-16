#!/usr/bin/env bash
# verify_binary_symmetry.sh — Verify binary symmetry across Linux platforms
#
# Compares .cpp and .hpp source files across all Linux platforms (debian, fedora, ubuntu)
# to ensure byte-identical output as required by the common specification.
#
# Usage: ./verify_binary_symmetry.sh [workspace_root]
#   workspace_root defaults to the ringbuffer project root (auto-detected)

set -euo pipefail

# --- Version check ---
REQUIRED_VERSION="5.0"
CURRENT_VERSION=$(bash --version | head -1 | sed -n 's/.*version \([0-9]*\.[0-9]*\).*/\1/p')
if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$CURRENT_VERSION" | sort -V | head -1)" != "$REQUIRED_VERSION" ]]; then
    echo "ERROR: Bash $REQUIRED_VERSION or higher required (found $CURRENT_VERSION)" >&2
    exit 1
fi

# --- Resolve workspace root ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-detect: walk up from script dir looking for src/ directory
WORKSPACE_ROOT="${1:-}"
if [[ -z "$WORKSPACE_ROOT" ]]; then
    _candidate="$SCRIPT_DIR"
    while [[ "$_candidate" != "/" && "$_candidate" != "." ]]; do
        if [[ -d "$_candidate/src" ]]; then
            WORKSPACE_ROOT="$_candidate"
            break
        fi
        _candidate="$(cd "$_candidate/.." && pwd)"
    done
    if [[ -z "$WORKSPACE_ROOT" ]]; then
        echo "ERROR: Could not auto-detect workspace root (no src/ directory found)" >&2
        exit 1
    fi
fi

# --- Configuration ---
# Linux platforms that should produce byte-identical source files
LINUX_PLATFORMS=("debian" "fedora" "ubuntu")

# Files to compare (relative to src/<os>/cpp/)
SOURCE_FILES=(
    "ringbuffer.hpp"
    "status.hpp"
    "swtr_ringbuffer_impl.hpp"
    "Accessors_ChecksumAlg.cpp"
    "Accessors_ChecksumVal.cpp"
    "Accessors_Size_Data.cpp"
    "Accessors_Size_Max.cpp"
    "Accessors_Size_Transformed.cpp"
    "Accessors_Status.cpp"
    "ErrorOps.cpp"
    "Lifecycle.cpp"
    "LoggingOps_1.cpp"
    "LoggingOps_2.cpp"
    "LoggingOps_3.cpp"
    "LoggingOps_4.cpp"
    "LoggingOps_5.cpp"
    "LoggingOps_6.cpp"
    "ReadOps.cpp"
    "Threading.cpp"
    "TransformOps.cpp"
    "WriteOps.cpp"
)

# --- Counters ---
TOTAL=0
PASS=0
FAIL=0
SKIPPED=0

# --- Color output (if terminal supports it) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Main verification loop ---
echo "=== Binary Symmetry Verification ==="
echo "Workspace: $WORKSPACE_ROOT"
echo "Platforms: ${LINUX_PLATFORMS[*]}"
echo ""

for src_file in "${SOURCE_FILES[@]}"; do
    TOTAL=$((TOTAL + 1))

    # Collect file paths for all platforms that have this file
    declare -a FILE_PATHS=()
    declare -a PLATFORM_NAMES=()

    for platform in "${LINUX_PLATFORMS[@]}"; do
        fpath="$WORKSPACE_ROOT/src/$platform/cpp/$src_file"
        if [[ -f "$fpath" ]]; then
            FILE_PATHS+=("$fpath")
            PLATFORM_NAMES+=("$platform")
        else
            SKIPPED=$((SKIPPED + 1))
        fi
    done

    # Need at least 2 platforms to compare
    if [[ ${#FILE_PATHS[@]} -lt 2 ]]; then
        echo "  [SKIP] $src_file — only ${#FILE_PATHS[@]} platform(s) have this file"
        continue
    fi

    # Compare all pairs against the first platform (reference)
    REF_PATH="${FILE_PATHS[0]}"
    REF_NAME="${PLATFORM_NAMES[0]}"
    DIFF_FOUND=0

    for i in $(seq 1 $(( ${#FILE_PATHS[@]} - 1 ))); do
        COMPARE_PATH="${FILE_PATHS[$i]}"
        COMPARE_NAME="${PLATFORM_NAMES[$i]}"

        if ! diff -q "$REF_PATH" "$COMPARE_PATH" >/dev/null 2>&1; then
            DIFF_FOUND=1
            echo -e "  ${RED}FAIL${NC} $src_file — differs between $REF_NAME and $COMPARE_NAME"
        fi
    done

    if [[ $DIFF_FOUND -eq 0 ]]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
    fi

    unset FILE_PATHS
    unset PLATFORM_NAMES
done

# --- Summary ---
echo ""
echo "=== Summary ==="
echo -e "Total files checked: $TOTAL"
echo -e "${GREEN}Passed (identical):$NC $PASS"
if [[ $FAIL -gt 0 ]]; then
    echo -e "${RED}Failed (differ):$NC $FAIL"
else
    echo "Failed (differ): 0"
fi
echo "Skipped: $SKIPPED"

if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "RESULT: SYMMETRY VIOLATION DETECTED"
    echo "Source files are NOT byte-identical across all Linux platforms."
    echo "Review the differences above and ensure the common specification is followed."
    exit 1
else
    echo ""
    echo "RESULT: SYMMETRY VERIFIED"
    echo "All compared source files are byte-identical across Linux platforms."
    exit 0
fi
