#!/usr/bin/env bash
# gif_to_mp4.sh — Convert an animated GIF to MP4
# Usage: ./utils/bin/gif_to_mp4.sh <input.gif> [720p|1080p]
#   No resolution arg → generates BOTH 720p and 1080p
#   Single resolution arg → generates only that resolution

set -euo pipefail

# --- Validate arguments ---
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <input.gif> [720p|1080p]"
    echo ""
    echo "  No resolution arg → generates BOTH 720p and 1080p"
    echo "  Single arg (720p or 1080p) → generates only that resolution"
    exit 1
fi

INPUT="$1"

if [ ! -f "$INPUT" ]; then
    echo "Error: file not found: $INPUT"
    exit 1
fi

# --- Determine resolutions to generate ---
RESOLUTIONS=()
if [ $# -eq 1 ]; then
    # No resolution specified → generate both
    RESOLUTIONS=("720p" "1080p")
else
    # Validate resolution argument
    case "$2" in
        720p|1080p) RESOLUTIONS=("$2") ;;
        *)
            echo "Error: invalid resolution '$2'. Must be 720p or 1080p."
            exit 1
            ;;
    esac
fi

# --- Derive output path (images/ is sibling of animated_graphics/) ---
BASENAME=$(basename "$INPUT" .gif)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$(dirname "$SCRIPT_DIR")/../images"
mkdir -p "$OUTPUT_DIR"

# --- Get GIF dimensions from ffprobe, round up to even (H.264 requirement) ---
GIF_WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$INPUT")
GIF_HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$INPUT")

# Round up to nearest even number
GIF_WIDTH=$(( (GIF_WIDTH + 1) / 2 * 2 ))
GIF_HEIGHT=$(( (GIF_HEIGHT + 1) / 2 * 2 ))

echo "Converting: $INPUT"
echo "  Original dimensions: ${GIF_WIDTH}x${GIF_HEIGHT}"
echo "  Resolutions to generate: ${RESOLUTIONS[*]}"
echo ""

# --- Convert function ---
convert_to_mp4() {
    local RES="$1"
    local TARGET_W TARGET_H

    case "$RES" in
        720p)  TARGET_W=1280; TARGET_H=720 ;;
        1080p) TARGET_W=1920; TARGET_H=1080 ;;
    esac

    # Scale to target resolution while preserving aspect ratio (letterbox/pillarbox)
    local OUTPUT="${OUTPUT_DIR}/${BASENAME}_${RES}.mp4"
    local REL_OUTPUT="images/${BASENAME}_${RES}.mp4"

    echo "  → ${REL_OUTPUT} (${TARGET_W}x${TARGET_H})"

    ffmpeg -y -i "$INPUT" \
        -vf "fps=24,scale=${TARGET_W}:${TARGET_H}:flags=lanczos,pad=${TARGET_W}:${TARGET_H}:(ow-iw)/2:(oh-ih)/2" \
        -c:v libx264 \
        -pix_fmt yuv420p \
        "$OUTPUT"

    local FILE_SIZE
    FILE_SIZE=$(du -h "$OUTPUT")
    FILE_SIZE="${FILE_SIZE%%\t*}"  # Extract size (bash builtin, no cut)
    echo "    Size: ${FILE_SIZE}"
}

# --- Generate each resolution ---
for RES in "${RESOLUTIONS[@]}"; do
    convert_to_mp4 "$RES"
    echo ""
done

echo "Done."
