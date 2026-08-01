#!/usr/bin/env bash

# Default values
lines=10
output_file=""

# Usage function
usage() {
    echo "Usage: $(basename $0) [-l lines] [output_file]"
    echo "  -l lines: Number of lines to generate. Defaults to 10."
    echo "  -h: Display usage information."
    exit 1
}

# Parse options
while getopts "l:h" opt; do
    case $opt in
        l) lines=$OPTARG ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

# The remaining argument is the output file
if [[ -n $1 ]]; then
    output_file=$1
fi

# Template and payload
payload="ABCEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
payload_len=${#payload}
cycle=92

# Function to generate a single line
generate_line() {
    local n=$1
    local seq_num=$(printf "%04d" $n)
    
    local p=-1
    if [[ $n -gt 1 ]]; then
        local m=$(( (n - 2) % cycle ))
        if [[ $m -lt 46 ]]; then
            p=$((m + 1))
        else
            p=$((cycle - 1 - m))
        fi
    fi
    
    if [[ $p -ge 0 && $p -lt $payload_len ]]; then
        local left=${payload:0:p}
        local right=${payload:p+1}
        echo "${seq_num} ${left} ${right} ${seq_num}"
    else
        echo "${seq_num} ${payload} ${seq_num}"
    fi
}

# Generate lines
if [[ -n $output_file ]]; then
    : > $output_file
    for (( i=1; i<=lines; i++ )); do
        generate_line $i >> $output_file
    done
else
    for (( i=1; i<=lines; i++ )); do
        generate_line $i
    done
fi
