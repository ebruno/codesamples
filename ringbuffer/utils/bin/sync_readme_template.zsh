#!/usr/bin/env zsh
# sync_readme_template.zsh — Extract README.md section headers and update readme_template.md
# Usage: ./utils/bin/sync_readme_template.zsh [workspace_root]

set -euo pipefail

WORKSPACE="${1:-.}"
README="$WORKSPACE/README.md"
TEMPLATE="$WORKSPACE/prompts/common/templates/readme_template.md"

if [ ! -f "$README" ]; then
    print -u2 "ERROR: README.md not found at $README"
    exit 1
fi
if [ ! -f "$TEMPLATE" ]; then
    print -u2 "ERROR: readme_template.md not found at $TEMPLATE"
    exit 1
fi

# Extract ## and ### headers from README.md (### items are indented)
typeset -a headers
while IFS= read -r line; do
    if [[ "$line" =~ ^###[[:space:]]+(.+)$ ]]; then
        headers+=("  $line")
    elif [[ "$line" =~ ^##[[:space:]]+(.+)$ ]]; then
        headers+=("$line")
    fi
done < "$README"

# Read the template and replace the Content Structure section
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

integer in_section=0 section_done=0
while IFS= read -r line; do
    if (( section_done )); then
        printf '%s\n' "$line" >> "$tmp"
        continue
    fi

    if (( ! in_section )) && [[ "$line" =~ ^##[[:space:]]+Content[[:space:]]+Structure ]]; then
        in_section=1
        printf '%s\n' "$line" >> "$tmp"
        continue
    fi

    if (( in_section )); then
        # Check if we've hit the next section (## Test Matrix or ## Platform)
        if [[ "$line" =~ ^##[[:space:]]+ ]]; then
            for h in "${headers[@]}"; do
                printf '%s\n' "$h" >> "$tmp"
            done
            printf '\n' >> "$tmp"
            printf '%s\n' "$line" >> "$tmp"
            section_done=1
            continue
        fi
        # Skip old content lines within the section
        continue
    fi

    printf '%s\n' "$line" >> "$tmp"
done < "$TEMPLATE"

if (( ! section_done && in_section )); then
    for h in "${headers[@]}"; do
        printf '%s\n' "$h" >> "$tmp"
    done
    printf '\n' >> "$tmp"
fi

mv "$tmp" "$TEMPLATE"
print "Synced ${#headers} headers from README.md → readme_template.md"
