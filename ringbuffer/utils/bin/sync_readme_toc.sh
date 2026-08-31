#!/usr/bin/env bash
# sync_readme_toc.sh — Regenerate the Table of Contents in README.md
# Usage: ./utils/bin/sync_readme_toc.sh [--check] [workspace_root]
#
# Bash-compatible version. See sync_readme_toc.zsh for the zsh variant.

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
    echo "ERROR: README.md not found at $README" >&2
    exit 1
fi

# ── Build fresh TOC from README headers ──────────────────────────
toc_lines=()
in_code_block=0

while IFS= read -r line; do
    # Track code blocks
    case "$line" in
        '```'*) in_code_block=$((1 - in_code_block)); continue ;;
    esac
    [ "$in_code_block" -eq 1 ] && continue

    # Match ##, ###, or #### headers at column 0
    case "$line" in
        "#### "*|"### "*|"## "*)
            ;;
        *)
            continue
            ;;
    esac

    # Skip the Contents header itself — don't self-reference
    [ "$line" = "## Contents" ] && continue

    # Count leading hashes
    hashes="${line%% *}"
    level=${#hashes}
    # Extract title (everything after the first space)
    title="${line#* }"
    title="${title#"${title%%[![:space:]]*}"}"  # trim leading whitespace

    # Strip inline code backticks
    title_clean="${title//\`/}"
    # Strip markdown links — keep text, drop URL
    while [[ "$title_clean" =~ \[([^\]]+)\]\([^\)]+\) ]]; do
        title_clean="${title_clean//${BASH_REMATCH[0]}/${BASH_REMATCH[1]}}"
    done

    # Build anchor: lowercase, only alphanumeric/space/hyphen
    anchor=$(printf '%s' "$title_clean" | tr '[:upper:]' '[:lower:]')
    # Remove all chars except a-z 0-9 space hyphen
    anchor=$(printf '%s' "$anchor" | tr -cd 'a-z0-9 -')
    # Collapse spaces to hyphens
    anchor=$(printf '%s' "$anchor" | tr ' ' '-')
    # Collapse multiple hyphens
    while [[ "$anchor" == *--* ]]; do
        anchor="${anchor//--/-}"
    done
    anchor="${anchor#-}"
    anchor="${anchor%-}"

    indent=""
    for ((i=2; i<level; i++)); do
        indent="$indent  "
    done
    toc_lines+=("${indent}- [${title_clean}](#${anchor})")
done < "$README"

if [ ${#toc_lines[@]} -eq 0 ]; then
    echo "ERROR: No headers found in README.md" >&2
    exit 1
fi

# ── Build the complete Contents block ─────────────────────────────
new_contents=("## Contents" "")
for t in "${toc_lines[@]}"; do
    new_contents+=("$t")
done

# ── Read current README, find Contents section boundaries ─────────
readme_lines=()
while IFS= read -r line; do
    readme_lines+=("$line")
done < "$README"

contents_start=0
contents_end=0
i=1
for line in "${readme_lines[@]}"; do
    if [ "$contents_start" -eq 0 ] && [ "$line" = "## Contents" ]; then
        contents_start=$i
    elif [ "$contents_start" -gt 0 ] && [ "$contents_end" -eq 0 ] && [[ "$line" =~ ^##[[:space:]]+ ]] && [ "$line" != "## Contents" ]; then
        contents_end=$i
        break
    fi
    i=$((i + 1))
done

if [ "$contents_start" -eq 0 ]; then
    echo "ERROR: '## Contents' section not found in README.md" >&2
    exit 1
fi
if [ "$contents_end" -eq 0 ]; then
    echo "ERROR: Could not find end of Contents section" >&2
    exit 1
fi

# ── Compare: strip all blank lines from both, compare entry lines ─
current_entries=()
new_entries=()
for ((j=contents_start; j<contents_end; j++)); do
    _line="${readme_lines[$((j-1))]}"
    _trimmed="${_line// /}"
    [ -n "$_trimmed" ] && current_entries+=("$_line")
done
for entry in "${new_contents[@]}"; do
    _trimmed="${entry// /}"
    [ -n "$_trimmed" ] && new_entries+=("$entry")
done

current_joined=$(printf '%s\n' "${current_entries[@]}")
new_joined=$(printf '%s\n' "${new_entries[@]}")

if [ "$current_joined" = "$new_joined" ]; then
    echo "TOC is current — no update needed."
    exit 0
fi

# ── Stale: either report (check mode) or replace ─────────────────
if [ "$CHECK_ONLY" -eq 1 ]; then
    echo "TOC is STALE — run: utils/bin/sync_readme_toc.sh" >&2
    exit 1
fi

# ── Replace the Contents block ───────────────────────────────────
new_readme=()
for ((j=0; j<contents_start-1; j++)); do
    new_readme+=("${readme_lines[$j]}")
done

# Insert blank line before contents if previous line is non-empty
prev_line="${readme_lines[$((contents_start - 2))]}"
prev_line_trimmed="${prev_line// /}"
if [ -n "$prev_line_trimmed" ]; then
    new_readme+=("")
fi

for t in "${new_contents[@]}"; do
    new_readme+=("$t")
done

new_readme+=("")

for ((j=contents_end-1; j<${#readme_lines[@]}; j++)); do
    new_readme+=("${readme_lines[$j]}")
done

# Write back
tmp="$WORKSPACE/.tmp_readme_toc"
printf '%s\n' "${new_readme[@]}" > "$tmp"
mv "$tmp" "$README"

echo "TOC updated — ${#toc_lines[@]} entries regenerated."
exit 0
