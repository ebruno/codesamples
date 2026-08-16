# Ringbuffer Prompt Changelog — Template

> **Purpose**: Track prompt file changes between generations for auditability and reproducibility.
> 
> **Status**: Template only — no automation logic uses this file at this time. Manual updates are required.
> 
> **Automation**: The `utils/bin/suggest_changelog_entry.sh` script can analyze git diffs and suggest changelog entries. See the [suggestion script](../../utils/bin/suggest_changelog_entry.sh) for usage.

## Format

Each entry MUST follow this structure:

```markdown
## [YYYY-MM-DD] <short description>
- **File**: `prompts/<path>/<filename>.md`
- **Change**: <one-line description of what changed>
- **Rationale**: <why this change was made, linking to any assessment or requirement>
```

## How to Use

1. Make changes to prompt files and commit them.
2. The post-commit hook will print a suggested entry to your terminal.
3. Copy the suggested entry into `prompts/common/CHANGELOG.md` (the actual changelog).
4. Refine the Rationale field if needed.

---
