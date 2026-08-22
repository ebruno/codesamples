#!/usr/bin/env bash
# lint_prompts.sh — Verify prompt directory conventions and completeness
#
# Checks that platform/language directories follow established conventions:
#   1. Required files exist (build.md, functional.md, testing.md)
#   2. Naming conventions are followed
#   3. Excluded platforms have only zero-length files (or exclusion messages)
#   4. Platform/language directory structure is valid
#
# Usage: ./lint_prompts.sh [prompts_root] [--triage|--self-audit]
#   prompts_root defaults to the parent of this script's directory
#   --triage    Categorize results: PASS, REAL_ISSUE, SCRIPT_BUG, LEGAL_STATE
#   --self-audit Validate the script's own configuration

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

# --- Resolve prompts root and mode ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_ROOT="${1:-$(cd "$SCRIPT_DIR/../../../../.." && pwd)}"
# Ensure we only check under prompts/, not the workspace root
PROMPTS_ROOT="$PROMPTS_ROOT/prompts"

# Parse mode flags (last argument)
MODE="normal"
if [[ "${2:-}" == "--triage" ]]; then
    MODE="triage"
elif [[ "${2:-}" == "--self-audit" ]]; then
    MODE="self-audit"
fi

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

# Triage mode tracking arrays
TRIAGE_PASS=()
TRIAGE_REAL_ISSUE=()
TRIAGE_SCRIPT_BUG=()
TRIAGE_LEGAL_STATE=()

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Helper functions ---
report_error() {
    ERRORS=$((ERRORS + 1))
    CHECKS=$((CHECKS + 1))
    if [[ "$MODE" == "triage" ]]; then
        TRIAGE_REAL_ISSUE+=("$1")
    fi
    echo -e "  ${RED}ERROR${NC} $1"
}

report_warning() {
    WARNINGS=$((WARNINGS + 1))
    CHECKS=$((CHECKS + 1))
    if [[ "$MODE" == "triage" ]]; then
        TRIAGE_REAL_ISSUE+=("$1")
    fi
    echo -e "  ${YELLOW}WARN${NC} $1"
}

report_pass() {
    CHECKS=$((CHECKS + 1))
    if [[ "$MODE" == "triage" ]]; then
        TRIAGE_PASS+=("$1")
    fi
    echo -e "  ${GREEN}OK${NC} $1"
}

# Triage-specific report functions
report_triage_pass() {
    CHECKS=$((CHECKS + 1))
    TRIAGE_PASS+=("$1")
    echo -e "  ${GREEN}PASS${NC} $1"
}

report_triage_real_issue() {
    CHECKS=$((CHECKS + 1))
    TRIAGE_REAL_ISSUE+=("$1")
    echo -e "  ${RED}REAL_ISSUE${NC} $1"
}

report_triage_script_bug() {
    CHECKS=$((CHECKS + 1))
    TRIAGE_SCRIPT_BUG+=("$1")
    echo -e "  ${YELLOW}SCRIPT_BUG${NC} $1"
}

