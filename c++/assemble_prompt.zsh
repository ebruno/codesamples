#!/usr/bin/env zsh

# Paths relative to the script location (c++/ directory)
SYSTEM_PROMPT="prompts/system/senior-cpp-dev.md"
TEMPLATE_PROMPT="prompts/templates/coding/refactor.md"

SCRIPT_NAME=$(basename "$0")
usage() {
    echo "Usage: $SCRIPT_NAME [-n] [-h] <file1> [file2 ...]"
    echo ""
    echo "Assembles prompts for refactoring the specified C++ files."
    echo ""
    echo "Options:"
    echo "  -h    Display this help message"
    echo "  -n    Dry run: Explain what would be done without creating files (output to stderr)"
    echo ""
    echo "Example:"
    echo "  $SCRIPT_NAME fizzbuzz.cpp"
    echo "  $SCRIPT_NAME -n fizzbuzz.cpp other_file.cpp"
}

# Default values
DRY_RUN=false

# Parse options
while getopts "hn" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        n)
            DRY_RUN=true
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# Shift options out of the positional parameters
shift $((OPTIND-1))

# Check if at least one file was provided
if [[ $# -eq 0 ]]; then
    echo "Error: No files specified." >&2
    usage
    exit 1
fi

# Verify prompt files exist
if [[ ! -f "$SYSTEM_PROMPT" ]]; then
    echo "Error: System prompt not found at $SYSTEM_PROMPT" >&2
    exit 1
fi
if [[ ! -f "$TEMPLATE_PROMPT" ]]; then
    echo "Error: Template prompt not found at $TEMPLATE_PROMPT" >&2
    exit 1
fi

# Process files
for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        echo "Warning: File '$file' not found. Skipping." >&2
        continue
    fi

    output_file="prompt_${file:t}.txt"

    if [ "$DRY_RUN" = true ]; then
        echo "Dry run: Would assemble prompt for '$file' using '$TEMPLATE_PROMPT' and '$SYSTEM_PROMPT'. Output would be saved to '$output_file'." >&2
    else
        echo "Assembling prompt for $file -> $output_file..."
        
        {
            echo "=== SYSTEM PROMPT ==="
            cat "$SYSTEM_PROMPT"
            print "\n\n=== USER PROMPT ==="
            # Use awk to replace {{CODE}} with the content of the target file.
            awk -v f="$file" '/{{CODE}}/{ while ((getline line < f) > 0) print line; close(f); next } 1' "$TEMPLATE_PROMPT"
        } > "$output_file"
    fi
done

if [ "$DRY_RUN" = false ]; then
    echo "All prompts assembled successfully."
fi
