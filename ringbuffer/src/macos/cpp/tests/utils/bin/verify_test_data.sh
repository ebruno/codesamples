#!/usr/bin/env bash

# verify_test_data.sh
# Purpose: Programmatically validate the strict line format of test data files.
# Usage: verify_test_data.sh <input_file>

if [[ -z "$1" ]]; then
    echo "Usage: verify_test_data.sh <input_file>"
    exit 1
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
    echo "Error: File $FILE not found."
    exit 1
fi

# Use awk to validate every line
# - Length must be 57
# - Char 5 must be space
# - Char 54 must be space
# - Chars 1-4 must be digits
# - Chars 55-58 must be digits
awk '
{
    if (length($0) != 57) {
        printf "Line %d: Invalid length (%d), expected 57\n", NR, length($0)
        exit 1
    }
    if (substr($0, 5, 1) != " ") {
        printf "Line %d: Character 5 must be a space\n", NR
        exit 1
    }
    if (substr($0, 54, 1) != " ") {
        printf "Line %d: Character 54 must be a space\n", NR
        exit 1
    }
    if (substr($0, 1, 4) !~ /^[0-9]{4}$/) {
        printf "Line %d: Characters 1-4 must be digits\n", NR
        exit 1
    }
    if (substr($0, 55, 4) !~ /^[0-9]{4}$/) {
        printf "Line %d: Characters 55-58 must be digits\n", NR
        exit 1
    }
}
END {
    if (NR == 0) {
        printf "Error: File is empty\n"
        exit 1
    }
}
' "$FILE"

if [[ $? -eq 0 ]]; then
    echo "Validation PASSED for $FILE"
    exit 0
else
    echo "Validation FAILED for $FILE"
    exit 1
fi
