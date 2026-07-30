#!/usr/bin/env zsh

# Function to display usage information
usage() {
    cat <<EOF
Usage: $(basename "$0") [-l lines] [output_file]

Generate test data using the zig-zag space pattern.

Options:
  -l lines    Number of lines to generate (default: 10)
  -h          Display this help message

Arguments:
  output_file Optional file to write the output to. If not specified, output goes to stdout.
EOF
    exit 0
}

# Default values
LINES=10
OUTPUT_FILE=""
TEMPLATE="ABCEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
L=${#TEMPLATE}

# Simple argument parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h) usage ;;
        -l) 
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                LINES=$2
                shift 2
            else
                echo "Error: -l requires a positive integer argument." >&2
                exit 1
            fi
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage
            ;;
        *)
            OUTPUT_FILE="$1"
            shift
            ;;
    esac
done

# Validate line count
if [[ ! "$LINES" =~ ^[0-9]+$ ]] || [[ "$LINES" -le 0 ]]; then
    echo "Error: Number of lines must be a positive integer." >&2
    exit 1
fi

# Generate content
result=""
for (( i=1; i<=LINES; i++ )); do
    seq_num=$(printf "%04d" "$i")
    
    if [[ $i -eq 1 ]]; then
        line="$seq_num $TEMPLATE $seq_num"
    else
        d=$(( i - 2 ))
        cycle_len=$(( 2 * (L - 1) ))
        pos=$(( d % cycle_len ))
        
        if [[ $pos -lt $(( L - 1 )) ]]; then
            idx=$(( pos + 1 ))
        else
            idx=$(( (L - 1) - (pos - (L - 1)) - 1 ))
        fi
        
        if [[ $idx -lt 0 ]]; then idx=0; fi
        if [[ $idx -ge $L ]]; then idx=$(( L - 1 )); fi
        
        mid=(${(s::)TEMPLATE})
        mid[$((idx + 1))]=" "
        joined_mid="${(j::)mid}"
        
        line="$seq_num $joined_mid $seq_num"
    fi
    result+="$line
"
done

if [[ -n "$OUTPUT_FILE" ]]; then
    echo -n "$result" > "$OUTPUT_FILE"
else
    echo -n "$result"
fi
