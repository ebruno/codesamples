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

S_CHARS="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
S_LEN=${#S_CHARS}

generate_line() {
    local line_num=$1
    local seq=$(printf "%04d" "$line_num")
    
    local space_pos=-1
    if (( line_num > 1 )); then
        local offset=$((line_num - 2))
        if (( (offset % (2 * S_LEN)) < S_LEN )); then
            space_L_POS=$((offset % S_LEN))
        else
            space_L_POS=$((2 * S_LEN - 1 - (offset % (2 * S_LEN))))
        fi
        space_pos=$space_L_POS
    fi

    if (( space_pos >= 0 && space_pos < S_LEN )); then
        local part1="${S_CHARS:0:space_pos}"
        local part2="${S_CHARS:space_pos+1}"
        echo "$seq $part1 $part2 $seq"
    else
        echo "$seq $S_CHARS $seq"
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
