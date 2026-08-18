#!/usr/bin/env zsh
# verify_binary_symmetry.zsh — Verify binary symmetry across ALL platforms (Zsh variant)
#
# Compares .cpp and .hpp source files across all platforms (macOS, debian, fedora, ubuntu, raspios)
# to ensure byte-identical output as required by the common specification.
#
# Usage: ./verify_binary_symmetry.zsh [workspace_root]

set -euo pipefail

# --- Version check ---
REQUIRED_VERSION="5.8"
CURRENT_VERSION=${ZSH_VERSION}
if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$CURRENT_VERSION" | sort -V | head -1)" != "$REQUIRED_VERSION" ]]; then
    echo "ERROR: Zsh $REQUIRED_VERSION or higher required (found $CURRENT_VERSION)" >&2
    exit 1
fi

# --- Resolve workspace root ---
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
WORKSPACE_ROOT="${1:-$(cd "$SCRIPT_DIR/../../../../../../.." && pwd)}"

# --- Configuration ---
PLATFORMS=(macos debian fedora ubuntu raspios)

SOURCE_FILES=(
    ringbuffer.hpp status.hpp swtr_ringbuffer_impl.hpp
    Accessors_ChecksumAlg.cpp Accessors_ChecksumVal.cpp
    Accessors_Size_Data.cpp Accessors_Size_Max.cpp Accessors_Size_Transformed.cpp Accessors_Status.cpp
    ErrorOps.cpp Lifecycle.cpp
    LoggingOps_1.cpp LoggingOps_2.cpp LoggingOps_3.cpp LoggingOps_4.cpp LoggingOps_5.cpp LoggingOps_6.cpp
    ReadOps.cpp Threading.cpp TransformOps.cpp WriteOps.cpp
)

TOTAL=0 PASS=0 FAIL=0 SKIPPED=0

echo "=== Binary Symmetry Verification ==="
echo "Workspace: $WORKSPACE_ROOT"
echo "Platforms: ${(j/ /)PLATFORMS}"
echo ""

for src_file in "$SOURCE_FILES"; do
    TOTAL=$((TOTAL + 1))

    FILE_PATHS=()
    PLATFORM_NAMES=()

    for platform in "$PLATFORMS"; do
        fpath="$WORKSPACE_ROOT/src/$platform/cpp/$src_file"
        if [[ -f "$fpath" ]]; then
            FILE_PATHS+=("$fpath")
            PLATFORM_NAMES+=("$platform")
        else
            SKIPPED=$((SKIPPED + 1))
        fi
    done

    if [[ ${#FILE_PATHS[@]} -lt 2 ]]; then
        echo "  [SKIP] $src_file — only ${#FILE_PATHS[@]} platform(s) have this file"
        continue
    fi

    REF_PATH="${FILE_PATHS[1]}"
    REF_NAME="${PLATFORM_NAMES[1]}"
    DIFF_FOUND=0

    for i in $(seq 2 ${#FILE_PATHS[@]}); do
        COMPARE_PATH="${FILE_PATHS[$i]}"
        COMPARE_NAME="${PLATFORM_NAMES[$i]}"

        if ! diff -q "$REF_PATH" "$COMPARE_PATH" >/dev/null 2>&1; then
            DIFF_FOUND=1
            echo "  FAIL $src_file — differs between $REF_NAME and $COMPARE_NAME"
        fi
    done

    if [[ $DIFF_FOUND -eq 0 ]]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "=== Summary ==="
echo "Total files checked: $TOTAL"
echo "Passed (identical): $PASS"
echo "Failed (differ): $FAIL"
echo "Skipped: $SKIPPED"

if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "RESULT: SYMMETRY VIOLATION DETECTED"
    exit 1
else
    echo ""
    echo "RESULT: SYMMETRY VERIFIED"
    exit 0
fi
