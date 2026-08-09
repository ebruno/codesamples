#!/usr/bin/env zsh

# Version Check
major=${ZSH_VERSION%%.*}
minor=${ZSH_VERSION#*.}
minor=${minor%%.*}

if (( major < 5 || ( major == 5 && minor < 8 ) )); then
    echo "Error: Zsh version 5.8 or higher is required." >&2
    exit 1
fi

if [[ -z $1 ]]; then
    echo "Usage: $(basename $0) [file]"
    exit 1
fi

file=$1

if [[ ! -f $file ]]; then
    echo "Error: File $file not found" >&2
    exit 1
fi

# Read file into array using Zsh parameter expansion (f flag splits by newline)
lines=("${(@f)$(< $file)}")

pattern='^[0-9]{4} .{47} [0-9]{4}$'

for line in "${lines[@]}"; do
    # Skip empty lines (e.g. trailing newline)
    [[ -z $line ]] && continue
    
    if [[ ${#line} -ne 57 ]]; then
        echo "Error: Length ${#line}"
        exit 1
    fi
    
    if [[ ! "$line" =~ $pattern ]]; then
        echo "Error: Format"
        exit 1
    fi
done

exit 0
