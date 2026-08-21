#!/usr/bin/env zsh
# generate_test_data.zsh - Generate zig-zag pattern test data files for Ringbuffer testing
# Usage: generate_test_data.zsh [-l lines] [output_file]

set -euo pipefail

# Version check (Zsh 5.8+)
major=${ZSH_VERSION%%.*}
minor=${ZSH_VERSION#*.}
if (( major < 5 || (major == 5 && minor < 8) )); then
    echo "ERROR: Zsh version 5.8 or higher is required (current: $ZSH_VERSION)" >&2
    exit 1
fi

# Defaults
lines=10
output_file=""

# Parse options
while getopts "l:h" opt; do
    case $opt in
        l) lines=$OPTARG ;;
        h) echo "Usage: generate_test_data.zsh [-l lines] [output_file]"
           echo "  -l lines    Number of lines to generate (default: 10)"
           echo "  -h          Display this help message"
           exit 0 ;;
        *) echo "Usage: generate_test_data.zsh [-l lines] [output_file]" >&2; exit 1 ;;
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
    
    # Format 4-digit sequence number (Zsh uses 1-based indexing)
    if (( n < 10 )); then
        prefix="000${n} "
    elif (( n < 100 )); then
        prefix="00${n} "
    elif (( n < 1000 )); then
        prefix="0${n} "
    else
        prefix="${n} "
    fi
    
    local suffix=$(printf "%04d" "$n")
    
    if (( n == 1 )); then
        echo "${prefix}${template} ${suffix}"
        return
    fi
    
    # Calculate zig-zag position (Zsh uses 1-based indexing for strings)
    local idx=$(( n - 2 ))
    local cycle=$(( 2 * (L - 1) ))
    local off=$(( idx % cycle ))
    local i
    
    if (( off < L - 1 )); then
        i=$(( off + 2 ))  # Convert to 1-based for Zsh string indexing
    else
        i=$(( cycle - off + 2 ))
    fi
    
    # Replace character at position i with space (1-based index in Zsh)
    local chars="${template}"
    local prefix_part="${chars[1:$((i-1))]}"
    local suffix_part="${chars[$((i+1)),$L]}"
    
    echo "${prefix}${prefix_part} ${suffix_part} ${suffix}"
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
