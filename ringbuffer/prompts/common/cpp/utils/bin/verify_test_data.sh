#!/usr/bin/env bash

# Version Check
major=${BASH_VERSINFO[0]}
if (( major < 5 )); then
    echo "Error: Bash version 5.0 or higher is required." >&2
    exit 1
fi

# verify_test_data.sh
# Purpose: Programmatically validate the strict line format of test data files.
# Usage: verify_test_data.sh <input_file>

if [[ -z "$1" ]]; then
    echo "Usage: $(basename "$0") <input_file>"
    exit 1
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
    echo "Error: File $FILE not found."
    exit 1
fi

pattern='^[0-9]{4} .{48} [0-9]{4}$'
line_num=0

while IFS= read -r line || [[ -n "$line" ]]; do
    ((line_num++))
    
    # Skip empty lines (e.g. trailing newline)
    [[ -z "$line" ]] && continue
    
    if [[ ${#line} -ne 58 ]]; then
        echo "Line $line_num: Invalid length (${#line}), expected 58"
        exit 1
    fi
    
    if [[ ! "$line" =~ $pattern ]]; then
        echo "Line $line_num: Format validation FAILED"
        exit 1
    fi
done < "$FILE"

if (( line_num == 0 )); then
    echo "Error: File is empty"
    exit 1
fi

echo "Validation PASSED for $FILE"
exit 0
