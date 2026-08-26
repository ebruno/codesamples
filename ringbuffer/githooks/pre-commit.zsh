#!/usr/bin/env zsh
# Ringbuffer — Pre-commit hook: README ↔ generate_toplevel_readme.md consistency
#
# Uses native zsh regex and associative arrays — no external tools (grep, sed, awk).
# See githooks/INSTALL.md for installation instructions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
README="$SCRIPT_DIR/README.md"
PROMPT="$SCRIPT_DIR/prompts/common/generate_toplevel_readme.md"

# ── Color helpers (graceful degradation if no TTY) ─────────────────────
if [ -t 1 ]; then
    RED='%F{red}'; YELLOW='%F{yellow}'; GREEN='%F{green}'; NC='%f'
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
    print -r -- ""
    print -P "${RED}✗ BLOCKED: README.md was modified but generate_toplevel_readme.md was not.${NC}"
    print -r -- ""
    print -r -- "  The README is the source of truth. When you change it, update"
    print -r -- "  prompts/common/generate_toplevel_readme.md to match."
    print -r -- ""
    print -r -- "  Either:"
    print -r -- "    1. Stage the prompt file too: git add prompts/common/generate_toplevel_readme.md"
    print -r -- "    2. Or revert the README change if it was accidental."
    print -r -- ""
    exit 1
fi

if [ "$PROMPT_STAGED" -gt 0 ] && [ "$README_STAGED" -eq 0 ]; then
    print -r -- ""
    print -P "${RED}✗ BLOCKED: generate_toplevel_readme.md was modified but README.md was not.${NC}"
    print -r -- ""
    print -r -- "  The prompt describes what the README should look like. If you changed"
    print -r -- "  the prompt, either regenerate the README or revert the prompt."
    print -r -- ""
    exit 1
fi

# ── Rule 2: Section Alignment (WARNING) ───────────────────────────────
# Extract ## and ### section headers using native zsh regex.
# [**] matches literal asterisks (zsh ERE does not support \*\*).
# [^*]+ captures only non-asterisk characters (acts as non-greedy match).

extract_headers() {
    local file="$1"
    local line name

    while IFS= read -r line; do
        # Standard Markdown ## headers (not ###)
        if [[ "$line" =~ ^##[[:space:]]+(.+)$ ]]; then
            name="$match[1]"
            [[ "$line" =~ ^### ]] && continue
            print -r -- "$name"
        # Standard Markdown ### headers
        elif [[ "$line" =~ ^###[[:space:]]+(.+)$ ]]; then
            print -r -- "$match[1]"
        # Prompt-style embedded ## names: **## Title** or similar
        elif [[ "$line" =~ [**][**][[:space:]]*##[[:space:]]+([^*]+)[**] ]]; then
            print -r -- "$match[1]"
        # Prompt-style embedded ### names: **### Subtitle**
        elif [[ "$line" =~ [**][**][[:space:]]*###[[:space:]]+([^*]+)[**] ]]; then
            print -r -- "$match[1]"
        fi
    done < "$file" 2>/dev/null || true
}

# Build associative arrays for O(1) lookup (zsh-native syntax)
typeset -A readme_sections
while IFS= read -r h; do
    [ -n "$h" ] && readme_sections["$h"]=1
done < <(extract_headers "$README")

typeset -A prompt_sections
while IFS= read -r h; do
    [ -n "$h" ] && prompt_sections["$h"]=1
done < <(extract_headers "$PROMPT")

# Find mismatches using zsh-native array iteration
missing_in_prompt=()
missing_in_readme=()

for h in ${(k)readme_sections}; do
    if [ -z "${prompt_sections[$h]:-}" ]; then
        missing_in_prompt+=("$h")
    fi
done

for h in ${(k)prompt_sections}; do
    if [ -z "${readme_sections[$h]:-}" ]; then
        missing_in_readme+=("$h")
    fi
done

if [ ${#missing_in_prompt[@]} -gt 0 ] || [ ${#missing_in_readme[@]} -gt 0 ]; then
    print -r -- ""
    print -P "${YELLOW}⚠ WARNING: Section alignment mismatch detected${NC}"
    print -r -- ""

    if [ ${#missing_in_prompt[@]} -gt 0 ]; then
        print -r -- "  Sections in README but NOT in prompt:"
        for h in "${missing_in_prompt[@]}"; do
            print -r -- "    + $h"
        done
    fi

    if [ ${#missing_in_readme[@]} -gt 0 ]; then
        print -r -- "  Sections in prompt but NOT in README:"
        for h in "${missing_in_readme[@]}"; do
            print -r -- "    - $h"
        done
    fi

    print -r -- ""
    print -r -- "  Update prompts/common/generate_toplevel_readme.md to match README.md."
    print -r -- ""
fi

# ── Rule 3: .bionic.d/* → CLAUDE.md sync (HARD BLOCK) ────────────────────
# CLAUDE.md is assembled from .bionic.d/project.md + .bionic.d/rules.md
BIONIC_MOD_STAGED=0
CLAUDE_STAGED=0
while IFS= read -r f; do
    nf=$(normalize_path "$f")
    case "$nf" in
        .bionic.d/project.md) BIONIC_MOD_STAGED=1 ;;
        .bionic.d/rules.md) BIONIC_MOD_STAGED=1 ;;
        CLAUDE.md) CLAUDE_STAGED=1 ;;
    esac
done <<< "$STAGED_FILES"

if [ "$BIONIC_MOD_STAGED" -gt 0 ]; then
    # Compare staged CLAUDE.md against the concatenation of its sources
    PROJECT_HASH=$(git show :ringbuffer/.bionic.d/project.md 2>/dev/null | md5sum)
    RULES_HASH=$(git show :ringbuffer/.bionic.d/rules.md 2>/dev/null | md5sum)
    COMBINED_HASH=$(printf '%s%s' "$PROJECT_HASH" "$RULES_HASH" | md5sum)
    CLAUDE_HASH=$(git show :ringbuffer/CLAUDE.md 2>/dev/null | md5sum)
    
    # Reconstruct what CLAUDE.md should be and compare
    EXPECTED=$(git show :ringbuffer/.bionic.d/project.md :ringbuffer/.bionic.d/rules.md 2>/dev/null | md5sum)
    
    if [ "$EXPECTED" != "$CLAUDE_HASH" ]; then
        print -r -- ""
        print -r -- "${RED}✗ BLOCKED: .bionic.d/project.md or .bionic.d/rules.md was modified but CLAUDE.md is not in sync.${NC}"
        print -r -- ""
        print -r -- "  CLAUDE.md = cat .bionic.d/project.md .bionic.d/rules.md"
        print -r -- "  Run: cat .bionic.d/project.md .bionic.d/rules.md > CLAUDE.md"
        print -r -- "  Then re-stage CLAUDE.md and retry the commit."
        print -r -- ""
        exit 1
    fi
fi

# ── Done ───────────────────────────────────────────────────────────────
exit 0
