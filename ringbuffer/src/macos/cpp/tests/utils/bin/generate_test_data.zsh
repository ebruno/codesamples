#!/usr/bin/env zsh
lines=10
output_file=""
while getopts "l:h" opt; do
    case $opt in
        l) lines=$OPTARG ;;
        h) echo "Usage: generate_test_data.zsh [-l lines] [output_file]"; exit 1 ;;
        *) exit 1 ;;
    esac
done
shift $((OPTIND-1))
if [[ -n $1 ]]; then output_file=$1; fi
template="ABCEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
L=${#template}
for (( n=1; n<=lines; n++ )); do
    seq=$(printf "%04d" $n)
    content=$template
    if (( n > 1 )); then
        idx=$(( n - 2 ))
        cycle=$(( 2 * (L - 1) ))
        off=$(( idx % cycle ))
        if (( off < L - 1 )); then pos=$(( off + 1 )); else pos=$(( cycle - off )); fi
        # Zsh 1-based indexing for strings
        # pos is 0-based index from my logic. 
        # So pos+1 is the 1-based index.
        content[pos+1]=" "
    fi
    line="${seq} ${content} ${seq}"
    if [[ -n $output_file ]]; then echo "$line" >> "$output_file"; else echo "$line"; fi
done
