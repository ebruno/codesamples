#!/usr/bin/env zsh
# sync-bionic-rules.zsh — Extract context-specific sections from .bionic into rules/*.md
# Run this when .bionic changes to regenerate rule files and manifest.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

BIONIC="$PROJECT_ROOT/.bionic"
RULES_DIR="$PROJECT_ROOT/rules"
MANIFEST="$PROJECT_ROOT/.bionic_rules_manifest.txt"
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"

# Verify .bionic exists
if [ ! -f "$BIONIC" ]; then
    echo "ERROR: .bionic not found at $BIONIC"
    exit 1
fi

echo "=== sync-bionic-rules ==="
echo "Project root: $PROJECT_ROOT"
echo ".bionic size: $(wc -c < "$BIONIC") bytes"

# Create rules directory
mkdir -p "$RULES_DIR"

# Extract sections by header boundaries using Python for reliable content-based matching
export BIONIC_PATH="$BIONIC"
export RULES_DIR="$RULES_DIR"

python3 << 'PYTHON_SCRIPT'
import os, re, hashlib

bionic_path = os.environ.get("BIONIC_PATH", ".bionic")
rules_dir = os.environ.get("RULES_DIR", "rules")

with open(bionic_path, 'r') as f:
    bionic = f.read()

# Define sections to extract with their start markers and contexts
sections = [
    ("macos-containers", "**macOS Shell & Make — Critical for Local Builds:**", "macos"),
    ("freebsd-shell", "**FreeBSD 14 Shell & Make — Critical for Remote Builds:**", "freebsd14"),
    ("tcsh-syntax", "**Critical tcsh Syntax Rules (Learned 2026-08-21):", "freebsd14"),
    ("archlinux-containers", "### Arch Linux (Linux-Hosts-Only)", "archlinux"),
    ("ssh-transfer", "### SSH Remote Transfer Rule (All Platforms)", "ssh-transfer"),
    ("container-rules", "### Makefile & Shell Script Testing — Always Use OS Containers", "container"),
    ("container-naming", "### Container Naming Convention", "container"),
    ("container-dockerfile", "### Container Dockerfile Location", "container"),
    ("archlinux-pinning", "### Arch Linux Container Image Pinning", "archlinux"),
    ("container-commands-macos", "### Container Commands (macOS)", "macos"),
    ("mermaid-validation", "### Mermaid Diagram Validation", "readme-update"),
    ("freebsd-ssh", "### FreeBSD 14 SSH Execution — tcsh Script Rule (Permanent)", "freebsd14"),
]

# Extract each section
extracted = {}

for name, start_marker, context in sections:
    idx = bionic.find(start_marker)
    if idx == -1:
        print(f"ERROR: Could not find '{start_marker}'")
        continue
    
    line_start = bionic.rfind('\n', 0, idx) + 1
    
    # For freebsd-shell, stop at tcsh-syntax marker (not next ### header)
    if name == "freebsd-shell":
        search_from = idx + len(start_marker)
        tcsh_marker = "**Critical tcsh Syntax Rules (Learned 2026-08-21):"
        tcsh_idx = bionic.find(tcsh_marker, search_from)
        
        if tcsh_idx != -1:
            end_idx = bionic.rfind('\n\n', 0, tcsh_idx) + 1
            section_text = bionic[line_start:end_idx]
        else:
            search_from = idx + len(start_marker)
            next_header = bionic.find('\n### ', search_from)
            if next_header == -1:
                section_text = bionic[line_start:]
            else:
                section_text = bionic[line_start:next_header]
    else:
        search_from = idx + len(start_marker)
        next_header = bionic.find('\n### ', search_from)
        
        if next_header == -1:
            section_text = bionic[line_start:]
        else:
            section_text = bionic[line_start:next_header]
    
    extracted[name] = {
        'text': section_text,
        'start': line_start,
        'end': idx + len(section_text),
        'context': context,
    }

# Write rule files to output directory
os.makedirs(rules_dir, exist_ok=True)
for name, data in extracted.items():
    path = os.path.join(rules_dir, f'{name}.md')
    with open(path, 'w') as f:
        f.write(data['text'])
    print(f"  Extracted: {name}.md ({len(data['text'])} bytes)")

# Create modified .bionic with placeholders (NO extra newline)
placeholder_template = '<!-- RULES-LOAD: {context} -> rules/{name}.md -->'
modified_bionic = bionic

