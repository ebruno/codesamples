#!/usr/bin/env bash

# generate_test_data.sh
# Purpose: Generate test data with a zig-zag space pattern for Linux/Bash.
# Usage: generate_test_data.sh [-l lines] [output_file]

usage() {
    echo "Usage: generate_test_data.sh [-l lines] [output_file]"
    echo "Options:"
    echo "  -l lines    Number of lines to generate. Defaults to 10."
    echo "  -h          Display usage information."
    exit 1
}

lines=10
output_file=""

while getopts "l:h" opt; do
    case $opt in
        l) lines=$OPTARG ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

if [[ -n $1 ]]; then
    output_file=$1
fi

template="ABCEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
len=${#template}

if [[ -n $output_file ]]; then
    exec > "$output_file"
fi

for (( i=1; i<=lines; i++ )); do
    printf "%04d " $i
    if (( i > 1 )); then
        period=$(( 2 * (len - 2) ))
        rel_pos=$(( (i - 2) % period ))
        
        if (( rel_pos <= len - 2 )); then
            pos=$(( rel_pos + 2 ))
        else
            pos=$(( period - rel_pos + 2 ))
        fi
        
        prefix=${template:0:pos-1}
        suffix=${template:pos}
        printf "%s %s " "$prefix" "$suffix"
    else
        printf "%s " "$template"
    fi
    printf "%04d\n" $i
done
