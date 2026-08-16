#!/bin/bash
# Ringbuffer — Suggest CHANGELOG entry from git diff analysis
# 
# Usage: suggest_changelog_entry.sh [COMMIT_HASH]
#   If COMMIT_HASH is omitted, uses HEAD.
#   Analyzes changes to prompts/ and outputs a suggested CHANGELOG entry.
#   Prompts the user to apply, edit, or skip.

set -euo pipefail

COMMIT="${1:-HEAD}"
WORKDIR="$(cd "$(dirname "$0")/../.." && pwd)"
CHANGELOG="$WORKDIR/prompts/common/CHANGELOG.md"

# ── Helper: check if any prompt files changed in this commit ──────────────
changed_prompt_files() {
    git diff-tree --no-commit-id --name-only -r "$COMMIT" 2>/dev/null | \
        grep '^prompts/' || true
}

# ── Helper: extract changed markdown sections from diff context lines ─────
changed_sections() {
    git diff-tree -p --no-commit-id -r "$COMMIT" 2>/dev/null | \
        grep '^+ *#' | sed 's/^+ *\([#]*\) .*/\1/' | \
        awk '{print NR, $0}' | sort -t' ' -k2 -rn | \
        awk '!seen[$0]++ {print $2}' | head -10 || true
}

# ── Helper: count additions/deletions per file ───────────────────────────
file_diff_stats() {
    local file="$1"
    local additions deletions
    additions=$(git diff-tree -p --no-commit-id -r "$COMMIT" 2>/dev/null | \
        grep "^+.*${file}" | wc -l | tr -d ' ')
    deletions=$(git diff-tree -p --no-commit-id -r "$COMMIT" 2>/dev/null | \
        grep "^-.*${file}" | wc -l | tr -d ' ')
    echo "$additions $deletions"
}

# ── Helper: suggest rationale based on diff content patterns ──────────────
suggest_rationale() {
    local diff_text="$1"
    local rationale=""

    # Pattern: container runtime / Dockerfile changes
    if echo "$diff_text" | grep -qiE '(FROM\s|container.*runtime|podman|dockerfile|base.image)'; then
        rationale="Updated container runtime configuration for reproducible builds"

    # Pattern: spec precedence rules
    elif echo "$diff_text" | grep -qiE '(spec.*precedence|platform.*specific.*override)'; then
        rationale="Clarified spec precedence to resolve platform-specific conflicts"

    # Pattern: new language specs
    elif echo "$diff_text" | grep -qiE '(functional\.md|build\.md)' && \
         echo "$diff_text" | grep -qiE '(python|java|go|rust|c23|c\+\+20)'; then
        rationale="Added language specification for multi-language implementation"

    # Pattern: test patterns or data generation
    elif echo "$diff_text" | grep -qiE '(pattern|test.*data|generate.*test|zigzag)'; then
        rationale="Extended test infrastructure with new pattern or data generation"

    # Pattern: slot state accessors / API changes
    elif echo "$diff_text" | grep -qiE '(get_.*buffer|set_.*status|accessor|slot.*state)'; then
        rationale="Updated library API surface for slot state visibility"

    # Pattern: version propagation
    elif echo "$diff_text" | grep -qiE '(version\.mk|version.*propagat)'; then
        rationale="Added version propagation from version.mk to target language"

    # Pattern: OS detection
    elif echo "$diff_text" | grep -qiE '(os-release|uname.*-s|sw_vers|host.*detect)'; then
        rationale="Enhanced OS detection for cross-platform compatibility"

    # Pattern: deduplication / session hints
    elif echo "$diff_text" | grep -qiE '(session_hints|dedupl|shared.*reference)'; then
        rationale="Refactored to reduce redundancy per deduplication discipline"

    # Pattern: develop-then-refactor strategy
    elif echo "$diff_text" | grep -qiE '(develop.*refactor|common.*codebase|platform.insensitive)'; then
        rationale="Updated documentation for develop-then-refactor strategy"

    # Pattern: library API design
    elif echo "$diff_text" | grep -qiE '(library.*first|API.*design|intentional.*abstraction)'; then
        rationale="Clarified library-first API design intent for consumers"

    # Pattern: prompt versioning / changelog
    elif echo "$diff_text" | grep -qiE '(gen_state|changelog|prompt.*version)'; then
        rationale="Added prompt versioning and changelog tracking mechanism"

    # Pattern: large additions (>100 lines) to functional specs
    elif echo "$diff_text" | grep -c '^+' 2>/dev/null | awk '{exit ($1 > 100) ? 0 : 1}'; then
        rationale="Expanded functional specification with new requirements"

    # Pattern: deletions across multiple files
    elif echo "$diff_text" | grep -c '^-' 2>/dev/null | awk '{exit ($1 > 50) ? 0 : 1}'; then
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

    # Read existing content, insert entry after the "---" separator line
    local temp_file
    temp_file=$(mktemp)

    # Everything before the first "---" (header + entries section start)
    local found_separator=0
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        if [ $found_separator -eq 0 ] && echo "$line" | grep -q '^---$'; then
            found_separator=1
            echo "" >> "$temp_file"
            echo "$entry" >> "$temp_file"
        fi
    done < "$CHANGELOG"

    # Append any remaining content after the separator
    local past_separator=0
    while IFS= read -r line; do
        if [ $past_separator -eq 0 ] && echo "$line" | grep -q '^---$'; then
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
