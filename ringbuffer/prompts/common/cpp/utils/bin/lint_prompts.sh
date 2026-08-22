#!/usr/bin/env bash
# lint_prompts.sh — Verify prompt directory conventions and completeness
#
# Checks that platform/language directories follow established conventions:
#   1. Required files exist (build.md, functional.md, testing.md)
#   2. Naming conventions are followed
#   3. Excluded platforms have only zero-length files
#   4. Platform/language directory structure is valid
#
# Usage: ./lint_prompts.sh [prompts_root]
#   prompts_root defaults to the parent of this script's directory

set -euo pipefail

# --- Version check (bash builtins only, no head/sed/sort) ---
REQUIRED_VERSION="5.0"
CURRENT_VERSION="${BASH_VERSION%%(*}"  # Strip everything from '(' onwards (e.g., "5.0.18")
CURRENT_VERSION="${CURRENT_VERSION##*version }"  # Remove 'version ' prefix if present
IFS='.' read -r req_major req_minor <<< "$REQUIRED_VERSION"
IFS='.' read -r cur_major cur_minor _ <<< "$CURRENT_VERSION"
if (( cur_major < req_major || (cur_major == req_major && cur_minor < req_minor) )); then
    echo "ERROR: Bash $REQUIRED_VERSION or higher required (found $CURRENT_VERSION)" >&2
    exit 1
fi

# --- Resolve prompts root ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_ROOT="${1:-$(cd "$SCRIPT_DIR/../../../../.." && pwd)}"
# Ensure we only check under prompts/, not the workspace root
PROMPTS_ROOT="$PROMPTS_ROOT/prompts"

# --- Configuration ---
REQUIRED_FILES=("build.md" "functional.md" "testing.md")

# Excluded platforms — must have only zero-length required files
# Note: freebsd14 and archlinux are active (have implementations), only freebsd15 is excluded
EXCLUDED_PLATFORMS=("freebsd15")

# All known platforms (from src/ and prompts/)
KNOWN_PLATFORMS=("macos" "debian" "fedora" "ubuntu")

# All known languages
KNOWN_LANGUAGES=("c" "cpp" "go" "java" "python" "rust")

# Directories to skip (not platform directories)
SKIP_DIRS=("common" "configs")

# Platforms that don't require all three required files (special-purpose directories)
PARTIAL_PLATFORMS=("freebsd" "reference_linux")

# --- Counters ---
ERRORS=0
WARNINGS=0
CHECKS=0

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Helper functions ---
report_error() {
    ERRORS=$((ERRORS + 1))
    CHECKS=$((CHECKS + 1))
    echo -e "  ${RED}ERROR${NC} $1"
}

report_warning() {
    WARNINGS=$((WARNINGS + 1))
    CHECKS=$((CHECKS + 1))
    echo -e "  ${YELLOW}WARN${NC} $1"
}

report_pass() {
    CHECKS=$((CHECKS + 1))
    echo -e "  ${GREEN}OK${NC} $1"
}

# Check if a directory name should be skipped
is_skip_dir() {
    local dir="$1"
    for skip in "${SKIP_DIRS[@]}"; do
        [[ "$dir" == "$skip" ]] && return 0
    done
    return 1
}

# Check if a directory name is a known language
is_known_language() {
    local lang="$1"
    for known in "${KNOWN_LANGUAGES[@]}"; do
        [[ "$lang" == "$known" ]] && return 0
    done
    return 1
}

# Check if a platform is a partial platform (doesn't require all three files)
is_partial_platform() {
    local plat="$1"
    for partial in "${PARTIAL_PLATFORMS[@]}"; do
        [[ "$plat" == "$partial" ]] && return 0
    done
    return 1
}

# --- Main checks ---
echo "=== Prompt Directory Lint ==="
echo "Prompts root: $PROMPTS_ROOT"
echo ""

# --- Check 1: Platform/language directory structure ---
echo "--- Check 1: Directory Structure ---"

for platform_dir in "$PROMPTS_ROOT"/*/; do
    [[ -d "$platform_dir" ]] || continue
    platform=$(basename "$platform_dir")

    # Skip non-platform directories
    is_skip_dir "$platform" && continue

    for lang_dir in "$platform_dir"/*/; do
        [[ -d "$lang_dir" ]] || continue
        lang=$(basename "$lang_dir")

        # Only check known language directories (skip utils/bin, etc.)
        is_known_language "$lang" || continue

        # Check that the language is known (already guaranteed by is_known_language)
        report_pass "Valid platform/language: $platform/$lang"
    done
