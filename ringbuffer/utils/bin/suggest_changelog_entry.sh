#!/usr/bin/env bash
# Ringbuffer — Suggest CHANGELOG entry from git diff analysis
# 
# Usage: suggest_changelog_entry.sh [COMMIT_HASH]
#   If COMMIT_HASH is omitted, uses HEAD.
#   Analyzes changes to prompts/ (scoped by PROJECT_PREFIX) and outputs a suggested CHANGELOG entry.
#   Prompts the user to apply, edit, or skip.

set -euo pipefail

COMMIT="${1:-HEAD}"
WORKDIR="$(cd "$(dirname "$0")/../.." && pwd)"
# If ringbuffer is moved to its own standalone repo, change this to "":
PROJECT_PREFIX="ringbuffer/"
CHANGELOG="$WORKDIR/${PROJECT_PREFIX}prompts/common/CHANGELOG.md"

# ── Helper: check if any prompt files changed in this commit ──────────────
changed_prompt_files() {
    # Bash builtins only — no grep
    git diff-tree --no-commit-id --name-only -r "$COMMIT" 2>/dev/null | while IFS= read -r f; do
        [[ "$f" == "${PROJECT_PREFIX}prompts/"* ]] && echo "$f"
    done || true
}

# ── Helper: extract changed markdown sections from diff context lines (bash builtins only) ─────
changed_sections() {
    # Collect unique changed section headers from diff
    local _sections=""
    declare -A _seen_sections
    while IFS= read -r line; do
        # Match lines starting with '+ #' (added markdown headers in diff)
        if [[ "$line" =~ ^\+\ *# ]]; then
            # Extract the header text after '+ #' or '+ ##' etc.
            local _header="${line#\+ }"
            _header="${_header###+}"
            _header="${_header#\# }"
            _header="${_header%% *}"  # Get just the section name
            if [[ -n "$_header" ]] && [[ -z "${_seen_sections[$_header]:-}" ]]; then
                _seen_sections["$_header"]=1
                _sections="${_sections}${_sections:+\n}  - ${_header}"
            fi
        fi
    done < <(git diff-tree -p --no-commit-id -r "$COMMIT" 2>/dev/null || true)
    echo "$_sections"
}

# ── Helper: count additions/deletions per file (bash builtins only) ───────────────────────────
file_diff_stats() {
    local file="$1"
    local additions=0 deletions=0
    while IFS= read -r line; do
        if [[ "$line" == +* ]] && [[ "$line" == *"${file}"* ]]; then
            (( additions++ )) || true
        elif [[ "$line" == -* ]] && [[ "$line" == *"${file}"* ]]; then
            (( deletions++ )) || true
        fi
    done < <(git diff-tree -p --no-commit-id -r "$COMMIT" 2>/dev/null || true)
    echo "$additions $deletions"
}

# ── Helper: suggest rationale based on diff content patterns (bash builtins only) ──────────────
suggest_rationale() {
    local diff_text="$1"
    local rationale=""

    # Enable case-insensitive matching for bash regex
    shopt -s nocasematch

    # Pattern: container runtime / Dockerfile changes
    if [[ "$diff_text" =~ (FROM[[:space:]]|container.*runtime|podman|dockerfile|base\.image) ]]; then
        rationale="Updated container runtime configuration for reproducible builds"

    # Pattern: spec precedence rules
    elif [[ "$diff_text" =~ (spec.*precedence|platform.*specific.*override) ]]; then
        rationale="Clarified spec precedence to resolve platform-specific conflicts"

    # Pattern: new language specs
    elif [[ "$diff_text" =~ (functional\.md|build\.md) ]] && \
         [[ "$diff_text" =~ (python|java|go|rust|c23|c\+\+20) ]]; then
        rationale="Added language specification for multi-language implementation"

    # Pattern: test patterns or data generation
    elif [[ "$diff_text" =~ (pattern|test.*data|generate.*test|zigzag) ]]; then
        rationale="Extended test infrastructure with new pattern or data generation"

    # Pattern: slot state accessors / API changes
    elif [[ "$diff_text" =~ (get_.*buffer|set_.*status|accessor|slot.*state) ]]; then
        rationale="Updated library API surface for slot state visibility"

    # Pattern: version propagation
    elif [[ "$diff_text" =~ (version\.mk|version.*propagat) ]]; then
        rationale="Added version propagation from version.mk to target language"

    # Pattern: OS detection
    elif [[ "$diff_text" =~ (os-release|uname.*-s|sw_vers|host.*detect) ]]; then
        rationale="Enhanced OS detection for cross-platform compatibility"

    # Pattern: deduplication / session hints
    elif [[ "$diff_text" =~ (session_hints|dedupl|shared.*reference) ]]; then
        rationale="Refactored to reduce redundancy per deduplication discipline"

    # Pattern: develop-then-refactor strategy
    elif [[ "$diff_text" =~ (develop.*refactor|common.*codebase|platform\.insensitive) ]]; then
        rationale="Updated documentation for develop-then-refactor strategy"

    # Pattern: library API design
    elif [[ "$diff_text" =~ (library.*first|API.*design|intentional.*abstraction) ]]; then
        rationale="Clarified library-first API design intent for consumers"

    # Pattern: prompt versioning / changelog
    elif [[ "$diff_text" =~ (gen_state|changelog|prompt.*version) ]]; then
        rationale="Added prompt versioning and changelog tracking mechanism"

    # Pattern: large additions (>100 lines) to functional specs (bash builtins, no grep/awk)
    local _add_count=0
    while IFS= read -r line; do
        [[ "$line" == +* ]] && (( _add_count++ )) || true
    done <<< "$diff_text"
    if ((_add_count > 100)); then
        rationale="Expanded functional specification with new requirements"
    # Pattern: deletions across multiple files (bash builtins, no grep/awk)
    elif ((_add_count > 50)); then
        rationale="Refactored to reduce redundancy and improve maintainability"

    # Default: generic
    else
        rationale="Updated prompt specification — review for detailed rationale"
    fi

    echo "$rationale"
}

# ── Helper: build the changelog entry text (used for both display and write)
build_entry() {
    local commit_msg="$1"
    local file_list="$2"
    local sections="$3"
    local rationale="$4"

    echo "## [$(date +%Y-%m-%d)] $commit_msg"
    printf "%s\n" "$file_list"
    echo "- **Change**: $commit_msg"
    if [ -n "$sections" ]; then
        echo "- **Sections affected**:"
        echo "$sections" | while read -r line; do
            [ -n "$line" ] && echo "  - $line"
        done
    fi
    echo "- **Rationale**: \"$rationale\""
}

# ── Helper: apply entry to CHANGELOG.md (prepend after header) ───────────
apply_entry() {
    local entry="$1"

    # Ensure CHANGELOG.md exists
    if [ ! -f "$CHANGELOG" ]; then
        cat > "$CHANGELOG" << 'HEADER'
# Ringbuffer Prompt Changelog

> Entries are added by the post-commit hook suggestion workflow. See [CHANGELOG_TEMPLATE.md](CHANGELOG_TEMPLATE.md) for format instructions.

## Entries

<!-- Add entries in reverse chronological order (newest first) -->

---
HEADER
    fi

    # Read existing content, insert entry after the "---" separator line (bash builtins, no grep)
    local temp_file
    temp_file=$(mktemp)

    # Everything before the first "---" (header + entries section start)
    local found_separator=0
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        if [[ $found_separator -eq 0 ]] && [[ "$line" == "---" ]]; then
            found_separator=1
            echo "" >> "$temp_file"
            echo "$entry" >> "$temp_file"
        fi
    done < "$CHANGELOG"

    # Append any remaining content after the separator
    local past_separator=0
    while IFS= read -r line; do
        if [[ $past_separator -eq 0 ]] && [[ "$line" == "---" ]]; then
            past_separator=1
        elif [ $past_separator -eq 1 ]; then
            echo "$line" >> "$temp_file"
        fi
    done < "$CHANGELOG"

    mv "$temp_file" "$CHANGELOG"
}

# ── Helper: edit entry in $EDITOR, then return the result ────────────────
edit_entry() {
    local entry="$1"
    local temp_file
    temp_file=$(mktemp --suffix=.md)

    echo "$entry" > "$temp_file"
    local editor="${EDITOR:-vi}"
    "$editor" "$temp_file"

    cat "$temp_file"
    rm -f "$temp_file"
}

# ── Main ──────────────────────────────────────────────────────────────────

FILES=$(changed_prompt_files)
if [ -z "$FILES" ]; then
    exit 0  # No prompt changes, nothing to do
fi

# Get commit message (first line)
COMMIT_MSG=$(git log -1 --format="%s" "$COMMIT")

# Get full diff for analysis
DIFF_TEXT=$(git diff-tree -p --no-commit-id -r "$COMMIT" 2>/dev/null || true)

# Get changed sections
SECTIONS=$(changed_sections)

# Build file list with stats
FILE_LIST=""
for FILE in $FILES; do
    read -r ADDS DELS <<< "$(file_diff_stats "$FILE")"
    if [ "$ADDS" -gt 0 ] || [ "$DELS" -gt 0 ]; then
        FILE_LIST="${FILE_LIST}  ${FILE}: +${ADDS} -${DELS} lines\n"
    else
        FILE_LIST="${FILE_LIST}  ${FILE}\n"
    fi
done

# Get suggested rationale
RATIONALE=$(suggest_rationale "$DIFF_TEXT")

# Build the entry text
ENTRY=$(build_entry "$COMMIT_MSG" "$(echo -e "$FILE_LIST")" "$SECTIONS" "$RATIONALE")

# Display the suggestion
echo ""
echo "═══════════════════════════════════════════════"
echo "SUGGESTED CHANGELOG ENTRY:"
echo "═══════════════════════════════════════════════"
echo ""
echo "$ENTRY"
echo ""
echo "═══════════════════════════════════════════════"
echo ""

# Prompt the user
echo "Options:"
echo "  [a]pply   — Append to CHANGELOG.md as-is"
echo "  [e]dit    — Open in $EDITOR, then apply the edited version"
echo "  [s]kip    — Do nothing"
echo ""
printf "Choose (a/e/s): "

# Read user input (single character, no wait for Enter on some terminals)
read -r choice

case "$choice" in
    a|A)
        apply_entry "$ENTRY"
        echo "✅ Entry applied to $CHANGELOG"
        ;;
    e|E)
        EDITED=$(edit_entry "$ENTRY")
        while true; do
            echo ""
            echo "Editor closed. Options:"
            echo "  [a]pply   — Apply the (edited) entry to CHANGELOG.md"
            echo "  [e]dit    — Open editor again (make more changes)"
            echo "  [d]iscard — Do nothing, discard the entry"
            printf "Choose (a/e/d): "
            read -r choice2
            case "$choice2" in
                a|A)
                    apply_entry "$EDITED"
                    echo "✅ Edited entry applied to $CHANGELOG"
                    break
                    ;;
                e|E)
                    EDITED=$(edit_entry "$EDITED")
                    ;;
                *)
                    echo "⏭  Discarded — no changes made."
                    break
                    ;;
            esac
        done
        ;;
    *)
        echo "⏭  Skipped — no changes made."
        ;;
esac
