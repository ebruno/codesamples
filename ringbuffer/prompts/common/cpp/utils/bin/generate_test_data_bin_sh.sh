#!/usr/bin/env sh
# generate_test_data_bin_sh.sh - Generate zig-zag pattern test data files for Ringbuffer testing
# Usage: generate_test_data_bin_sh.sh [-l lines] [output_file]
#
# NOTE: POSIX sh has no built-in string manipulation or version variable.
# External commands (expr, cut) are used as a necessary compromise — the spec's
# "built-ins only" rule cannot be met in pure POSIX sh.

set -e

# Defaults
lines=10
output_file=""

# Parse options
while [ $# -gt 0 ]; do
    case "$1" in
        -l) lines="$2"; shift 2 ;;
        -h) echo "Usage: generate_test_data_bin_sh.sh [-l lines] [output_file]"
            echo "  -l lines    Number of lines to generate (default: 10)"
            echo "  -h          Display this help message"
            exit 0 ;;
        *) if [ -n "$output_file" ]; then
               echo "ERROR: Multiple output files specified" >&2
               exit 1
           fi
           output_file="$1"; shift ;;
    esac
done

# Template string (48 characters) — authoritative ground truth
template="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>""
L=${#template}

generate_line() {
    n=$1
    prefix=""
    
    # Format 4-digit sequence number
    if [ "$n" -lt 10 ]; then
        prefix="000${n} "
    elif [ "$n" -lt 100 ]; then
        prefix="00${n} "
    elif [ "$n" -lt 1000 ]; then
        prefix="0${n} "
    else
        prefix="${n} "
    fi
    
    suffix=$(printf "%04d" "$n")
    
    if [ "$n" -eq 1 ]; then
        echo "${prefix}${template} ${suffix}"
        return
    fi
    
    # Calculate zig-zag position (Bourne shell has no arrays, use string manipulation)
    idx=$(( n - 2 ))
    cycle=$(( 2 * (L - 1) ))
    off=$(( idx % cycle ))
    
    if [ "$off" -lt "$((L - 1))" ]; then
        i=$(( off + 2 ))  # Convert to 1-based for string indexing
    else
        i=$(( cycle - off + 2 ))
    fi
    
    # Replace character at position i with space (1-based index)
    prefix_part="${template:0:$((i-2))}"
    suffix_part="${template:$i}"
    echo "${prefix}${prefix_part} ${suffix_part} ${suffix}"
}

# Generate output — truncate first, then append per line (avoids error messages going to data file)
if [ -n "$output_file" ]; then
    > "$output_file"  # Truncate file first
    n=1
    while [ "$n" -le "$lines" ]; do
        generate_line "$n" >> "$output_file"
        n=$(( n + 1 ))
    done
else
    n=1
    while [ "$n" -le "$lines" ]; do
        generate_line "$n"
        n=$(( n + 1 ))
    done
fi
