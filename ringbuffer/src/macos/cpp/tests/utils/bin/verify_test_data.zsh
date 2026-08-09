#!/usr/bin/env zsh
if [[ -z $1 ]]; then echo "Usage: verify_test_data.zsh [file]"; exit 1; fi
file=$1
line_count=$(wc -l < "$file")
while IFS= read -r line; do
    if [[ ${#line} -ne 57 ]]; then echo "Error: Length ${#line}"; exit 1; fi
    if [[ ! "$line" =~ ^[0-9]{4}\ .{47}\ [0-9]{4}$ ]]; then echo "Error: Format"; exit 1; fi
done < "$file"
exit 0
