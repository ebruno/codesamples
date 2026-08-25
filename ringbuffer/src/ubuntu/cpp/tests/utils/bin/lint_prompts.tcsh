#!/usr/bin/env tcsh
# lint_prompts.tcsh — Verify prompt directory conventions and completeness
# tcsh version for FreeBSD 14 (and macOS local testing)
#
# Checks that platform/language directories follow established conventions:
#   1. Required files exist (build.md, functional.md, testing.md)
#   2. Naming conventions are followed
#   3. Excluded platforms have only zero-length files (or exclusion messages)
#   4. Platform/language directory structure is valid
#
# Usage: ./lint_prompts.tcsh [prompts_root] [--triage|--self-audit]
#   prompts_root defaults to the parent of this script's directory
#   --triage    Categorize results: PASS, REAL_ISSUE, SCRIPT_BUG, LEGAL_STATE
#   --self-audit Validate the script's own configuration

# --- Resolve prompts root and mode ---
set SCRIPT_DIR = `dirname "$0"`
cd "$SCRIPT_DIR"
set SCRIPT_DIR = `pwd`

# Set prompts root (default: parent of utils/bin/ → workspace root)
if ($#argv >= 1) then
    set PROMPTS_ROOT = "$1/prompts"
else
    # Resolve relative path by cd'ing to parent and getting pwd
    set main_parent_dir = "$SCRIPT_DIR/../../../../prompts"
    if (-d "$main_parent_dir") then
        cd "$main_parent_dir"
        set PROMPTS_ROOT = `pwd`
    else
        set PROMPTS_ROOT = "$main_parent_dir"
    endif
endif

# Parse mode flags (last argument)
set MODE = "normal"
if ($#argv >= 2) then
    if ("$2" == "--triage") then
        set MODE = "triage"
    else if ("$2" == "--self-audit") then
        set MODE = "self-audit"
    endif
endif

# --- Configuration ---
set REQUIRED_FILES = (build.md functional.md testing.md)

# Excluded platforms — must have only zero-length required files
# Note: freebsd14 and archlinux are active (have implementations), only freebsd15 is excluded
set EXCLUDED_PLATFORMS = (freebsd15)

# All known platforms (from src/ and prompts/)
set KNOWN_PLATFORMS = (macos debian fedora ubuntu)

# All known languages
set KNOWN_LANGUAGES = (c cpp go java python rust)

# Directories to skip (not platform directories)
set SKIP_DIRS = (common configs)

# Platforms that don't require all three required files (special-purpose directories)
set PARTIAL_PLATFORMS = (freebsd reference_linux)

# --- Counters ---
set main_errors = 0
set main_warnings = 0
set main_checks = 0

# Triage mode tracking (tcsh has no arrays — use counter variables)
set triage_pass_count = 0
set triage_real_issue_count = 0
set triage_script_bug_count = 0
set triage_legal_state_count = 0

# Triage temp files for collecting items (tcsh has no arrays)
set triage_pass_file = "/tmp/lint_triage_pass_$$"
set triage_issue_file = "/tmp/lint_triage_issue_$$"
set triage_bug_file = "/tmp/lint_triage_bug_$$"
set triage_legal_file = "/tmp/lint_triage_legal_$$"

# Color output
set RED = "\033[0;31m"
set GREEN = "\033[0;32m"
set YELLOW = "\033[1;33m"
set BLUE = "\033[0;34m"
set NC = "\033[0m"

# --- Main checks ---
echo "=== Prompt Directory Lint ==="
echo "Prompts root: $PROMPTS_ROOT"
if ("$MODE" == "triage") then
    echo "Mode: Triage (categorized results)"
else if ("$MODE" == "self-audit") then
    echo "Mode: Self-Audit (validate script configuration)"
endif
echo ""

# --- Handle self-audit mode separately ---
if ("$MODE" == "self-audit") then
    goto self_audit_start
endif

# --- Check 1: Platform/language directory structure ---
echo "--- Check 1: Directory Structure ---"

foreach chk1_platform_dir ("$PROMPTS_ROOT"/*/)
    if (! -d "$chk1_platform_dir") continue
    set chk1_platform = `basename "$chk1_platform_dir"`

    # Skip non-platform directories
    set chk1_skip_result = 1
    foreach chk1_item ($SKIP_DIRS)
        if ("$chk1_platform" == "$chk1_item") then
            set chk1_skip_result = 0
        endif
    end
    if ($chk1_skip_result == 0) continue

    # Check for subdirectories before foreach (tcsh throws "No match" if none exist)
    set chk1_lang_dirs = `find "$chk1_platform_dir" -mindepth 1 -maxdepth 1 -type d`
    if ("$chk1_lang_dirs" == "") continue

    foreach chk1_lang_dir ($chk1_lang_dirs)
        if (! -d "$chk1_lang_dir") continue
        set chk1_lang = `basename "$chk1_lang_dir"`

        # Only check known language directories (skip utils/bin, etc.)
        set chk1_lang_result = 1
        foreach chk1_item ($KNOWN_LANGUAGES)
            if ("$chk1_lang" == "$chk1_item") then
                set chk1_lang_result = 0
            endif
        end
        if ($chk1_lang_result == 1) continue

        # Check that the language is known (already guaranteed by chk1_lang_result check)
        @ main_checks++
        if ("$MODE" == "triage") then
            @ triage_pass_count++
            echo "Valid platform/language: $chk1_platform/$chk1_lang" >> $triage_pass_file
        endif
        printf "  ${GREEN}OK${NC} Valid platform/language: $chk1_platform/$chk1_lang\n"
    end
end

@ main_checks++
if ("$MODE" == "triage") then
    @ triage_pass_count++
    echo "Directory structure validated" >> $triage_pass_file
endif
printf "  ${GREEN}OK${NC} Directory structure validated\n"

# --- Check 2: Required files exist ---
echo ""
echo "--- Check 2: Required Files ---"

foreach chk2_platform_dir ("$PROMPTS_ROOT"/*/)
    if (! -d "$chk2_platform_dir") continue
    set chk2_platform = `basename "$chk2_platform_dir"`

    # Skip non-platform directories
    set chk2_skip_result = 1
    foreach chk2_item ($SKIP_DIRS)
        if ("$chk2_platform" == "$chk2_item") then
            set chk2_skip_result = 0
        endif
    end
    if ($chk2_skip_result == 0) continue

    # Skip partial platforms (special-purpose directories that don't need all files)
    set chk2_partial_result = 1
    foreach chk2_item ($PARTIAL_PLATFORMS)
        if ("$chk2_platform" == "$chk2_item") then
            set chk2_partial_result = 0
        endif
    end
    if ($chk2_partial_result == 0) continue

    # Check for subdirectories before foreach
    set chk2_lang_dirs = `find "$chk2_platform_dir" -mindepth 1 -maxdepth 1 -type d`
    if ("$chk2_lang_dirs" == "") continue

    foreach chk2_lang_dir ($chk2_lang_dirs)
        if (! -d "$chk2_lang_dir") continue
        set chk2_lang = `basename "$chk2_lang_dir"`

        # Only check known language directories
        set chk2_lang_result = 1
        foreach chk2_item ($KNOWN_LANGUAGES)
            if ("$chk2_lang" == "$chk2_item") then
                set chk2_lang_result = 0
            endif
        end
        if ($chk2_lang_result == 1) continue

        foreach chk2_req_file ($REQUIRED_FILES)
            set chk2_file_path = "${chk2_lang_dir}/${chk2_req_file}"
            if (! -f "$chk2_file_path") then
                @ main_errors++
                @ main_checks++
                if ("$MODE" == "triage") then
                    @ triage_real_issue_count++
                    echo "Missing required file: $chk2_platform/$chk2_lang/$chk2_req_file" >> $triage_issue_file
                endif
                printf "  ${RED}ERROR${NC} Missing required file: $chk2_platform/$chk2_lang/$chk2_req_file\n"
            endif
        end
    end
end

@ main_checks++
if ("$MODE" == "triage") then
    @ triage_pass_count++
    echo "Required files check complete" >> $triage_pass_file
endif
printf "  ${GREEN}OK${NC} Required files check complete\n"

# --- Check 3: Excluded platforms have only zero-length files ---
echo ""
echo "--- Check 3: Excluded Platforms ---"

foreach chk3_excl_item ("$EXCLUDED_PLATFORMS")
    set chk3_excl_dir = "${PROMPTS_ROOT}/${chk3_excl_item}"

    if (! -d "$chk3_excl_dir") then
        @ main_warnings++
        @ main_checks++
        if ("$MODE" == "triage") then
            @ triage_real_issue_count++
            echo "Excluded platform directory not found: $chk3_excl_item" >> $triage_issue_file
        endif
        printf "  ${YELLOW}WARN${NC} Excluded platform directory not found: $chk3_excl_item\n"
        continue
    endif

    # Check for subdirectories before foreach
    set chk3_lang_dirs = `find "$chk3_excl_dir" -mindepth 1 -maxdepth 1 -type d`
    if ("$chk3_lang_dirs" == "") continue

    foreach chk3_lang_dir ($chk3_lang_dirs)
        if (! -d "$chk3_lang_dir") continue
        set chk3_lang = `basename "$chk3_lang_dir"`

        # Only check known language directories
        set chk3_lang_result = 1
        foreach chk3_item ($KNOWN_LANGUAGES)
            if ("$chk3_lang" == "$chk3_item") then
                set chk3_lang_result = 0
            endif
        end
        if ($chk3_lang_result == 1) continue

        foreach chk3_req_file ($REQUIRED_FILES)
            set chk3_file_path = "${chk3_lang_dir}/${chk3_req_file}"
            if (-f "$chk3_file_path") then
                set chk3_file_size = `stat -f%z "$chk3_file_path"`
                if ($chk3_file_size > 0) then
                    # Excluded platforms may contain exclusion messages (e.g., "Excluded platform — do not modify")
                    # This is the expected legal state per .bionic — no warning needed
                    @ main_checks++
                    if ("$MODE" == "triage") then
                        @ triage_pass_count++
                        echo "Excluded platform has exclusion message: $chk3_excl_item/$chk3_lang/$chk3_req_file ($chk3_file_size bytes)" >> $triage_pass_file
                    endif
                    printf "  ${GREEN}OK${NC} Excluded platform has exclusion message: $chk3_excl_item/$chk3_lang/$chk3_req_file ($chk3_file_size bytes)\n"
                else
                    @ main_checks++
                    if ("$MODE" == "triage") then
                        @ triage_pass_count++
                        echo "Excluded platform clean: $chk3_excl_item/$chk3_lang/$chk3_req_file (0 bytes)" >> $triage_pass_file
                    endif
                    printf "  ${GREEN}OK${NC} Excluded platform clean: $chk3_excl_item/$chk3_lang/$chk3_req_file (0 bytes)\n"
                endif
            else
                @ main_checks++
                if ("$MODE" == "triage") then
                    @ triage_pass_count++
                    echo "Excluded platform missing file (acceptable): $chk3_excl_item/$chk3_lang/$chk3_req_file" >> $triage_pass_file
                endif
                printf "  ${GREEN}OK${NC} Excluded platform missing file (acceptable): $chk3_excl_item/$chk3_lang/$chk3_req_file\n"
            endif
        end
    end
end

@ main_checks++
if ("$MODE" == "triage") then
    @ triage_pass_count++
    echo "Excluded platforms check complete" >> $triage_pass_file
endif
printf "  ${GREEN}OK${NC} Excluded platforms check complete\n"

# --- Check 4: Naming conventions for primary documents ---
echo ""
echo "--- Check 4: Primary Document Naming ---"

foreach chk4_plat_item ("$KNOWN_PLATFORMS")
    foreach chk4_phase ("functional" "build" "testing")
        # Check for create_<phase>.md (primary document)
        set chk4_create_file = "${PROMPTS_ROOT}/${chk4_plat_item}/cpp/create_${chk4_phase}.md"
        if (-f "$chk4_create_file") then
            @ main_checks++
            if ("$MODE" == "triage") then
                @ triage_pass_count++
                echo "Primary document exists: ${chk4_plat_item}/cpp/create_${chk4_phase}.md" >> $triage_pass_file
            endif
            printf "  ${GREEN}OK${NC} Primary document exists: ${chk4_plat_item}/cpp/create_${chk4_phase}.md\n"
        endif

        # Check for update_<phase>.md (incremental update)
        set chk4_update_file = "${PROMPTS_ROOT}/${chk4_plat_item}/cpp/update_${chk4_phase}.md"
        if (-f "$chk4_update_file") then
            @ main_checks++
            if ("$MODE" == "triage") then
                @ triage_pass_count++
                echo "Update document exists: ${chk4_plat_item}/cpp/update_${chk4_phase}.md" >> $triage_pass_file
            endif
            printf "  ${GREEN}OK${NC} Update document exists: ${chk4_plat_item}/cpp/update_${chk4_phase}.md\n"
        endif
    end
end

@ main_checks++
if ("$MODE" == "triage") then
    @ triage_pass_count++
    echo "Primary document naming check complete" >> $triage_pass_file
endif
printf "  ${GREEN}OK${NC} Primary document naming check complete\n"

# --- Check 5: Common workflow files exist ---
echo ""
echo "--- Check 5: Common Workflow Files ---"

foreach chk5_workflow ("common/implement_functional.md" "common/implement_build.md" \
                       "common/implement_regression.md" "common/run_regression.md" \
                       "common/verify_build.md")
    if (-f "${PROMPTS_ROOT}/${chk5_workflow}") then
        @ main_checks++
        if ("$MODE" == "triage") then
            @ triage_pass_count++
            echo "Common workflow exists: $chk5_workflow" >> $triage_pass_file
        endif
        printf "  ${GREEN}OK${NC} Common workflow exists: $chk5_workflow\n"
    else
        @ main_errors++
        @ main_checks++
        if ("$MODE" == "triage") then
            @ triage_real_issue_count++
            echo "Missing common workflow: $chk5_workflow" >> $triage_issue_file
        endif
        printf "  ${RED}ERROR${NC} Missing common workflow: $chk5_workflow\n"
    endif
end

@ main_checks++
if ("$MODE" == "triage") then
    @ triage_pass_count++
    echo "Common workflow check complete" >> $triage_pass_file
endif
printf "  ${GREEN}OK${NC} Common workflow check complete\n"

# --- Summary ---
echo ""
echo "=== Lint Summary ==="
printf "Total checks: %d\n" "$main_checks"
@ main_passed = $main_checks - $main_errors - $main_warnings
printf "${GREEN}Passed:${NC} %d\n" "$main_passed"
if ($main_warnings > 0) then
    printf "${YELLOW}Warnings:${NC} %d\n" "$main_warnings"
else
    echo "Warnings: 0"
endif
if ($main_errors > 0) then
    printf "${RED}Errors:${NC} %d\n" "$main_errors"
else
    echo "Errors: 0"
endif

# --- Triage summary (if in triage mode) ---
if ("$MODE" == "triage") then
    echo ""
    echo "=== Triage Summary ==="
    printf "${GREEN}PASS:${NC} %d\n" "$triage_pass_count"

    if ($triage_real_issue_count > 0) then
        printf "${RED}REAL_ISSUE:${NC} %d\n" "$triage_real_issue_count"
        echo ""
        echo "Real issues (fix the prompts):"
        while (1)
            set triage_issue_line = $<
            if ($status != 0) break
            echo "  - $triage_issue_line"
        end < $triage_issue_file
    endif

    if ($triage_script_bug_count > 0) then
        printf "${YELLOW}SCRIPT_BUG:${NC} %d\n" "$triage_script_bug_count"
        echo ""
        echo "Script bugs (fix the lint script):"
        while (1)
            set triage_bug_line = $<
            if ($status != 0) break
            echo "  - $triage_bug_line"
        end < $triage_bug_file
    endif

    if ($triage_legal_state_count > 0) then
        printf "${BLUE}LEGAL_STATE:${NC} %d\n" "$triage_legal_state_count"
        echo ""
        echo "Legal states (expected, no action needed):"
        while (1)
            set triage_legal_line = $<
            if ($status != 0) break
            echo "  - $triage_legal_line"
        end < $triage_legal_file
    endif

    if ($triage_real_issue_count > 0 || $triage_script_bug_count > 0) then
        echo ""
        echo "Action required: Fix REAL_ISSUE items (prompts) and SCRIPT_BUG items (lint script)."
    endif

    # Cleanup temp files
    rm -f $triage_pass_file $triage_issue_file $triage_bug_file $triage_legal_file
endif

if ($main_errors > 0) then
    echo ""
    echo "RESULT: LINT FAILED — $main_errors error(s) found"
    exit 1
else
    echo ""
    echo "RESULT: LINT PASSED"
    exit 0
endif

# --- Self-audit checks (separate block, only entered via goto) ---
self_audit_start:

set sa_audit_errors = 0

echo "=== Self-Audit Mode ==="
echo ""

# Check 1: EXCLUDED_PLATFORMS entries must have zero-length or exclusion messages only
echo "--- Check 1: Excluded Platforms Content ---"

foreach sa_excl_item ($EXCLUDED_PLATFORMS)
    set sa_excl_dir = "${PROMPTS_ROOT}/${sa_excl_item}"

    if (! -d "$sa_excl_dir") then
        @ main_checks++
        @ triage_script_bug_count++
        echo "Excluded platform directory not found: $sa_excl_item (may need removal from EXCLUDED_PLATFORMS)" >> $triage_bug_file
        printf "  ${YELLOW}SCRIPT_BUG${NC} Excluded platform directory not found: $sa_excl_item (may need removal from EXCLUDED_PLATFORMS)\n"
        set sa_audit_errors = 1
        continue
    endif

    # Check for subdirectories before foreach
    set sa_lang_dirs = `find "$sa_excl_dir" -mindepth 1 -maxdepth 1 -type d`
    if ("$sa_lang_dirs" == "") continue

    foreach sa_lang_dir ($sa_lang_dirs)
        if (! -d "$sa_lang_dir") continue
        set sa_lang = `basename "$sa_lang_dir"`

        # Only check known language directories
        set sa_lang_result = 1
        foreach sa_item ($KNOWN_LANGUAGES)
            if ("$sa_lang" == "$sa_item") then
                set sa_lang_result = 0
            endif
        end
        if ($sa_lang_result == 1) continue

        foreach sa_req_file ($REQUIRED_FILES)
            set sa_file_path = "${sa_lang_dir}/${sa_req_file}"
            if (-f "$sa_file_path") then
                set sa_file_size = `stat -f%z "$sa_file_path"`
                if ($sa_file_size > 0) then
                    # Check if file contains an exclusion message (case-insensitive)
                    # NOTE: Using grep -ci here because tcsh does not support 2>&1 redirect syntax
                    set sa_has_msg = `grep -ci "excluded platform" "$sa_file_path"`
                    if ($sa_has_msg > 0) then
                        @ main_checks++
                        @ triage_legal_state_count++
                        echo "Excluded platform has exclusion message: $sa_excl_item/$sa_lang/$sa_req_file ($sa_file_size bytes)" >> $triage_legal_file
                        printf "  ${BLUE}LEGAL_STATE${NC} Excluded platform has exclusion message: $sa_excl_item/$sa_lang/$sa_req_file ($sa_file_size bytes)\n"
                    else
                        @ main_checks++
                        @ triage_script_bug_count++
                        echo "Excluded platform has non-exclusion content: $sa_excl_item/$sa_lang/$sa_req_file ($sa_file_size bytes) — should be zero-length or contain only exclusion message" >> $triage_bug_file
                        printf "  ${YELLOW}SCRIPT_BUG${NC} Excluded platform has non-exclusion content: $sa_excl_item/$sa_lang/$sa_req_file ($sa_file_size bytes) — should be zero-length or contain only exclusion message\n"
                        set sa_audit_errors = 1
                    endif
                else
                    @ main_checks++
                    @ triage_pass_count++
                    echo "Excluded platform clean: $sa_excl_item/$sa_lang/$sa_req_file (0 bytes)" >> $triage_pass_file
                    printf "  ${GREEN}PASS${NC} Excluded platform clean: $sa_excl_item/$sa_lang/$sa_req_file (0 bytes)\n"
                endif
            else
                @ main_checks++
                @ triage_pass_count++
                echo "Excluded platform missing file (acceptable): $sa_excl_item/$sa_lang/$sa_req_file" >> $triage_pass_file
                printf "  ${GREEN}PASS${NC} Excluded platform missing file (acceptable): $sa_excl_item/$sa_lang/$sa_req_file\n"
            endif
        end
    end
end

# Check 2: PARTIAL_PLATFORMS entries must have non-zero content (otherwise they should be excluded or fixed)
echo ""
echo "--- Check 2: Partial Platforms Content ---"

foreach sa_partial_item ($PARTIAL_PLATFORMS)
    set sa_partial_dir = "${PROMPTS_ROOT}/${sa_partial_item}"

    if (! -d "$sa_partial_dir") then
        @ main_checks++
        @ triage_script_bug_count++
        echo "Partial platform directory not found: $sa_partial_item (may need removal from PARTIAL_PLATFORMS)" >> $triage_bug_file
        printf "  ${YELLOW}SCRIPT_BUG${NC} Partial platform directory not found: $sa_partial_item (may need removal from PARTIAL_PLATFORMS)\n"
        set sa_audit_errors = 1
        continue
    endif

    set sa_has_content = 0
    # Check for subdirectories before foreach
    set sa_lang_dirs = `find "$sa_partial_dir" -mindepth 1 -maxdepth 1 -type d`
    if ("$sa_lang_dirs" == "") continue

    foreach sa_lang_dir ($sa_lang_dirs)
        if (! -d "$sa_lang_dir") continue
        set sa_lang = `basename "$sa_lang_dir"`

        # Only check known language directories
        set sa_lang_result = 1
        foreach sa_item ($KNOWN_LANGUAGES)
            if ("$sa_lang" == "$sa_item") then
                set sa_lang_result = 0
            endif
        end
        if ($sa_lang_result == 1) continue

        foreach sa_req_file ($REQUIRED_FILES)
            set sa_file_path = "${sa_lang_dir}/${sa_req_file}"
            if (-f "$sa_file_path") then
                set sa_file_size = `stat -f%z "$sa_file_path"`
                if ($sa_file_size > 0) then
                    set sa_has_content = 1
                    break
                endif
            endif
        end
    end

    if ($sa_has_content == 1) then
        @ main_checks++
        @ triage_pass_count++
        echo "Partial platform has non-zero content: $sa_partial_item" >> $triage_pass_file
        printf "  ${GREEN}PASS${NC} Partial platform has non-zero content: $sa_partial_item\n"
    else
        @ main_checks++
        @ triage_script_bug_count++
        echo "Partial platform has no non-zero content: $sa_partial_item (consider removing from PARTIAL_PLATFORMS or adding content)" >> $triage_bug_file
        printf "  ${YELLOW}SCRIPT_BUG${NC} Partial platform has no non-zero content: $sa_partial_item (consider removing from PARTIAL_PLATFORMS or adding content)\n"
        set sa_audit_errors = 1
    endif
end

# Check 3: All required file paths in checks must exist somewhere in prompts tree
echo ""
echo "--- Check 3: Required File Paths Exist ---"

# Check common workflow paths
foreach sa_workflow ("common/implement_functional.md" "common/implement_build.md" \
                     "common/implement_regression.md" "common/run_regression.md" \
                     "common/verify_build.md")
    if (-f "${PROMPTS_ROOT}/${sa_workflow}") then
        @ main_checks++
        @ triage_pass_count++
        echo "Common workflow path exists: $sa_workflow" >> $triage_pass_file
        printf "  ${GREEN}PASS${NC} Common workflow path exists: $sa_workflow\n"
    else
        @ main_checks++
        @ triage_script_bug_count++
        echo "Common workflow path does not exist: $sa_workflow (check for typos in check definitions)" >> $triage_bug_file
        printf "  ${YELLOW}SCRIPT_BUG${NC} Common workflow path does not exist: $sa_workflow (check for typos in check definitions)\n"
        set sa_audit_errors = 1
    endif
end

# Check primary document paths for known platforms
foreach sa_plat_item ($KNOWN_PLATFORMS)
    foreach sa_phase ("functional" "build" "testing")
        set sa_create_file = "${PROMPTS_ROOT}/${sa_plat_item}/cpp/create_${sa_phase}.md"
        if (-f "$sa_create_file") then
            @ main_checks++
            @ triage_pass_count++
            echo "Primary document path exists: ${sa_plat_item}/cpp/create_${sa_phase}.md" >> $triage_pass_file
            printf "  ${GREEN}PASS${NC} Primary document path exists: ${sa_plat_item}/cpp/create_${sa_phase}.md\n"
        endif

        set sa_update_file = "${PROMPTS_ROOT}/${sa_plat_item}/cpp/update_${sa_phase}.md"
        if (-f "$sa_update_file") then
            @ main_checks++
            @ triage_pass_count++
            echo "Update document path exists: ${sa_plat_item}/cpp/update_${sa_phase}.md" >> $triage_pass_file
            printf "  ${GREEN}PASS${NC} Update document path exists: ${sa_plat_item}/cpp/update_${sa_phase}.md\n"
        endif
    end
end

# Check 4: No duplicate check definitions (verify each check section appears only once)
echo ""
echo "--- Check 4: No Duplicate Checks ---"

# Count check section headers (they appear as echo "--- Check N: ...")
# NOTE: Using grep here because tcsh has no native regex matching for file content scanning
set sa_script_path = "$0"
set sa_check_count = 0
if (-f "$sa_script_path") then
    # Use grep to count check section headers (match "--- Check N:" anywhere in line)
    # NOTE: grep -e required because pattern starts with --- which grep interprets as option
    set sa_check_count = `grep -c -e '--- Check [0-9]' "$sa_script_path"`
    if ($status != 0) set sa_check_count = 0
endif

if ($sa_check_count > 0) then
    @ main_checks++
    @ triage_pass_count++
    echo "Found $sa_check_count unique check sections (no duplicates detected)" >> $triage_pass_file
    printf "  ${GREEN}PASS${NC} Found $sa_check_count unique check sections (no duplicates detected)\n"
else
    @ main_checks++
    @ triage_script_bug_count++
    echo "No check section headers found in $sa_script_path — may indicate script corruption" >> $triage_bug_file
    printf "  ${YELLOW}SCRIPT_BUG${NC} No check section headers found in $sa_script_path — may indicate script corruption\n"
    set sa_audit_errors = 1
endif

# Summary
echo ""
echo "=== Self-Audit Summary ==="
@ sa_total = $triage_pass_count + $triage_real_issue_count + $triage_script_bug_count + $triage_legal_state_count
echo "Total checks: $sa_total"
printf "${GREEN}Passed:${NC} %d\n" "$triage_pass_count"
if ($triage_real_issue_count > 0) then
    printf "${RED}Real Issues:${NC} %d\n" "$triage_real_issue_count"
endif
if ($triage_script_bug_count > 0) then
    printf "${YELLOW}Script Bugs:${NC} %d\n" "$triage_script_bug_count"
endif
if ($triage_legal_state_count > 0) then
    printf "${BLUE}Legal State:${NC} %d\n" "$triage_legal_state_count"
endif

if ($sa_audit_errors > 0) then
    echo ""
    echo "RESULT: SELF-AUDIT FAILED — $sa_audit_errors configuration issue(s) found"
    echo ""
    echo "Action required: Fix script configuration issues before committing."

    # Cleanup temp files
    rm -f $triage_pass_file $triage_issue_file $triage_bug_file $triage_legal_file

    exit 1
else
    echo ""
    echo "RESULT: SELF-AUDIT PASSED — Script configuration is valid"

    # Cleanup temp files
    rm -f $triage_pass_file $triage_issue_file $triage_bug_file $triage_legal_file

    exit 0
endif
