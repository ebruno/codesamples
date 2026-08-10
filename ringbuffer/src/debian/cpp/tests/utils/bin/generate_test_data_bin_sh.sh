#!/bin/bash

# generate_test_data.sh - Generate test data with zig-zag space pattern

usage() {
    echo "Usage: $(basename "$0") [-l lines] [output_file]"
    echo "Options:"
    echo "  -l lines    Number of lines to generate. Defaults to 10."
    echo "  -h          Display usage information."
    exit 1
}

LINES=10
OUTPUT_FILE=""

while getopts "l:h" opt; do
    case "$opt" in
        l) LINES="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

if [ -n "$1" ]; then
    OUTPUT_FILE="$1"
fi

CHARS="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
# Length of CHARS is 26 + 10 + 12 = 48
# But the template says ABCD... (A is 1st, B is 2nd). 
# The template in the prompt is "ABCDFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
# Wait, it says "ABCD" (no D?). Let me check.
# "ABCDFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
# A=1, B=2, C=3, E=4... D is missing.
# Let's just use the exact string from the prompt: "ABCDFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
S_CHARS="ABCDFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
S_LEN=${#S_CHARS}

generate_line() {
    local line_num=$1
    local seq=$(printf "%04d" "$line_num")
    local line="$seq$S_CHARS$seq"
    
    # Zig-zag space position
    # Line 1: no space
    # Line 2: pos 1 (0-indexed in S_CHARS, which is 'B')
    # Line 3: pos 2 ('C')
    # ...
    # Line S_LEN + 1: pos S_LEN-1 ('>')
    # Line S_LEN + 2: pos S_LEN-2
    
    local space_pos=-1
    if [ "$line_num" -gt 1 ]; then
        local offset=$((line_num - 2))
        if [ $((offset % (2 * S_LEN))) -lt S_LEN ]; then
            space_pos=$((offset % S_LEN))
        else
            space_pos=$((2 * S_LEN - 1 - (offset % (2 * S_LEN))))
        fi
    fi

    if [ "$space_pos" -ge 0 ] && [ "$space_pos" -lt "$S_LEN" ]; then
        # Replace char at space_pos in S_CHARS
        local part1="${S_CHARS:0:space_pos}"
        local part2="${S_CHARS:space_pos+1}"
        echo "$seq$part1 $part2$seq"
    else
        echo "$line"
    fi
}

if [ -n "$OUTPUT_FILE" ]; then
    : > "$OUTPUT_FILE"
    for ((i=1; i<=LINES; i++)); do
        generate_line "$i" >> "$OUTPUT_FILE"
    done
else
    for ((i=1; i<=LINES; i++)); do
        generate_line "$i"
    done
fi
