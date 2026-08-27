#!/usr/bin/env bash
# Detect available C++ compilers in priority order
# Usage: detect_compilers.sh [lang]  (default: cpp)

LANG="${1:-cpp}"
COMPILERS=""

case "$LANG" in
    cpp)
        COMPILERS="g++ clang++ c++"
        ;;
    c)
        COMPILERS="gcc cc clang"
        ;;
    java)
        COMPILERS="javac"
        ;;
    *)
        echo "ERROR: Unknown language $LANG" >&2
        exit 1
        ;;
esac

for cc in $COMPILERS; do
    if command -v "$cc" >/dev/null 2>&1 && ! "$cc" --version 2>/dev/null | grep -q "clang"; then
        echo "$cc"
    fi
done

# If no non-clang compiler found, check for clang
if [ -z "$COMPILER_LIST" ]; then
    for cc in $COMPILERS; do
        if command -v "$cc" >/dev/null 2>&1; then
            echo "$cc"
        fi
    done
fi
