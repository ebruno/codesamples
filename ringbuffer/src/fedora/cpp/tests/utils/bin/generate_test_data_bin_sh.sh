#!/bin/sh

# Default values
lines=10
output_file=""

# Usage function
usage() {
    echo "Usage: generate_test_data_bin_sh.sh [-l lines] [output_file]"
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
if [ -n "$1" ]; then
    output_file=$1
fi

# Template and payload
payload="ABCEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
payload_len=46
cycle=92

# Logic to generate lines in sh (no local variables or advanced slicing)
i=1
while [ $i -le $lines ]; do
    seq_num=$(printf "%04d" $i)
    
    p=-1
    if [ $i -gt 1 ]; then
        m=$(expr $i - 2)
        m=$(expr $m % $cycle)
        if [ $m -lt 46 ]; then
            p=$(expr $m + 1)
        else
            p=$(expr $cycle - 1 - $m)
        fi
    fi
    
    if [ $p -ge 0 ] && [ $p -lt $payload_len ]; then
        # sh slicing is hard, using cut or similar is not standard. 
        # We will use a small helper to replace the char.
        # For a truly portable sh, we might use a loop or sed.
        line="${seq_num} "
        # This is a complex part for pure sh. We'll use a sed trick to replace the p-th char of the payload.
        # Payload is ABCEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>
        # p is 0-indexed.
        # We replace the (p+1)-th character with a space.
        # Note: The payload is fixed.
        modified_payload=$(echo $payload | sed "s/.${p} / /") # This is not quite right.
        # Let's use a loop to build the line.
        # Or just use a sed expression to replace the char at position p+1.
        # In sed, the dot matches one char.
        # We need to match (p) chars, then one char, then the rest.
        # If p=0, replace 1st char. If p=1, replace 2nd char.
        # Sed pattern for p-th char:
        # sed "s/^\(.{p}\)./\1 /"
        
        # Since p is dynamic, we construct the sed command:
        # To replace the (p+1)th character:
        # We need a regex that matches p chars, then one char.
        # For p=0: s/^.//
        # For p=1: s/^.\(.\)// -> s/^.\(.\)/ /
        
        # Let's try a simpler way:
        # Use a temporary file or a loop.
        # Since we are in a script, a loop to build the payload is safest for sh.
        
        payload_with_space=""
        j=0
        while [ $j -lt $payload_len ]; do
            char=$(echo $payload | cut -c $(expr $j + 1))
            if [ $j -eq $p ]; then
                payload_with_space="${payload_with_space} "
            else
                payload_with_space="${payload_with_space}${char}"
            fi
            j=$(expr $j + 1)
        done
        echo "${seq_num} ${payload_with_space} ${seq_num}"
    else
        echo "${seq_num} ${payload} ${seq_num}"
    fi
    i=$(expr $i + 1)
done | {
    if [ -n "$output_file" ]; then
        cat > "$output_file"
    else
        cat
    fi
}
