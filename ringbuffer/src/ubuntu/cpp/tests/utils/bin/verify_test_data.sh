#!/usr/bin/env bash
# verify_test_data.sh - Validate test data files for Ringbuffer testing
# Usage: verify_test_data.sh [file1] [file2] ...

set -euo pipefail

# Version check (Bash 5.0+)
major=${BASH_VERSION%%.*}
minor=${BASH_VERSION#*.}
minor=${minor%%.*}  # Extract only the numeric minor version (handles macOS '3.2.57(1)-release')
if (( major < 5 || (major == 5 && minor < 0) )); then
    echo "ERROR: Bash version 5.0 or higher is required (current: $BASH_VERSION)" >&2
    exit 1
fi

if [[ $# -eq 0 ]]; then
    echo "Usage: verify_test_data.sh [file1] [file2] ..." >&2
    exit 1
fi

errors=0

for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        echo "ERROR: File not found: $file" >&2
        (( errors++ )) || true
        continue
    fi
    
    line_num=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        (( line_num++ )) || true
        
        # Check line length (must be exactly 58 characters: 4-digit prefix + space + 48-char payload + space + 4-digit suffix)
        len=${#line}
        if (( len != 58 )); then
            echo "ERROR: $file line $line_num: length is $len, expected 58" >&2
            (( errors++ )) || true
            continue
        fi
        
        # Check prefix: characters 1-4 are digits, character 5 is space
        prefix="${line:0:4}"
        if [[ ! "$prefix" =~ ^[0-9]{4}$ ]]; then
            echo "ERROR: $file line $line_num: prefix '$prefix' is not 4 digits" >&2
            (( errors++ )) || true
        fi
        
        if [[ "${line:4:1}" != " " ]]; then
            echo "ERROR: $file line $line_num: character 5 is not a space" >&2
            (( errors++ )) || true
        fi
        
        # Check suffix: character 54 is space, characters 55-58 are digits
        if [[ "${line:53:1}" != " " ]]; then
            echo "ERROR: $file line $line_num: character 54 is not a space" >&2
            (( errors++ )) || true
        fi
        
        suffix="${line:54:4}"
        if [[ ! "$suffix" =~ ^[0-9]{4}$ ]]; then
            echo "ERROR: $file line $line_num: suffix '$suffix' is not 4 digits" >&2
            (( errors++ )) || true
        fi
        
    done < "$file"
    
    if (( line_num == 0 )); then
        echo "ERROR: $file is empty" >&2
        (( errors++ )) || true
    fi
    
done

if (( errors == 0 )); then
    echo "PASS: All files validated successfully"
    exit 0
else
    echo "FAIL: $errors error(s) found" >&2
    exit 1
fi
