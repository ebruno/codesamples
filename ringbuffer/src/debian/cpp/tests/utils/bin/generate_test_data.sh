#!/usr/bin/env bash
# generate_test_data.sh - Generate zig-zag pattern test data files for Ringbuffer testing
# Usage: generate_test_data.sh [-l lines] [output_file]

set -euo pipefail

# Version check (Bash 5.0+)
major=${BASH_VERSION%%.*}
minor=${BASH_VERSION#*.}
minor=${minor%%.*}  # Extract only the numeric minor version (handles macOS '3.2.57(1)-release')
if (( major < 5 || (major == 5 && minor < 0) )); then
    echo "ERROR: Bash version 5.0 or higher is required (current: $BASH_VERSION)" >&2
    exit 1
fi

# Defaults
lines=10
output_file=""

# Parse options
while getopts "l:h" opt; do
    case $opt in
        l) lines=$OPTARG ;;
        h) echo "Usage: generate_test_data.sh [-l lines] [output_file]"
           echo "  -l lines    Number of lines to generate (default: 10)"
           echo "  -h          Display this help message"
           exit 0 ;;
        *) echo "Usage: generate_test_data.sh [-l lines] [output_file]" >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -gt 0 ]]; then
    output_file=$1
fi

# Template string (48 characters) — authoritative ground truth
template="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
L=${#template}

generate_line() {
    local n=$1
    local prefix suffix
    
    # Format 4-digit sequence number
    if (( n < 10 )); then
        prefix="000${n} "
    elif (( n < 100 )); then
        prefix="00${n} "
    elif (( n < 1000 )); then
        prefix="0${n} "
    else
        prefix="${n} "
    fi
    
    if (( n == 1 )); then
        echo "${prefix}${template} ${prefix}"
        return
    fi
    
    # Calculate zig-zag position
    local idx=$(( n - 2 ))
    local cycle=$(( 2 * (L - 1) ))
    local off=$(( idx % cycle ))
    local i
    
    if (( off < L - 1 )); then
        i=$(( off + 1 ))
    else
        i=$(( cycle - off ))
    fi
    
    # Replace character at position i with space (0-based index)
    local chars=()
    for (( c=0; c<L; c++ )); do
        chars+=("${template:$c:1}")
    done
    chars[$i]=" "
    
    local modified=""
    for (( c=0; c<L; c++ )); do
        modified+="${chars[$c]}"
    done
    
    echo "${prefix}${modified} ${prefix}"
}

# Generate output — truncate first, then append per line (avoids error messages going to data file)
if [[ -n "$output_file" ]]; then
    > "$output_file"  # Truncate file first
    for (( n=1; n<=lines; n++ )); do
        generate_line "$n" >> "$output_file"
    done
else
    for (( n=1; n<=lines; n++ )); do
        generate_line "$n"
    done
fi
