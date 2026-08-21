#!/usr/bin/env bash
# check_tools.sh - Check required tools for Linux distributions
# Returns 0 if all found, 1 if any missing

set -euo pipefail

MISSING=()
FOUND=()

echo "============================================="
echo "Tool Availability Check (Linux)"
echo "============================================="

tools=(clang clang++ gcc g++ make bmake cmake ffmpeg ffprobe pandoc mmdc glab gh)

# Default install commands (apt-based, overridden per distro below)
install_cmds=(
    ""
    ""
    "sudo apt-get install -y gcc"
    ""
    "sudo apt-get install -y make"
    "sudo apt-get install -y bmake"
    "sudo apt-get install -y cmake"
    "sudo apt-get install -y ffmpeg"
    ""
    "sudo apt-get install -y pandoc"
    "sudo apt-get install -y mermaid-cli"
    "sudo apt-get install -y glab"
    "sudo apt-get install -y gh"
)

# Detect Linux distribution and override commands
if [ -f /etc/os-release ]; then
    os_id=$(. /etc/os-release && echo "${ID}")
else
    os_id="unknown"
fi

case "$os_id" in
    fedora)
        install_cmds=(
            ""
            ""
            "sudo dnf install -y gcc"
            ""
            "sudo dnf install -y make"
            "sudo dnf install -y bmake mk-files"
            "sudo dnf install -y cmake"
            "sudo dnf install -y ffmpeg"
            ""
            "sudo dnf install -y pandoc"
            "sudo dnf install -y mermaid-cli"
            "sudo dnf install -y glab"
            "sudo dnf install -y gh"
        )
        ;;
    debian|ubuntu|raspios)
        install_cmds=(
            ""
            ""
            "sudo apt-get install -y gcc"
            ""
            "sudo apt-get install -y make"
            "sudo apt-get install -y bmake"
            "sudo apt-get install -y cmake"
            "sudo apt-get install -y ffmpeg"
            ""
            "sudo apt-get install -y pandoc"
            "sudo apt-get install -y mermaid-cli"
            "sudo apt-get install -y glab"
            "sudo apt-get install -y gh"
        )
        ;;
    arch)
        install_cmds=(
            ""
            ""
            "sudo pacman -S gcc"
            ""
            "sudo pacman -S make"
            "sudo pacman -S bmake mk-files"
            "sudo pacman -S cmake"
            "sudo pacman -S ffmpeg"
            ""
            "sudo pacman -S pandoc"
            "sudo npm install -g @mermaid-js/mermaid-cli"
            "sudo pacman -S glab"
            "sudo pacman -S gh"
        )
        ;;
esac

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
                echo "  $tool: (system tool - check distro package manager)"
            fi
        fi
    done

    exit 1
else
    echo ""
    echo "All required tools are available."
    exit 0
fi