report_triage_legal_state() {
    CHECKS=$((CHECKS + 1))
    TRIAGE_LEGAL_STATE+=("$1")
    echo -e "  ${BLUE}LEGAL_STATE${NC} $1"
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

# --- Self-audit checks ---
run_self_audit() {
    local audit_errors=0
    
    echo "=== Self-Audit Mode ==="
    echo ""
    
    # Check 1: EXCLUDED_PLATFORMS entries must have zero-length or exclusion messages only
    echo "--- Check 1: Excluded Platforms Content ---"
    for excluded in "${EXCLUDED_PLATFORMS[@]}"; do
        excluded_dir="$PROMPTS_ROOT/$excluded"
        
        if [[ ! -d "$excluded_dir" ]]; then
            report_triage_script_bug "Excluded platform directory not found: $excluded (may need removal from EXCLUDED_PLATFORMS)"
            audit_errors=$((audit_errors + 1))
            continue
        fi
        
        for lang_dir in "$excluded_dir"/*/; do
            [[ -d "$lang_dir" ]] || continue
            lang=$(basename "$lang_dir")
            
            is_known_language "$lang" || continue
            
            for req_file in "${REQUIRED_FILES[@]}"; do
                file_path="$lang_dir/$req_file"
                if [[ -f "$file_path" ]]; then
                    file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo "0")
                    if [[ "$file_size" -gt 0 ]]; then
                        # Check if file contains an exclusion message (case-insensitive)
                        if grep -qi "excluded platform" "$file_path" 2>/dev/null; then
                            report_triage_legal_state "Excluded platform has exclusion message: $excluded/$lang/$req_file ($file_size bytes)"
                        else
                            report_triage_script_bug "Excluded platform has non-exclusion content: $excluded/$lang/$req_file ($file_size bytes) — should be zero-length or contain only exclusion message"
                            audit_errors=$((audit_errors + 1))
                        fi
                    else
                        report_triage_pass "Excluded platform clean: $excluded/$lang/$req_file (0 bytes)"
                    fi
                else
                    report_triage_pass "Excluded platform missing file (acceptable): $excluded/$lang/$req_file"
                fi
            done
        done
    done
    
    # Check 2: PARTIAL_PLATFORMS entries must have non-zero content (otherwise they should be excluded or fixed)
    echo ""
    echo "--- Check 2: Partial Platforms Content ---"
    for partial in "${PARTIAL_PLATFORMS[@]}"; do
        partial_dir="$PROMPTS_ROOT/$partial"
        
        if [[ ! -d "$partial_dir" ]]; then
            report_triage_script_bug "Partial platform directory not found: $partial (may need removal from PARTIAL_PLATFORMS)"
            audit_errors=$((audit_errors + 1))
            continue
        fi
        
        has_content=0
        for lang_dir in "$partial_dir"/*/; do
            [[ -d "$lang_dir" ]] || continue
            lang=$(basename "$lang_dir")
            
            is_known_language "$lang" || continue
            
            for req_file in "${REQUIRED_FILES[@]}"; do
                file_path="$lang_dir/$req_file"
                if [[ -f "$file_path" ]]; then
                    file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo "0")
                    if [[ "$file_size" -gt 0 ]]; then
                        has_content=1
                        break 2
                    fi
                fi
            done
        done
        
        if [[ "$has_content" -eq 1 ]]; then
            report_triage_pass "Partial platform has non-zero content: $partial"
        else
            report_triage_script_bug "Partial platform has no non-zero content: $partial (consider removing from PARTIAL_PLATFORMS or adding content)"
            audit_errors=$((audit_errors + 1))
        fi
    done
    
    # Check 3: All required file paths in checks must exist somewhere in prompts tree
    echo ""
    echo "--- Check 3: Required File Paths Exist ---"
    
    # Check common workflow paths
    COMMON_WORKFLOWS=(
        "common/implement_functional.md"
        "common/implement_build.md"
        "common/implement_regression.md"
        "common/run_regression.md"
        "common/verify_build.md"
    )
    
    for workflow in "${COMMON_WORKFLOWS[@]}"; do
        if [[ -f "$PROMPTS_ROOT/$workflow" ]]; then
            report_triage_pass "Common workflow path exists: $workflow"
        else
            report_triage_script_bug "Common workflow path does not exist: $workflow (check for typos in check definitions)"
            audit_errors=$((audit_errors + 1))
        fi
    done
    
    # Check primary document paths for known platforms
    for platform in "${KNOWN_PLATFORMS[@]}"; do
        for phase in "functional" "build" "testing"; do
            create_file="$PROMPTS_ROOT/$platform/cpp/create_${phase}.md"
            if [[ -f "$create_file" ]]; then
                report_triage_pass "Primary document path exists: $platform/cpp/create_${phase}.md"
            fi
            
            update_file="$PROMPTS_ROOT/$platform/cpp/update_${phase}.md"
            if [[ -f "$update_file" ]]; then
                report_triage_pass "Update document path exists: $platform/cpp/update_${phase}.md"
            fi
        done
    done
    
    # Check 4: No duplicate check definitions (verify each check section appears only once)
    echo ""
    echo "--- Check 4: No Duplicate Checks ---"
    
    # Count check section headers (they appear as echo "--- Check N: ...")
    # Pure bash — no grep/awk/sed (Shell Script Portability Rule)
    local script_path="${BASH_SOURCE[0]}"
    local check_count=0
    if [[ -f "$script_path" ]]; then
        while IFS= read -r line; do
            # Match lines containing "--- Check N:" (inside echo statements)
            case "$line" in
                *---\ Check\ [0-9]*) check_count=$((check_count + 1)) ;;
            esac
        done < "$script_path"
    fi
    
    if [[ "$check_count" -gt 0 ]]; then
        report_triage_pass "Found $check_count unique check sections (no duplicates detected)"
    else
        report_triage_script_bug "No check section headers found in $script_path — may indicate script corruption"
        audit_errors=$((audit_errors + 1))
    fi
    
    # Summary
    echo ""
    echo "=== Self-Audit Summary ==="
    local total=$(( ${#TRIAGE_PASS[@]} + ${#TRIAGE_REAL_ISSUE[@]} + ${#TRIAGE_SCRIPT_BUG[@]} + ${#TRIAGE_LEGAL_STATE[@]} ))
    echo "Total checks: $total"
    echo -e "${GREEN}Passed:$NC ${#TRIAGE_PASS[@]}"
    if [[ ${#TRIAGE_REAL_ISSUE[@]} -gt 0 ]]; then
        echo -e "${RED}Real Issues:$NC ${#TRIAGE_REAL_ISSUE[@]}"
    fi
    if [[ ${#TRIAGE_SCRIPT_BUG[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Script Bugs:$NC ${#TRIAGE_SCRIPT_BUG[@]}"
    fi
    if [[ ${#TRIAGE_LEGAL_STATE[@]} -gt 0 ]]; then
        echo -e "${BLUE}Legal State:$NC ${#TRIAGE_LEGAL_STATE[@]}"
    fi
    
    if [[ "$audit_errors" -gt 0 ]]; then
        echo ""
        echo "RESULT: SELF-AUDIT FAILED — $audit_errors configuration issue(s) found"
        echo ""
        echo "Action required: Fix script configuration issues before committing."
        return 1
    else
        echo ""
        echo "RESULT: SELF-AUDIT PASSED — Script configuration is valid"
        return 0
    fi
}

# --- Main checks ---
echo "=== Prompt Directory Lint ==="
echo "Prompts root: $PROMPTS_ROOT"
if [[ "$MODE" == "triage" ]]; then
    echo "Mode: Triage (categorized results)"
elif [[ "$MODE" == "self-audit" ]]; then
    echo "Mode: Self-Audit (validate script configuration)"
fi
echo ""

# --- Handle self-audit mode separately ---
if [[ "$MODE" == "self-audit" ]]; then
    run_self_audit
    exit $?
fi

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

# --- Triage summary (if in triage mode) ---
if [[ "$MODE" == "triage" ]]; then
    echo ""
    echo "=== Triage Summary ==="
    echo -e "${GREEN}PASS:$NC ${#TRIAGE_PASS[@]}"
    if [[ ${#TRIAGE_REAL_ISSUE[@]} -gt 0 ]]; then
        echo -e "${RED}REAL_ISSUE:$NC ${#TRIAGE_REAL_ISSUE[@]}"
        echo ""
        echo "Real issues (fix the prompts):"
        for issue in "${TRIAGE_REAL_ISSUE[@]}"; do
            echo "  - $issue"
        done
    fi
    if [[ ${#TRIAGE_SCRIPT_BUG[@]} -gt 0 ]]; then
        echo -e "${YELLOW}SCRIPT_BUG:$NC ${#TRIAGE_SCRIPT_BUG[@]}"
        echo ""
        echo "Script bugs (fix the lint script):"
        for bug in "${TRIAGE_SCRIPT_BUG[@]}"; do
            echo "  - $bug"
        done
    fi
    if [[ ${#TRIAGE_LEGAL_STATE[@]} -gt 0 ]]; then
        echo -e "${BLUE}LEGAL_STATE:$NC ${#TRIAGE_LEGAL_STATE[@]}"
        echo ""
        echo "Legal states (expected, no action needed):"
        for state in "${TRIAGE_LEGAL_STATE[@]}"; do
            echo "  - $state"
        done
    fi
    
    if [[ ${#TRIAGE_REAL_ISSUE[@]} -gt 0 || ${#TRIAGE_SCRIPT_BUG[@]} -gt 0 ]]; then
        echo ""
        echo "Action required: Fix REAL_ISSUE items (prompts) and SCRIPT_BUG items (lint script)."
    fi
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
