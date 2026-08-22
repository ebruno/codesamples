#!/usr/bin/env zsh
# check_tools.zsh - Check required tools for macOS host
# Returns 0 if all found, 1 if any missing

set -euo pipefail
setopt ksh_arrays

MISSING=()
FOUND=()

echo "============================================="
echo "Tool Availability Check (macOS)"
echo "============================================="

tools=(clang clang++ gcc g++ make bmake tcsh cmake ffmpeg ffprobe pandoc mmdc glab gh)

install_cmds=(
    ""
    ""
    "brew install gcc"
    ""
    "brew install make"
    "brew install bmake"
    "brew install tcsh"
    "brew install cmake"
    "brew install ffmpeg"
    ""
    "brew install pandoc"
    "brew install mermaid-cli"
    "brew install glab"
    "brew install gh"
)

num_tools=${#tools[@]}

for (( i=0; i<num_tools; i++ )); do
    tool="${tools[$i]}"
    if command -v "$tool" >/dev/null 2>&1; then
        path=$(command -v "$tool")
        echo "OK $tool ($path)"
        FOUND+=("$tool")
    else
        echo "MISSING $tool"
        MISSING+=("$tool")
    fi
done

echo ""
echo "Found: ${#FOUND[@]} tools"
echo "Missing: ${#MISSING[@]} tools"

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo "============================================="
    echo "Missing Tools - Installation Commands"
    echo "============================================="

    if ! command -v brew >/dev/null 2>&1; then
        echo ""
        echo "WARNING: Homebrew not found. Install it first:"
        echo '   bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        echo ""
    fi

    for (( i=0; i<num_tools; i++ )); do
        tool="${tools[$i]}"
        found=0
        for m in "${MISSING[@]}"; do
            if [ "$m" = "$tool" ]; then
                found=1
                break
            fi
        done
        if [ $found -eq 1 ]; then
            cmd="${install_cmds[$i]}"
            if [ -n "$cmd" ]; then
                echo "  $tool: $cmd"
            else
                echo "  $tool: (system tool - check Xcode Command Line Tools)"
            fi
        fi
    done

    echo ""
    echo "To install all missing tools at once:"

    pkg_list=""
    for (( i=0; i<num_tools; i++ )); do
        tool="${tools[$i]}"
        found=0
        for m in "${MISSING[@]}"; do
            if [ "$m" = "$tool" ]; then
                found=1
                break
            fi
        done
        if [ $found -eq 1 ] && [ -n "${install_cmds[$i]}" ]; then
            pkg="${install_cmds[$i]##* }"
            case " $pkg_list " in
                *" $pkg "*) ;;
                *) pkg_list="$pkg_list $pkg" ;;
            esac
        fi
    done

    if [ -n "$pkg_list" ]; then
        echo "   brew install$pkg_list"
    fi

    exit 1
else
    echo ""
    echo "All required tools are available."
    exit 0
fi
