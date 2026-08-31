#!/usr/bin/env zsh
# sync_readme_toc.zsh — Regenerate the Table of Contents in README.md
# Usage: ./utils/bin/sync_readme_toc.zsh [--check] [workspace_root]
#
# Without --check: regenerates the "## Contents" section if stale.
# With --check: validates only, exits 0 if current, 1 if stale, 2 on error.

set -euo pipefail

CHECK_ONLY=0
WORKSPACE="."
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        *) WORKSPACE="$arg" ;;
    esac
done
README="$WORKSPACE/README.md"

if [ ! -f "$README" ]; then
    print -u2 "ERROR: README.md not found at $README"
    exit 1
fi

# ── Build fresh TOC from README headers ──────────────────────────
typeset -a toc_lines
integer in_code_block=0

local hashes title level title_clean anchor indent ii
while IFS= read -r line; do
    # Track code blocks so we don't match headers inside them
    if [[ "$line" =~ ^[[:space:]]*\`\`\` ]]; then
        in_code_block=$((1 - in_code_block))
        continue
    fi
    (( in_code_block )) && continue

    # Match ##, ###, or #### headers at column 0
    if [[ "$line" =~ ^(#{2,4})[[:space:]]+(.+)$ ]]; then
        # Skip the Contents header itself — don't self-reference
        [[ "$line" == "## Contents" ]] && continue
        hashes="$match[1]"
        title="$match[2]"
        level=${#hashes}

        # Strip inline code backticks from title for display
        title_clean="${title//\`/}"
        # Strip markdown links — keep text, drop URL portion
        while [[ "$title_clean" =~ \[([^\]]+)\]\([^\)]+\) ]]; do
            title_clean="${title_clean//${match[0]}/${match[1]}}"
        done

        # Build anchor: lowercase, keep only alphanumeric, spaces, hyphens
        anchor="${(L)title_clean}"
        # Remove all chars except a-z 0-9 space hyphen
        anchor="${anchor//[^a-z0-9 -]/}"
        # Collapse spaces to hyphens
        anchor="${anchor// /-}"
        # Collapse multiple hyphens
        while [[ "$anchor" =~ -- ]]; do
            anchor="${anchor//--/-}"
        done
        anchor="${anchor#-}"
        anchor="${anchor%-}"

        indent=""
        for ((ii=2; ii<level; ii++)); do
            indent="$indent  "
        done
        toc_lines+=("${indent}- [${title_clean}](#${anchor})")
    fi
done < "$README"

if (( ${#toc_lines} == 0 )); then
    print -u2 "ERROR: No headers found in README.md"
    exit 1
fi

# ── Build the complete Contents block ─────────────────────────────
typeset -a new_contents
new_contents+=("## Contents")
new_contents+=("")
for t in "${toc_lines[@]}"; do
    new_contents+=("$t")
done

# ── Read current README, find Contents section boundaries ─────────
typeset -a readme_lines
while IFS= read -r line; do
    readme_lines+=("$line")
done < "$README"

integer contents_start=0 contents_end=0 i=1
for line in "${readme_lines[@]}"; do
    if (( contents_start == 0 )) && [[ "$line" == "## Contents" ]]; then
        contents_start=$i
    elif (( contents_start > 0 )) && (( contents_end == 0 )) && [[ "$line" =~ ^##[[:space:]]+ ]] && [[ "$line" != "## Contents" ]]; then
        contents_end=$i
        break
    fi
    i=$((i + 1))
done

if (( contents_start == 0 )); then
    print -u2 "ERROR: '## Contents' section not found in README.md"
    exit 1
fi

# Contents end is the blank line before the next ## section
if (( contents_end == 0 )); then
    print -u2 "ERROR: Could not find end of Contents section"
    exit 1
fi

# ── Compare: strip all blank lines from both, compare entry lines ─
# Only compare non-empty lines (skips "## Contents" header + blank lines)
typeset -a current_entries new_entries
local _line
for ((j=contents_start; j<contents_end; j++)); do
    _line="${readme_lines[$j]}"
    [[ -n "${_line// /}" ]] && current_entries+=("$_line")
done
for entry in "${new_contents[@]}"; do
    [[ -n "${entry// /}" ]] && new_entries+=("$entry")
done

if [[ "${(j:\n:)current_entries}" == "${(j:\n:)new_entries}" ]]; then
    print "TOC is current — no update needed."
    exit 0
fi

# ── Stale: either report (check mode) or replace ─────────────────
if (( CHECK_ONLY )); then
    print -u2 "TOC is STALE — run: utils/bin/sync_readme_toc.zsh"
    exit 1
fi

# ── Replace the Contents block ───────────────────────────────────
typeset -a new_readme
for ((j=1; j<contents_start; j++)); do
    new_readme+=("${readme_lines[$j]}")
done

# Insert a blank line before the new contents block if needed
local prev_line="${readme_lines[$((contents_start - 1))]}"
if [[ -n "${prev_line// /}" ]]; then
    new_readme+=("")
fi

for t in "${new_contents[@]}"; do
    new_readme+=("$t")
done

# Add a blank line after Contents before the next section
new_readme+=("")

for ((j=contents_end; j<=${#readme_lines[@]}; j++)); do
    new_readme+=("${readme_lines[$j]}")
done

# Write back
local tmp="$WORKSPACE/.tmp_readme_toc"
printf '%s\n' "${new_readme[@]}" > "$tmp"
mv "$tmp" "$README"

print "TOC updated — $((${#toc_lines[@]})) entries regenerated."
exit 0
