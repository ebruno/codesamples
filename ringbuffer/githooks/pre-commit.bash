#!/usr/bin/env bash
# Ringbuffer — Pre-commit hook: README ↔ readme_template.md consistency
#
# Uses native bash regex and associative arrays — no external tools (grep, sed, awk).
# See githooks/INSTALL.md for installation instructions.

set -euo pipefail

# ── Resolve ringbuffer workspace root ──────────────────────────────────
# Handles both standalone repos and multi-project repos (ringbuffer/ subdir)
find_workspace() {
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
    if [ -n "$repo_root" ] && [ -d "$repo_root/ringbuffer" ] && [ -f "$repo_root/ringbuffer/.bionic" ]; then
        cd "$repo_root/ringbuffer" && pwd
    else
        cd "$(dirname "$0")/../.." && pwd
    fi
}

SCRIPT_DIR=$(find_workspace)
README="$SCRIPT_DIR/README.md"
TEMPLATE="$SCRIPT_DIR/prompts/common/templates/readme_template.md"
SYNC_SCRIPT="$SCRIPT_DIR/utils/bin/sync_readme_template.sh"

# ── Color helpers (graceful degradation if no TTY) ─────────────────────
if [ -t 1 ]; then
    RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'; NC='\033[0m'
else
    RED=''; YELLOW=''; GREEN=''; NC=''
fi

# ── Determine if we're in the ringbuffer project ───────────────────────
if [ ! -f "$SCRIPT_DIR/.bionic" ]; then
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
        prompts/common/templates/readme_template.md) PROMPT_STAGED=1 ;;
    esac
done <<< "$STAGED_FILES"

# ── Rule 1: Both-or-None (HARD BLOCK) ─────────────────────────────────
if [ "$README_STAGED" -gt 0 ] && [ "$PROMPT_STAGED" -eq 0 ]; then
    echo ""
    echo -e "${RED}✗ BLOCKED: README.md was modified but readme_template.md was not.${NC}"
    echo ""
    echo "  The README is the source of truth. When you change it, update"
    echo "  prompts/common/templates/readme_template.md to match."
    echo ""
    echo "  Either:"
    echo "    1. Stage the template file too: git add prompts/common/templates/readme_template.md"
    echo "    2. Or revert the README change if it was accidental."
    echo ""
    exit 1
fi

if [ "$PROMPT_STAGED" -gt 0 ] && [ "$README_STAGED" -eq 0 ]; then
    echo ""
    echo -e "${RED}✗ BLOCKED: readme_template.md was modified but README.md was not.${NC}"
    echo ""
    echo "  The prompt describes what the README should look like. If you changed"
    echo "  the prompt, either regenerate the README or revert the prompt."
    echo ""
    exit 1
fi

# ── Rule 2: Auto-sync template from README.md ────────────────────────
# When README.md is staged, automatically update readme_template.md
if [ "$README_STAGED" -gt 0 ]; then
    if [ -x "$SYNC_SCRIPT" ]; then
        bash "$SYNC_SCRIPT" "$SCRIPT_DIR" 2>/dev/null && {
            git add "$TEMPLATE" 2>/dev/null || true
            echo -e "${GREEN}✓ Auto-synced readme_template.md from README.md${NC}"
        } || {
            echo -e "${YELLOW}⚠ Warning: Could not auto-sync readme_template.md${NC}"
        }
    fi
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
        echo ""
        echo -e "${RED}✗ BLOCKED: .bionic.d/project.md or .bionic.d/rules.md was modified but CLAUDE.md is not in sync.${NC}"
        echo ""
        echo "  CLAUDE.md = cat .bionic.d/project.md .bionic.d/rules.md"
        echo "  Run: cat .bionic.d/project.md .bionic.d/rules.md > CLAUDE.md"
        echo "  Then re-stage CLAUDE.md and retry the commit."
        echo ""
        exit 1
    fi
fi

# ── Done ───────────────────────────────────────────────────────────────
exit 0