done

report_pass "Directory structure validated"

# --- Check 2: Required files exist ---
echo ""
echo "--- Check 2: Required Files ---"

for platform_dir in "$PROMPTS_ROOT"/*/; do
    [[ -d "$platform_dir" ]] || continue
    platform=$(basename "$platform_dir")

    # Skip non-platform directories
    is_skip_dir "$platform" && continue

    # Skip partial platforms (special-purpose directories that don't need all files)
    is_partial_platform "$platform" && continue

    for lang_dir in "$platform_dir"/*/; do
        [[ -d "$lang_dir" ]] || continue
        lang=$(basename "$lang_dir")

        # Only check known language directories
        is_known_language "$lang" || continue

        for req_file in "${REQUIRED_FILES[@]}"; do
            file_path="$lang_dir/$req_file"
            if [[ ! -f "$file_path" ]]; then
                report_error "Missing required file: $platform/$lang/$req_file"
            fi
        done
    done
done

report_pass "Required files check complete"

# --- Check 3: Excluded platforms have only zero-length files ---
echo ""
echo "--- Check 3: Excluded Platforms ---"

for excluded in "${EXCLUDED_PLATFORMS[@]}"; do
    excluded_dir="$PROMPTS_ROOT/$excluded"

    if [[ ! -d "$excluded_dir" ]]; then
        report_warning "Excluded platform directory not found: $excluded"
        continue
    fi

    for lang_dir in "$excluded_dir"/*/; do
        [[ -d "$lang_dir" ]] || continue
        lang=$(basename "$lang_dir")

        # Only check known language directories
        is_known_language "$lang" || continue

        for req_file in "${REQUIRED_FILES[@]}"; do
            file_path="$lang_dir/$req_file"
            if [[ -f "$file_path" ]]; then
                file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo "0")
                if [[ "$file_size" -gt 0 ]]; then
                    # Excluded platforms may contain exclusion messages (e.g., "Excluded platform — do not modify")
                    # This is the expected legal state per .bionic — no warning needed
                    report_pass "Excluded platform has exclusion message: $excluded/$lang/$req_file ($file_size bytes)"
                else
                    report_pass "Excluded platform clean: $excluded/$lang/$req_file (0 bytes)"
                fi
            else
                report_pass "Excluded platform missing file (acceptable): $excluded/$lang/$req_file"
            fi
        done
    done
done

report_pass "Excluded platforms check complete"

# --- Check 4: Naming conventions for primary documents ---
echo ""
echo "--- Check 4: Primary Document Naming ---"

for platform in "${KNOWN_PLATFORMS[@]}"; do
    for phase in "functional" "build" "testing"; do
        # Check for create_<phase>.md (primary document)
        create_file="$PROMPTS_ROOT/$platform/cpp/create_${phase}.md"
        if [[ -f "$create_file" ]]; then
            report_pass "Primary document exists: $platform/cpp/create_${phase}.md"
        fi

        # Check for update_<phase>.md (incremental update)
        update_file="$PROMPTS_ROOT/$platform/cpp/update_${phase}.md"
        if [[ -f "$update_file" ]]; then
            report_pass "Update document exists: $platform/cpp/update_${phase}.md"
        fi
    done
done

report_pass "Primary document naming check complete"

# --- Check 5: Common workflow files exist ---
echo ""
echo "--- Check 5: Common Workflow Files ---"

COMMON_WORKFLOWS=(
    "common/implement_functional.md"
    "common/implement_build.md"
    "common/implement_regression.md"
    "common/run_regression.md"
    "common/verify_build.md"
)

for workflow in "${COMMON_WORKFLOWS[@]}"; do
    if [[ -f "$PROMPTS_ROOT/$workflow" ]]; then
        report_pass "Common workflow exists: $workflow"
    else
        report_error "Missing common workflow: $workflow"
    fi
done

report_pass "Common workflow check complete"

# --- Summary ---
echo ""
echo "=== Lint Summary ==="
echo -e "Total checks: $CHECKS"
echo -e "${GREEN}Passed:$NC $((CHECKS - ERRORS - WARNINGS))"
if [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}Warnings:$NC $WARNINGS"
else
    echo "Warnings: 0"
fi
if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}Errors:$NC $ERRORS"
else
    echo "Errors: 0"
fi

if [[ $ERRORS -gt 0 ]]; then
    echo ""
    echo "RESULT: LINT FAILED — $ERRORS error(s) found"
    exit 1
else
    echo ""
    echo "RESULT: LINT PASSED"
    exit 0
fi
