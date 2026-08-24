#!/usr/bin/env zsh
# lint_scripts.zsh — Lint shell scripts for forbidden external tools
# Usage: ./lint_scripts.zsh <file> [file ...]
#   Scans specified .zsh and .sh files for forbidden external tools (awk, sed, grep, etc.)
#   Permitted tools: jq, date, cat, mkdir -p, rm -rf, cp, mv, chmod
#   Exit 0 = clean, Exit 1 = violations found

set -euo pipefail
setopt ksh_arrays GLOB_STAR_SHORT

# ── Host OS check (macOS required) ────────────────────────────────
BYPASS_OS_CHECK=false
while getopts ":N" opt; do
    case $opt in
        N) BYPASS_OS_CHECK=true ;;
        *) echo "ERROR: Unknown option -$OPTARG"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if [ "$BYPASS_OS_CHECK" = false ]; then
    local_host_os=$(uname -s)
    if [ "$local_host_os" != "Darwin" ]; then
        echo "ERROR: Running unsupported operating system ${local_host_os}; lint_scripts.zsh requires macOS."
        exit 1
    fi
fi

# ── Validate arguments ────────────────────────────────────────────
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file> [file ...]"
    echo "  Scans specified .zsh and .sh files for forbidden external tools."
    exit 1
fi

# Forbidden tools — any usage in .zsh/.sh scripts is a violation
FORBIDDEN=(awk sed grep cut tr sort uniq find xargs)

# Permitted external tools — these are OK
PERMITTED=(jq date cat mkdir rm cp mv chmod)

VIOLATIONS=()
FILES_SCANNED=0

# ── Check if a tool name appears as a command (not in comments/strings) ──
check_line_for_tool() {
    local line="$1" tool="$2"

    # Skip comment-only lines
    [[ "$line" =~ ^[[:space:]]*# ]] && return 1

    # Strip inline comments before checking
    local stripped="${line%%#*}"

    # Quick check: does the line contain the tool at all?
    if [[ "$stripped" != *"${tool}"* ]]; then
        return 1
    fi

    # Build a version of the line with pipes and semicolons replaced by spaces
    local normalized="${stripped//|/ }"
    normalized="${normalized//;/ }"

    # Now check if the tool appears as a standalone word (surrounded by spaces or at boundaries)
    # Prepend and append a space to handle start/end of line
    local padded=" ${normalized} "

    # Check for tool surrounded by spaces (standalone word)
    if [[ "$padded" == *" ${tool} "* ]]; then
        return 0
    fi

    # Tool is embedded in a larger word (e.g., fgrep contains grep) — not a violation
    return 1
}

# ── Scan a single file ──
scan_file() {
    local filepath="$1"
    local lineno=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        lineno=$((lineno + 1))

        for tool in "${FORBIDDEN[@]}"; do
            if check_line_for_tool "$line" "$tool"; then
                VIOLATIONS+=("${filepath}:${lineno}: forbidden tool '${tool}' found")
            fi
        done
    done < "$filepath"
}

# ── Main: scan specified files ────────────────────────────────────
echo "============================================="
echo "Shell Script Linter (zsh)"
echo "============================================="

for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        echo "WARNING: File not found: $file" >&2
        continue
    fi

    scan_file "$file"
    FILES_SCANNED=$((FILES_SCANNED + 1))
done

echo "Files scanned: $FILES_SCANNED"
echo ""

if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    echo "============================================="
    echo "VIOLATIONS FOUND: ${#VIOLATIONS[@]}"
    echo "============================================="
    for v in "${VIOLATIONS[@]}"; do
        echo "  $v"
    done
    exit 1
else
    echo "No violations found. All scripts are clean."
    exit 0
fi
