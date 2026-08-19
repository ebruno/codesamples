#!/usr/bin/env zsh
# lint_prompts.zsh — Verify prompt directory conventions (Zsh variant)

set -euo pipefail

# --- Version check (zsh builtins only, no sort/head) ---
REQUIRED_VERSION="5.8"
CURRENT_VERSION=${ZSH_VERSION%%.*}  # Major version
CURRENT_VERSION="${CURRENT_VERSION}.${ZSH_VERSION#*.}"  # Major.minor (strip patch)
CURRENT_VERSION="${CURRENT_VERSION%%(*}"  # Strip '(' if present
IFS='.' read -r req_major req_minor <<< "$REQUIRED_VERSION"
IFS='.' read -r cur_major cur_minor _ <<< "$CURRENT_VERSION"
if (( cur_major < req_major || (cur_major == req_major && cur_minor < req_minor) )); then
    echo "ERROR: Zsh $REQUIRED_VERSION or higher required (found ${ZSH_VERSION})" >&2
    exit 1
fi

# --- Resolve prompts root ---
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROMPTS_ROOT="${1:-$(cd "$SCRIPT_DIR/../../../../.." && pwd)}"

REQUIRED_FILES=(build.md functional.md testing.md)
EXCLUDED_PLATFORMS=(freebsd14 freebsd15 archlinux)
KNOWN_PLATFORMS=(macos debian fedora ubuntu)
KNOWN_LANGUAGES=(c cpp go java python rust)
SKIP_DIRS=(common configs)

ERRORS=0 WARNINGS=0 CHECKS=0

report_error() { ERRORS=$((ERRORS + 1)); CHECKS=$((CHECKS + 1)); echo "  ERROR $1"; }
report_warning() { WARNINGS=$((WARNINGS + 1)); CHECKS=$((CHECKS + 1)); echo "  WARN $1"; }
report_pass() { CHECKS=$((CHECKS + 1)); echo "  OK $1"; }

is_skip_dir() {
    local dir="$1"
    for skip in "${SKIP_DIRS[@]}"; do [[ "$dir" == "$skip" ]] && return 0; done
    return 1
}

is_known_language() {
    local lang="$1"
    for known in "${KNOWN_LANGUAGES[@]}"; do [[ "$lang" == "$known" ]] && return 0; done
    return 1
}

echo "=== Prompt Directory Lint ==="
echo "Prompts root: $PROMPTS_ROOT"
echo ""

# Check 1: Directory structure
echo "--- Check 1: Directory Structure ---"
for platform_dir in "$PROMPTS_ROOT"/*/; do
    [[ -d "$platform_dir" ]] || continue
    platform=$(basename "$platform_dir")
    is_skip_dir "$platform" && continue
    for lang_dir in "$platform_dir"/*/; do
        [[ -d "$lang_dir" ]] || continue
        lang=$(basename "$lang_dir")
        is_known_language "$lang" && report_pass "Valid: $platform/$lang"
    done
done
report_pass "Directory structure validated"

# Check 2: Required files
echo ""
echo "--- Check 2: Required Files ---"
for platform_dir in "$PROMPTS_ROOT"/*/; do
    [[ -d "$platform_dir" ]] || continue
    platform=$(basename "$platform_dir")
    is_skip_dir "$platform" && continue
    for lang_dir in "$platform_dir"/*/; do
        [[ -d "$lang_dir" ]] || continue
        lang=$(basename "$lang_dir")
        is_known_language "$lang" || continue
        for req_file in "${REQUIRED_FILES[@]}"; do
            [[ ! -f "$lang_dir/$req_file" ]] && report_error "Missing: $platform/$lang/$req_file"
        done
    done
done
report_pass "Required files check complete"

# Check 3: Excluded platforms
echo ""
echo "--- Check 3: Excluded Platforms ---"
for excluded in "${EXCLUDED_PLATFORMS[@]}"; do
    [[ -d "$PROMPTS_ROOT/$excluded" ]] || { report_warning "Not found: $excluded"; continue; }
    for lang_dir in "$PROMPTS_ROOT/$excluded"/*/; do
        [[ -d "$lang_dir" ]] || continue
        lang=$(basename "$lang_dir")
        is_known_language "$lang" || continue
        for req_file in "${REQUIRED_FILES[@]}"; do
            file_path="$lang_dir/$req_file"
            if [[ -f "$file_path" ]]; then
                file_size=$(stat -f%z "$file_path" 2>/dev/null || echo "0")
                [[ "$file_size" -gt 0 ]] && report_error "Non-zero: $excluded/$lang/$req_file" || report_pass "Clean: $excluded/$lang/$req_file (0 bytes)"
            else
                report_error "Missing: $excluded/$lang/$req_file"
            fi
        done
    done
done
report_pass "Excluded platforms check complete"

# Check 4: Primary documents
echo ""
echo "--- Check 4: Primary Document Naming ---"
for platform in "${KNOWN_PLATFORMS[@]}"; do
    for phase in functional build testing; do
        [[ -f "$PROMPTS_ROOT/$platform/cpp/create_${phase}.md" ]] && report_pass "create_${phase}.md for $platform"
        [[ -f "$PROMPTS_ROOT/$platform/cpp/update_${phase}.md" ]] && report_pass "update_${phase}.md for $platform"
    done
done
report_pass "Primary document naming check complete"

# Check 5: Common workflows
echo ""
echo "--- Check 5: Common Workflow Files ---"
for workflow in prompts/common/implement_functional.md prompts/common/implement_build.md prompts/common/implement_regression.md prompts/common/run_regression.md prompts/common/verify_build.md; do
    [[ -f "$PROMPTS_ROOT/$workflow" ]] && report_pass "Exists: $workflow" || report_error "Missing: $workflow"
done
report_pass "Common workflow check complete"

# Summary
echo ""
echo "=== Lint Summary ==="
echo "Total checks: $CHECKS"
echo "Passed: $((CHECKS - ERRORS - WARNINGS))"
echo "Warnings: $WARNINGS"
echo "Errors: $ERRORS"

if [[ $ERRORS -gt 0 ]]; then
    echo ""
    echo "RESULT: LINT FAILED — $ERRORS error(s) found"
    exit 1
else
    echo ""
    echo "RESULT: LINT PASSED"
    exit 0
fi