# Process in reverse order to preserve offsets
for name, data in sorted(extracted.items(), key=lambda x: -x[1]['start']):
    placeholder = placeholder_template.format(context=data['context'], name=name)
    modified_bionic = modified_bionic[:data['start']] + placeholder + modified_bionic[data['end']:]

# Add rule loading directive at the top
directive = """## Rule Loading Directive

This file uses modular rule files. Context-specific sections are extracted to `rules/*.md`.
When a context keyword is active, the corresponding rule files are loaded automatically.

**How rules work:**
1. The `.bionic_rules_manifest.txt` file maps context keywords to rule files
2. When processing a task, identify the active context(s) from the manifest
3. Load each rule file specified for that context before proceeding
4. Rule files contain platform-specific, shell-specific, or workflow-specific rules

**To regenerate rule files:** Run `utils/bin/sync-bionic-rules.sh` (Linux) or `.zsh` (macOS).
"""

modified_bionic = directive + modified_bionic

# Write modified .bionic back to file
with open(bionic_path, 'w') as f:
    f.write(modified_bionic)

print(f"\nModified .bionic: {len(modified_bionic)} bytes")
print(f"Size reduction: {(1 - len(modified_bionic)/len(bionic))*100:.1f}%")

# Count placeholders with FIXED regex (allow hyphens)
placeholder_pattern = r'<!-- RULES-LOAD: ([\w-]+) -> rules/([\w-]+\.md) -->'
placeholders = list(re.finditer(placeholder_pattern, modified_bionic))
print(f"Placeholders: {len(placeholders)}")

# Verify reconstruction - replace placeholders with rule file content
reconstructed = modified_bionic

for m in reversed(placeholders):
    rule_file_with_ext = m.group(2)  # e.g., 'macos-containers.md'
    rule_file = rule_file_with_ext[:-3]  # Strip '.md' -> 'macos-containers'
    
    if rule_file in extracted:
        content = extracted[rule_file]['text']
        reconstructed = reconstructed[:m.start()] + content + reconstructed[m.end():]

# Remove directive from reconstructed to compare with original
reconstructed_without_directive = reconstructed[len(directive):]

if bionic == reconstructed_without_directive:
    print("OK: Reconstruction matches original exactly!")
else:
    print("ERROR: Reconstruction does not match original!")

# Compute SHA-256 hash of modified .bionic
sha256 = hashlib.sha256(modified_bionic.encode()).hexdigest()

# Generate manifest
manifest_content = f"""# .bionic Rules Manifest
# Auto-generated by sync-bionic-rules script
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# .bionic SHA-256: {sha256}

# Context -> Rule File Mapping
# When a context keyword is active, load the corresponding rule files.
# Composite contexts (space-separated) load all matching rules.

# macOS native builds and local testing
macos -> rules/macos-containers.md, rules/container-commands-macos.md

# FreeBSD 14 remote builds via SSH (tcsh shell)
freebsd14 -> rules/freebsd-shell.md, rules/tcsh-syntax.md, rules/freebsd-ssh.md

# FreeBSD 14 + macOS local testing of FreeBSD Makefiles
macos freebsd14 -> rules/macos-containers.md, rules/freebsd-shell.md, rules/tcsh-syntax.md

# Arch Linux (Linux-hosts-only, rolling release)
archlinux -> rules/archlinux-containers.md, rules/archlinux-pinning.md

# SSH remote transfer and build workflow (all platforms)
ssh-transfer -> rules/ssh-transfer.md

# Container operations (Linux distros on macOS host, Linux hosts)
container -> rules/container-rules.md, rules/container-naming.md, rules/container-dockerfile.md

# Container + SSH combined (FreeBSD 14 remote via container-like workflow)
container ssh-transfer -> rules/container-rules.md, rules/container-naming.md, rules/container-dockerfile.md, rules/ssh-transfer.md

# README updates (mermaid diagram validation)
readme-update -> rules/mermaid-validation.md
"""

manifest_path = os.path.join(os.path.dirname(bionic_path), '.bionic_rules_manifest.txt')
with open(manifest_path, 'w') as f:
    f.write(manifest_content)

print(f"  Manifest written to {manifest_path}")

# Update CLAUDE.md from .bionic
claude_md_path = os.path.join(os.path.dirname(bionic_path), 'CLAUDE.md')
with open(claude_md_path, 'w') as f:
    f.write(modified_bionic)

print(f"  CLAUDE.md updated from .bionic")
PYTHON_SCRIPT

echo ""
echo "=== sync-bionic-rules complete ==="
