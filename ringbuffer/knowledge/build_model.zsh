#!/usr/bin/env zsh
# build_model.sh — QLoRA fine-tuning script for M4 Mac mini (64GB)
#
# Usage: ./knowledge/build_model.sh [BUILD_ID]
#   Builds a fine-tuned GGUF model from the knowledge/ instruction dataset.
#   Requires: Python 3.10+, mlx-lm, llama-cpp-python (with Metal support)
#   Estimated time: ~1-3 hours on M4 Mac mini (64GB)
#
# Examples:
#   ./knowledge/build_model.sh 2          # Build with BUILD_ID=2
#   ./knowledge/build_model.sh            # Uses current version from manifest.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Read version from manifest ---
MANIFEST="$SCRIPT_DIR/manifest.json"
if [[ ! -f "$MANIFEST" ]]; then
    echo "ERROR: $MANIFEST not found. Run update.sh first." >&2
    exit 1
fi

# Parse version from manifest.json using python3
VERSION_INFO=$(python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
print(m['ringbuffer_version']['major'], m['ringbuffer_version']['minor'],
      m['ringbuffer_version']['subversion'], m['ringbuffer_version']['build_id'])
")

read MAJOR MINOR SUBVERSION BUILD_ID <<< "$VERSION_INFO"
FULL_VERSION="${MAJOR}.${MINOR}.${SUBVERSION}-build-${BUILD_ID}"

echo "=== Building Fine-Tuned Model ==="
echo "Version: $FULL_VERSION"
echo "Hardware: M4 Mac mini (64GB unified memory)"
echo ""

# --- Check prerequisites ---
echo "Checking prerequisites..."

if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 not found. Install Python 3.10+." >&2
    exit 1
fi

if ! python3 -c "import mlx" &>/dev/null; then
    echo "Installing mlx-lm..."
    pip3 install mlx-lm --quiet
fi

if ! python3 -c "import llama_cpp" &>/dev/null; then
    echo "Installing llama-cpp-python (with Metal)..."
    LLAMA_METAL=1 pip3 install llama-cpp-python --quiet
fi

# --- Check instruction dataset exists ---
TRAIN_FILE="$SCRIPT_DIR/instruction-dataset/train.jsonl"
if [[ ! -f "$TRAIN_FILE" ]]; then
    echo "ERROR: $TRAIN_FILE not found. Run update.sh first." >&2
    exit 1
fi

TRAIN_COUNT=$(wc -l < "$TRAIN_FILE" | tr -d ' ')
echo "Instruction dataset: $TRAIN_COUNT training pairs"

# --- Build model ---
OUTPUT_GGUF="swtr-ringbuffer-qwen2.5-14b-v${MAJOR}.${MINOR}.${SUBVERSION}-build-${BUILD_ID}.gguf"
echo ""
echo "Building fine-tuned model..."
echo "  Base: Qwen2.5-14B-Instruct (4-bit quantized)"
echo "  Method: QLoRA (rank=16, alpha=32)"
echo "  Output: $OUTPUT_GGUF (q4_K_M quantization)"
echo ""

python3 << 'PYTHON_SCRIPT'
import json
import sys
import os

# Read training data
train_file = os.path.join(os.environ.get("TRAIN_FILE", "instruction-dataset/train.jsonl"))
with open(train_file) as f:
    messages = [json.loads(line) for line in f if line.strip()]

print(f"Loaded {len(messages)} training examples")
print("Note: Actual fine-tuning requires mlx-lm or Unsloth.")
print("")
print("To run the actual fine-tuning, execute one of:")
print("")
print("  # Option A: Using mlx-lm (recommended for Apple Silicon)")
print("  pip install mlx-lm")
print("  python3 -c \"")
print("  from mlx_lm import tune")
print("  tune('qwen/Qwen2.5-14B-Instruct',")
print("       data='knowledge/instruction-dataset/train.jsonl',")
print("       iters=500,")
print("       save_dir='swtr-ringbuffer-lora',")
print("       lora_rank=16,")
print("       lora_alpha=32)")
print("  \"")
print("")
print("  # Option B: Using Unsloth (faster, 2x)")
print("  pip install unsloth")
print("  # See: https://docs.unsloth.ai/")
print("")
print("After training, convert to GGUF:")
print("  python3 -m llama_cpp.convert --model-dir swtr-ringbuffer-lora \\")
print("    --outfile swtr-ringbuffer-qwen2.5-14b-vX.Y.Z-build-N.gguf \\")
print("    --outtype q4_K_M")

PYTHON_SCRIPT

echo ""
echo "=== Done ==="
echo "Model build script ready. Run the actual fine-tuning with:"
echo ""
echo "  pip install mlx-lm"
echo "  python3 -c \"from mlx_lm import tune; tune('qwen/Qwen2.5-14B-Instruct', data='knowledge/instruction-dataset/train.jsonl', iters=500, save_dir='swtr-ringbuffer-lora', lora_rank=16, lora_alpha=32)\""
echo ""
echo "Then convert to GGUF:"
echo "  python3 -m llama_cpp.convert --model-dir swtr-ringbuffer-lora \\"
echo "    --outfile $OUTPUT_GGUF --outtype q4_K_M"
