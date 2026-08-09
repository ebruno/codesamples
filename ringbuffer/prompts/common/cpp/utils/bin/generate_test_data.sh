#!/usr/bin/env bash

# Version Check
if (( ${BASH_VERSINFO[0]} < 5 )); then
    echo "Error: Bash version 5.0 or higher is required." >&2
    exit 1
fi

usage() {
    echo "Usage: $(basename $0) [-l lines] [output_file]"
    echo "Options:"
    echo "  -l lines    Number of lines to generate. Defaults to 10."
    echo "  -h          Display usage information."
    exit 0
}

# Defaults
lines=10
output_file=""

# Parse Arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l)
            if [[ -n $2 && $2 =~ ^[0-9]+$ ]]; then
                lines=$2
                shift 2
            else
                echo "Error: -l requires a numeric argument." >&2
                exit 1
            fi
            ;;
        -h)
            usage
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            usage
            ;;
        *)
            output_file=$1
            shift
            ;;
    esac
done

# Template and Constraints
# Prefix: 4 digits + space (5 chars)
# Internal: 47 chars
# Suffix: space + 4 digits (5 chars)
# Total: 57 chars
template="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>" # 48 chars

L=${#template}
cycle=$(( 2 * (L - 1) ))

# Output handling: Use > to overwrite if output_file is specified
if [[ -n $output_file ]]; then
    exec > "$output_file"
fi

for (( n=1; n<=lines; n++ )); do
    # Sequence number (4 digits)
    seq=$(printf "%04d" $n)
    
    # Internal content
    content=$template
    if (( n > 1 )); then
        idx=$(( n - 2 ))
        off=$(( idx % cycle ))
        if (( off < L - 1 )); then
            i=$(( off + 1 ))
        else
            i=$(( cycle - off ))
        fi
        # Bash string manipulation to replace character at index i (0-based)
        content="${content:0:i} ${content:i+1}"
    fi
    
    echo "${seq} ${content} ${seq}"
done
