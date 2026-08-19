#!/usr/bin/env bash
# update.sh — Regenerates LLM knowledge package from source headers
#
# Usage: ./knowledge/update.sh [BUILD_ID]
#   BUILD_ID is a manual parameter — if omitted, current value is preserved (no auto-increment)
#   MAJOR/MINOR/SUBVERSION are auto-detected from src/*/cpp/version.mk
#
# Examples:
#   ./knowledge/update.sh 2          # Sets BUILD_ID to 2
#   ./knowledge/update.sh            # Preserves current BUILD_ID

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Read version from source (Makefile-style syntax, not shell) ---
VERSION_MK="$PROJECT_ROOT/src/macos/cpp/version.mk"
if [[ ! -f "$VERSION_MK" ]]; then
    echo "ERROR: $VERSION_MK not found. Run this from the project root." >&2
    exit 1
fi

# Parse version.mk (uses Makefile syntax: VAR = value, not shell export)
# Bash builtins only — no grep/awk
while IFS= read -r line; do
    case "$line" in
        MAJOR\ *) MAJOR="${line#MAJOR }" ;;
        MINOR\ *) MINOR="${line#MINOR }" ;;
        SUBVERSION\ *) SUBVERSION="${line#SUBVERSION }" ;;
        BUILD_ID\ *) CURRENT_BUILD_ID="${line#BUILD_ID }" ;;
    esac
done < "$VERSION_MK"
CURRENT_BUILD_ID="${CURRENT_BUILD_ID:-0}"

# --- Accept BUILD_ID as argument, or preserve current ---
if [[ $# -ge 1 ]]; then
    NEW_BUILD_ID="$1"
else
    NEW_BUILD_ID="$CURRENT_BUILD_ID"
fi

FULL_VERSION="${MAJOR}.${MINOR}.${SUBVERSION}-build-${NEW_BUILD_ID}"
echo "=== Regenerating LLM Knowledge Package ==="
echo "Version: $FULL_VERSION (MAJOR=$MAJOR, MINOR=$MINOR, SUBVERSION=$SUBVERSION, BUILD_ID=$NEW_BUILD_ID)"

# --- Update manifest.json ---
echo "Updating knowledge/manifest.json..."
cat > "$SCRIPT_DIR/manifest.json" <<EOF
{
  "name": "swtr-ringbuffer-knowledge",
  "version": "$FULL_VERSION",
  "ringbuffer_version": {
    "major": $MAJOR,
    "minor": $MINOR,
    "subversion": $SUBVERSION,
    "build_id": $NEW_BUILD_ID
  },
  "languages": ["cpp", "java", "python"],
  "compatible_with": [
    "qwen3.6-35b-a3b",
    "qwen2.5-14b-instruct",
    "qwen2.5-7b-instruct"
  ],
  "distribution": {
    "system_prompt": "Modelfile — wraps any Qwen model, instant to use",
    "fine_tuned": "swtr-ringbuffer-qwen2.5-14b-v${MAJOR}.${MINOR}.${SUBVERSION}-build-${NEW_BUILD_ID}.gguf — QLoRA fine-tuned, zero-context inference"
  },
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "files": {}
}
EOF

# --- Update system-prompt.md version string (bash parameter expansion, no sed) ---
echo "Updating knowledge/system-prompt.md..."
_file_content=$(<"$SCRIPT_DIR/system-prompt.md")
_file_content="${_file_content//Version: [0-9.]*-build-[0-9]*/Version: $FULL_VERSION}"
# The above won't work with regex in bash, so use a line-by-line approach
_tmpfile=$(mktemp)
while IFS= read -r line; do
    if [[ "$line" =~ ^Version:\ [0-9.]*-build-[0-9]+ ]]; then
        line="Version: $FULL_VERSION"
    fi
    printf '%s\n' "$line"
done < "$SCRIPT_DIR/system-prompt.md" > "$_tmpfile"
# Remove trailing newline if original didn't have one
if [[ -s "$SCRIPT_DIR/system-prompt.md" ]] && [[ "$(tail -c 1 "$SCRIPT_DIR/system-prompt.md" | wc -l)" -eq 0 ]]; then
    truncate -s -1 "$_tmpfile"
fi
mv "$_tmpfile" "$SCRIPT_DIR/system-prompt.md"

# --- Update Modelfile version string (bash parameter expansion, no sed) ---
echo "Updating knowledge/Modelfile..."
_tmpfile=$(mktemp)
while IFS= read -r line; do
    if [[ "$line" =~ ^v[0-9.]*-build-[0-9]+ ]]; then
        line="v$FULL_VERSION"
    fi
    if [[ "$line" =~ ^Version:\ [0-9.]*-build-[0-9]+ ]]; then
        line="Version: $FULL_VERSION"
    fi
    printf '%s\n' "$line"
done < "$SCRIPT_DIR/Modelfile" > "$_tmpfile"
if [[ -s "$SCRIPT_DIR/Modelfile" ]] && [[ "$(tail -c 1 "$SCRIPT_DIR/Modelfile" | wc -l)" -eq 0 ]]; then
    truncate -s -1 "$_tmpfile"
fi
mv "$_tmpfile" "$SCRIPT_DIR/Modelfile"

# --- Update .gen_state.json ---
echo "Updating knowledge/.gen_state.json..."
cat > "$SCRIPT_DIR/.gen_state.json" <<EOF
{
  "version": "$FULL_VERSION",
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source_version": {
    "major": $MAJOR,
    "minor": $MINOR,
    "subversion": $SUBVERSION
  },
  "files": {}
}
EOF

# --- Compute SHA-256 checksums for all knowledge files ---
echo "Computing file checksums..."
CHECKSUMS=""
for f in "$SCRIPT_DIR"/Modelfile "$SCRIPT_DIR"/system-prompt.md \
         "$SCRIPT_DIR"/api-reference/*.md \
         "$SCRIPT_DIR"/examples/*.* \
         "$SCRIPT_DIR"/patterns/*.md; do
    if [[ -f "$f" ]]; then
        HASH=$(sha256sum "$f")
        HASH="${HASH%% *}"  # Extract hash (bash builtin, no awk)
        REL_PATH="${f#$SCRIPT_DIR/}"
        CHECKSUMS="$CHECKSUMS\n    \"$REL_PATH\": \"$HASH\""
    fi
done

# Update manifest.json with checksums
if command -v python3 &>/dev/null; then
    python3 -c "
import json, hashlib, os

script_dir = '$SCRIPT_DIR'
manifest_path = os.path.join(script_dir, 'manifest.json')

with open(manifest_path) as f:
    manifest = json.load(f)

files = {}
for root, dirs, filenames in os.walk(script_dir):
    for fn in filenames:
        if fn.endswith('.json') or fn == '.gen_state.json':
            continue
        full_path = os.path.join(root, fn)
        rel_path = os.path.relpath(full_path, script_dir)
        with open(full_path, 'rb') as f:
            files[rel_path] = hashlib.sha256(f.read()).hexdigest()

manifest['files'] = files
with open(manifest_path, 'w') as f:
    json.dump(manifest, f, indent=2)
    f.write('\n')
"
fi

echo ""
echo "=== Done ==="
echo "Knowledge package updated to version: $FULL_VERSION"
echo ""
echo "Next steps:"
echo "  1. Review generated files in knowledge/"
echo "  2. Run ./knowledge/build_model.sh to fine-tune (optional)"
echo "  3. Commit and push to GitLab"
