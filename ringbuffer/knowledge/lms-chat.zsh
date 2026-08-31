#!/usr/bin/env zsh
# lms-chat.zsh — Convenience wrapper to chat with the ringbuffer knowledge model via LM Studio
#
# Usage:
#   ./lms-chat.zsh                    Interactive chat
#   ./lms-chat.zsh "your question"    One-shot, prints response and exits

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/lms-system-prompt.txt"

# Read model name from lms-model.txt, or use default
MODEL_FILE="$SCRIPT_DIR/lms-model.txt"
if [[ -f "$MODEL_FILE" ]]; then
    MODEL="$(<"$MODEL_FILE")"
else
    echo "ERROR: lms-model.txt not found. Run update.zsh first." >&2
    exit 1
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "ERROR: lms-system-prompt.txt not found. Run update.zsh first." >&2
    exit 1
fi

SYSTEM_PROMPT="$(<"$PROMPT_FILE")"

if [[ $# -ge 1 ]]; then
    # One-shot mode
    lms chat "$MODEL" -s "$SYSTEM_PROMPT" -p "$1"
else
    # Interactive mode
    echo "Starting interactive chat with ringbuffer knowledge..."
    echo "Model: $MODEL"
    echo ""
    lms chat "$MODEL" -s "$SYSTEM_PROMPT"
fi
