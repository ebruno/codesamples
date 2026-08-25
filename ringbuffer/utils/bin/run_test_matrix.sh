#!/usr/bin/env bash
# Run test matrix for all supported compilers (from registry)
# Usage: run_test_matrix.sh <os> [lang]
# Reads config/toolchains.json to determine which toolchains to test

set -e

OS_NAME="${1:?Usage: run_test_matrix.sh <os> [lang]}"
LANG="${2:-cpp}"

# Resolve registry path relative to workspace root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../../../" 2>/dev/null && pwd || echo "$SCRIPT_DIR")"
REGISTRY="$WORKSPACE_ROOT/config/toolchains.json"

if [ ! -f "$REGISTRY" ]; then
    echo "ERROR: Registry not found at $REGISTRY" >&2
    exit 1
fi

# ── Registry helper: list ALL compilers for <os> + <lang> (to stderr) ──
list_all_compilers() {
    local os="$1" lang="${2:-cpp}"

    if command -v jq &>/dev/null; then
        jq -r ".[\"${lang}\"][\"${os}\"][] | \"  \\(.name) (min_version: \\(.min_version)) - \\(if .supported then \"SUPPORTED\" else \"UNSUPPORTED: \\(.description)\" end)\"" "$REGISTRY" 2>/dev/null >&2
    elif command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('${REGISTRY}') as f:
    data = json.load(f)
for c in data.get('${lang}', {}).get('${os}', []):
    status = 'SUPPORTED' if c.get('supported') else f\"UNSUPPORTED: {c.get('description', 'unknown')}\"
    print(f'  {c[\"name\"]} (min_version: {c.get(\"min_version\", \"?\")}) - {status}')
" 2>/dev/null >&2
    else
        echo "ERROR: Neither jq nor python3 available to read registry" >&2
    fi
}

# Read supported compilers from registry for this OS + language
COMPILERS=$(python3 -c "
import json, sys
reg = json.load(open('$REGISTRY'))
compilers = reg.get('$LANG', {}).get('$OS_NAME', [])
print(' '.join(c['name'] for c in compilers if c.get('supported')))
" 2>/dev/null)

if [ -z "$COMPILERS" ]; then
    echo "ERROR: No supported compilers found for $LANG/$OS_NAME in registry" >&2
    exit 1
fi

echo "Compilers for $LANG/$OS_NAME: $COMPILERS"

# List all compilers (supported and unsupported) to stderr
echo "Available compilers for $OS_NAME/$LANG:"
list_all_compilers "$OS_NAME" "$LANG"

# Loop over each compiler
for CXX in $COMPILERS; do
    echo "========================================"
    echo "Testing with $CXX ($LANG/$OS_NAME)"
    echo "========================================"

    # Clean build artifacts for this compiler
    make clean

    # Build and verify with this compiler
    make verify-single CXX="$CXX"

    echo "Completed $CXX — status: PASS"
done

echo ""
echo "All compilers passed for $LANG/$OS_NAME"
