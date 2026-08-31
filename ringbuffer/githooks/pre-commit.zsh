#!/usr/bin/env zsh
# Ringbuffer — Pre-commit hook: README ↔ readme_template.md consistency
#
# Uses native zsh regex and associative arrays — no external tools (grep, sed, awk).
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
SYNC_SCRIPT="$SCRIPT_DIR/utils/bin/sync_readme_template.zsh"

# ── Color helpers (graceful degradation if no TTY) ─────────────────────
if [ -t 1 ]; then
    RED='%F{red}'; YELLOW='%F{yellow}'; GREEN='%F{green}'; NC='%f'
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

# ── Rule 1: Auto-sync template + TOC from README.md (before block check) ───
# When README.md is staged, automatically update readme_template.md and TOC
SYNC_OK=0
TOC_OK=0
if [ "$README_STAGED" -gt 0 ]; then
    # Sync readme_template.md
    if [ -x "$SYNC_SCRIPT" ]; then
        zsh "$SYNC_SCRIPT" "$SCRIPT_DIR" 2>/dev/null && {
            git add "$TEMPLATE" 2>/dev/null || true
            print -P "${GREEN}✓ Auto-synced readme_template.md from README.md${NC}"
            SYNC_OK=1
        } || {
            print -P "${YELLOW}⚠ Warning: Could not auto-sync readme_template.md${NC}"
        }
    fi
    # Sync TOC
    TOC_SCRIPT="$SCRIPT_DIR/utils/bin/sync_readme_toc.zsh"
    if [ -x "$TOC_SCRIPT" ]; then
        zsh "$TOC_SCRIPT" >/dev/null 2>&1 && {
            git add "$README" 2>/dev/null || true
            print -P "${GREEN}✓ Auto-synced README.md Table of Contents${NC}"
            TOC_OK=1
        } || {
            print -P "${YELLOW}⚠ Warning: Could not auto-sync README.md TOC${NC}"
        }
    fi
fi

# ── Rule 2: Both-or-None (HARD BLOCK) ─────────────────────────────────
# Only block if README was staged, template wasn't pre-staged, AND sync failed
if [ "$README_STAGED" -gt 0 ] && [ "$PROMPT_STAGED" -eq 0 ] && [ "$SYNC_OK" -eq 0 ]; then
    print -r -- ""
    print -P "${RED}✗ BLOCKED: README.md was modified but readme_template.md was not.${NC}"
    print -r -- ""
    print -r -- "  The README is the source of truth. When you change it, update"
    print -r -- "  prompts/common/templates/readme_template.md to match."
    print -r -- ""
    print -r -- "  Either:"
    print -r -- "    1. Stage the prompt file too: git add prompts/common/templates/readme_template.md"
    print -r -- "    2. Or revert the README change if it was accidental."
    print -r -- ""
    exit 1
fi

if [ "$PROMPT_STAGED" -gt 0 ] && [ "$README_STAGED" -eq 0 ]; then
    print -r -- ""
    print -P "${RED}✗ BLOCKED: readme_template.md was modified but README.md was not.${NC}"
    print -r -- ""
    print -r -- "  The prompt describes what the README should look like. If you changed"
    print -r -- "  the prompt, either regenerate the README or revert the prompt."
    print -r -- ""
    exit 1
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
    # Rebuild expected CLAUDE.md from sources and compare against working tree
    expected_content=$(cat "$SCRIPT_DIR/.bionic.d/project.md" "$SCRIPT_DIR/.bionic.d/rules.md" 2>/dev/null)
    claude_content=$(cat "$SCRIPT_DIR/CLAUDE.md" 2>/dev/null)
    
    if [ "$expected_content" != "$claude_content" ]; then
        print -r -- ""
        print -r -- "${RED}✗ BLOCKED: .bionic.d/project.md or .bionic.d/rules.md was modified but CLAUDE.md is not in sync.${NC}"
        print -r -- ""
        print -r -- "  CLAUDE.md = cat .bionic.d/project.md .bionic.d/rules.md"
        print -r -- "  Run: cat .bionic.d/project.md .bionic.d/rules.md > CLAUDE.md"
        print -r -- "  Then: git add .bionic.d/project.md .bionic.d/rules.md CLAUDE.md"
        print -r -- "  (Re-stage ALL three files — bionic files may have unstaged edits.)"
        print -r -- ""
        exit 1
    fi
fi

# ── Rule 4: TOC verification when README.md is staged (HARD BLOCK) ────
# Only block if sync didn't already fix it
if [ "$README_STAGED" -gt 0 ] && [ "$TOC_OK" -eq 0 ]; then
    TOC_SCRIPT="$SCRIPT_DIR/utils/bin/sync_readme_toc.zsh"
    if [ -x "$TOC_SCRIPT" ]; then
        if ! zsh "$TOC_SCRIPT" --check "$SCRIPT_DIR" 2>/dev/null; then
            print -r -- ""
            print -P "${RED}✗ BLOCKED: README.md was modified but the Table of Contents is stale.${NC}"
            print -r -- ""
            print -r -- "  Run: utils/bin/sync_readme_toc.zsh"
            print -r -- "  Then re-stage README.md and retry the commit."
            print -r -- ""
            exit 1
        fi
    fi
fi

# ── Done ───────────────────────────────────────────────────────────────
exit 0
