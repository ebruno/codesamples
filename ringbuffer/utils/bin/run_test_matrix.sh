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

# Read compilers from registry for this OS + language
COMPILERS=$(python3 -c "
import json, sys
reg = json.load(open('$REGISTRY'))
compilers = reg.get('$LANG', {}).get('$OS_NAME', [])
print(' '.join(compilers))
" 2>/dev/null)

if [ -z "$COMPILERS" ]; then
    echo "ERROR: No compilers defined for $LANG/$OS_NAME in registry" >&2
    exit 1
fi

echo "Compilers for $LANG/$OS_NAME: $COMPILERS"

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
