#!/usr/bin/env bash
# sync_readme_template.sh — Extract README.md section headers and update readme_template.md
# Usage: ./utils/bin/sync_readme_template.sh [workspace_root]

set -euo pipefail

WORKSPACE="${1:-.}"
README="$WORKSPACE/README.md"
TEMPLATE="$WORKSPACE/prompts/common/templates/readme_template.md"

if [ ! -f "$README" ]; then
    echo "ERROR: README.md not found at $README" >&2
    exit 1
fi
if [ ! -f "$TEMPLATE" ]; then
    echo "ERROR: readme_template.md not found at $TEMPLATE" >&2
    exit 1
fi

# Extract ## and ### headers from README.md (### items are indented)
headers=()
while IFS= read -r line; do
    if [[ "$line" =~ ^###[[:space:]]+(.+)$ ]]; then
        headers+=("  $line")
    elif [[ "$line" =~ ^##[[:space:]]+(.+)$ ]]; then
        headers+=("$line")
    fi
done < "$README"

# Read the template and replace the Content Structure section
# Strategy: find the "## Content Structure" line and the next "## " line,
# replace everything between them with the current headers.

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

in_section=false
section_done=false
while IFS= read -r line; do
    if [ "$section_done" = true ]; then
        printf '%s\n' "$line" >> "$tmp"
        continue
    fi

    if [ "$in_section" = false ] && [[ "$line" =~ ^##[[:space:]]+Content[[:space:]]+Structure ]]; then
        in_section=true
        printf '%s\n' "$line" >> "$tmp"
        continue
    fi

    if [ "$in_section" = true ]; then
        # Check if we've hit the next section (## Test Matrix or ## Platform)
        if [[ "$line" =~ ^##[[:space:]]+ ]]; then
            # Write the new headers before the next section
            for h in "${headers[@]}"; do
                printf '%s\n' "$h" >> "$tmp"
            done
            printf '\n' >> "$tmp"
            printf '%s\n' "$line" >> "$tmp"
            section_done=true
            continue
        fi
        # Skip old numbered lines within the section
        if [[ "$line" =~ ^[[:space:]]*[0-9]+\. ]]; then
            continue
        fi
        # Skip blank lines within section (we'll add our own)
        continue
    fi

    printf '%s\n' "$line" >> "$tmp"
done < "$TEMPLATE"

# If we never found the end of section (no ## Test Matrix after), append at end
if [ "$section_done" = false ] && [ "$in_section" = true ]; then
    for h in "${headers[@]}"; do
        printf '%s\n' "$h" >> "$tmp"
    done
    printf '\n' >> "$tmp"
fi

mv "$tmp" "$TEMPLATE"
echo "Synced ${#headers[@]} headers from README.md → readme_template.md"
