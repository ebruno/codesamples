#!/usr/bin/env sh

# generate_test_data_bin_sh.sh
# Purpose: Generate test data with a zig-zag space pattern for Bourne shell.
# Usage: generate_test_data_bin_sh.sh [-l lines] [output_file]

usage() {
    echo "Usage: generate_test_data_bin_sh.sh [-l lines] [output_file]"
    echo "Options:"
    echo "  -l lines    Number of lines to generate. Defaults to 10."
    echo "  -h          Display usage information."
    exit 1
}

lines=10
output_file=""

while [ $# -gt 0 ]; do
    case "$1" in
        -l) lines="$2"; shift 2 ;;
        -h) usage ;;
        -*) usage ;;
        *) output_file="$1"; shift ;;
    esac
done

template="ABCDFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
len=$(echo "$template" | wc -c)
len=$(expr $len - 1)

if [ -n "$output_file" ]; then
    exec > "$output_file"
fi

i=1
while [ $i -le $lines ]; do
    seq=$(printf "%04d" $i)
    if [ $i -gt 1 ]; then
        period=$(expr 2 \* \( $len - 2 \))
        rel_pos=$(expr \( $i - 2 \) % $period)
        
        if [ $rel_pos -le $(expr $len - 2) ]; then
            pos=$(expr $rel_pos + 1)
        else
            pos=$(expr $period - $rel_pos + 1)
        fi
        
        prefix=$(echo "$template" | cut -c 1-$(expr $pos - 1))
        suffix=$(echo "$template" | cut -c $(expr $pos + 1)-)
        printf "%s %s %s %s\n" "$seq" "$prefix" "$suffix" "$seq"
    else
        printf "%s %s %s\n" "$seq" "$template" "$seq"
    fi
    i=$(expr $i + 1)
done
