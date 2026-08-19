#!/usr/bin/env bash
# Ringbuffer — Pre-commit hook: README ↔ generate_toplevel_readme.md consistency
#
# Uses native bash regex and associative arrays — no external tools (grep, sed, awk).
# See githooks/INSTALL.md for installation instructions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
README="$SCRIPT_DIR/README.md"
PROMPT="$SCRIPT_DIR/prompts/common/generate_toplevel_readme.md"

# ── Color helpers (graceful degradation if no TTY) ─────────────────────
if [ -t 1 ]; then
    RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'; NC='\033[0m'
else
    RED=''; YELLOW=''; GREEN=''; NC=''
fi

# ── Determine if we're in the ringbuffer project ───────────────────────
if [ ! -f "$README" ]; then
    exit 0
fi

# ── Gather staged file list (relative to git repo root) ────────────────
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
if [ -z "$STAGED_FILES" ]; then
    exit 0
fi

# Normalize paths: strip the ringbuffer/ prefix if present.
normalize_path() {
    local p="$1"
    case "$p" in
        ringbuffer/*) p="${p#ringbuffer/}" ;;
    esac
    printf '%s' "$p"
}

README_STAGED=0
PROMPT_STAGED=0
while IFS= read -r f; do
    nf=$(normalize_path "$f")
    case "$nf" in
        README.md) README_STAGED=1 ;;
        prompts/common/generate_toplevel_readme.md) PROMPT_STAGED=1 ;;
    esac
done <<< "$STAGED_FILES"

# ── Rule 1: Both-or-None (HARD BLOCK) ─────────────────────────────────
if [ "$README_STAGED" -gt 0 ] && [ "$PROMPT_STAGED" -eq 0 ]; then
    echo ""
    echo -e "${RED}✗ BLOCKED: README.md was modified but generate_toplevel_readme.md was not.${NC}"
    echo ""
    echo "  The README is the source of truth. When you change it, update"
    echo "  prompts/common/generate_toplevel_readme.md to match."
    echo ""
    echo "  Either:"
    echo "    1. Stage the prompt file too: git add prompts/common/generate_toplevel_readme.md"
    echo "    2. Or revert the README change if it was accidental."
    echo ""
    exit 1
fi

if [ "$PROMPT_STAGED" -gt 0 ] && [ "$README_STAGED" -eq 0 ]; then
    echo ""
    echo -e "${RED}✗ BLOCKED: generate_toplevel_readme.md was modified but README.md was not.${NC}"
    echo ""
    echo "  The prompt describes what the README should look like. If you changed"
    echo "  the prompt, either regenerate the README or revert the prompt."
    echo ""
    exit 1
fi

# ── Rule 2: Section Alignment (WARNING) ───────────────────────────────
# Extract ## and ### section headers using native bash regex.
# [**] matches literal asterisks (bash ERE does not support \*\*).
# [^*]+ captures only non-asterisk characters (acts as non-greedy match).

extract_headers() {
    local file="$1"
    local line name

    while IFS= read -r line; do
        # Standard Markdown ## headers (not ###)
        if [[ "$line" =~ ^##[[:space:]]+(.+)$ ]]; then
            name="${BASH_REMATCH[1]}"
            [[ "$line" =~ ^### ]] && continue
            printf '%s\n' "$name"
        # Standard Markdown ### headers
        elif [[ "$line" =~ ^###[[:space:]]+(.+)$ ]]; then
            printf '%s\n' "${BASH_REMATCH[1]}"
        # Prompt-style embedded ## names: **## Title** or similar
        elif [[ "$line" =~ [**][**][[:space:]]*##[[:space:]]+([^*]+)[**] ]]; then
            printf '%s\n' "${BASH_REMATCH[1]}"
        # Prompt-style embedded ### names: **### Subtitle**
        elif [[ "$line" =~ [**][**][[:space:]]*###[[:space:]]+([^*]+)[**] ]]; then
            printf '%s\n' "${BASH_REMATCH[1]}"
        fi
    done < "$file" 2>/dev/null || true
}

# Build associative arrays for O(1) lookup
declare -A readme_sections
while IFS= read -r h; do
    [ -n "$h" ] && readme_sections["$h"]=1
done < <(extract_headers "$README")

declare -A prompt_sections
while IFS= read -r h; do
    [ -n "$h" ] && prompt_sections["$h"]=1
done < <(extract_headers "$PROMPT")

# Find mismatches
missing_in_prompt=()
missing_in_readme=()

for h in "${!readme_sections[@]}"; do
    if [ -z "${prompt_sections[$h]+x}" ]; then
        missing_in_prompt+=("$h")
    fi
done

for h in "${!prompt_sections[@]}"; do
    if [ -z "${readme_sections[$h]+x}" ]; then
        missing_in_readme+=("$h")
    fi
done

if [ ${#missing_in_prompt[@]} -gt 0 ] || [ ${#missing_in_readme[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠ WARNING: Section alignment mismatch detected${NC}"
    echo ""

    if [ ${#missing_in_prompt[@]} -gt 0 ]; then
        echo "  Sections in README but NOT in prompt:"
        for h in "${missing_in_prompt[@]}"; do
            echo "    + $h"
        done
    fi

    if [ ${#missing_in_readme[@]} -gt 0 ]; then
        echo "  Sections in prompt but NOT in README:"
        for h in "${missing_in_readme[@]}"; do
            echo "    - $h"
        done
    fi

    echo ""
    echo "  Update prompts/common/generate_toplevel_readme.md to match README.md."
    echo ""
fi

# ── Done ───────────────────────────────────────────────────────────────
exit 0
