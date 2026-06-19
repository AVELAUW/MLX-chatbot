#!/usr/bin/env bash
#
# train_qwen_lora.sh
# One-command LoRA fine-tuning of Qwen2.5-1.5B-Instruct using mlx_lm,
# followed by fusing the trained adapters into a model the Xcode app loads directly.
#
# Terminal usage:
#   chmod +x train_qwen_lora.sh
#   ./train_qwen_lora.sh
#
# To skip training and only fuse:   SKIP_TRAIN=1 ./train_qwen_lora.sh
# To skip the fuse step:            SKIP_FUSE=1  ./train_qwen_lora.sh
# To force retrain even if model exists: FORCE=1 ./train_qwen_lora.sh
#
# Xcode Build Phase usage:
#   Target → Build Phases → + → New Run Script Phase
#   Script: "${SRCROOT}/train_qwen_lora.sh"
#   Uncheck "Based on dependency analysis" so it runs every build.
#   (Set FORCE=0 — training is skipped automatically if fused_model already exists.)
#
set -euo pipefail

# ── Configurable defaults (override by setting env vars before running) ────────
MODEL="${MODEL:-Qwen/Qwen2.5-1.5B-Instruct}"
DATA_DIR="${DATA_DIR:-./Jsonl_data_jsonl}"
LEARNING_RATE="${LEARNING_RATE:-1e-5}"
ITERS="${ITERS:-1000}"
BATCH_SIZE="${BATCH_SIZE:-1}"
STEPS_PER_REPORT="${STEPS_PER_REPORT:-10}"
SAVE_EVERY="${SAVE_EVERY:-50}"
MAX_SEQ_LENGTH="${MAX_SEQ_LENGTH:-1024}"
ADAPTER_PATH="${ADAPTER_PATH:-./adapters}"
SKIP_FUSE="${SKIP_FUSE:-0}"
SKIP_TRAIN="${SKIP_TRAIN:-0}"
FORCE="${FORCE:-0}"

# ── Where the fused model is saved ────────────────────────────────────────────
# The Xcode app reads from exactly this path at launch.
# Do not change this without also updating FUSED_MODEL_PATH in ChatView.swift.
FUSED_MODEL_DIR="${FUSED_MODEL_DIR:-$HOME/Library/Application Support/MLX-chatbot/fused_model}"

echo "=================================================="
echo " MLX-LM LoRA Fine-Tuning"
echo " Output: $FUSED_MODEL_DIR"
echo "=================================================="

# ── Skip everything if fused model already exists and FORCE is not set ─────────
if [ -d "$FUSED_MODEL_DIR" ] && [ "$FORCE" != "1" ]; then
    echo "✓ Fused model already exists at:"
    echo "  $FUSED_MODEL_DIR"
    echo "  Skipping training. Run with FORCE=1 to retrain."
    exit 0
fi

# ── 1. Check for Python 3 ──────────────────────────────────────────────────────
if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 not found."
    echo "Install Python 3.9+ first, e.g.: brew install python"
    exit 1
fi
echo "✓ python3: $(python3 --version)"

# ── 2. Create / reuse a local virtual environment ─────────────────────────────
VENV_DIR="$(pwd)/.mlx_venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment at $VENV_DIR ..."
    python3 -m venv "$VENV_DIR"
fi
# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"
echo "✓ Virtual environment active ($VENV_DIR)"

# ── 3. Install mlx-lm ─────────────────────────────────────────────────────────
if ! python -c "import mlx_lm" &> /dev/null; then
    echo "Installing mlx-lm (first run only)..."
    pip install --quiet --upgrade pip
    pip install --quiet mlx-lm
fi
echo "✓ mlx-lm ready"

# ── 4. Verify training data ───────────────────────────────────────────────────
if [ ! -d "$DATA_DIR" ]; then
    echo "ERROR: Training data directory '$DATA_DIR' not found."
    echo "Place train.jsonl / valid.jsonl there, or set DATA_DIR=/path/to/data"
    exit 1
fi
echo "✓ Training data: $DATA_DIR"

# ── 5. LoRA fine-tuning ───────────────────────────────────────────────────────
if [ "$SKIP_TRAIN" = "1" ]; then
    echo "SKIP_TRAIN=1 — skipping training step."
else
    echo "=================================================="
    echo " Training $MODEL"
    echo "=================================================="

    python -m mlx_lm lora \
      --model "$MODEL" \
      --train \
      --data "$DATA_DIR" \
      --fine-tune-type lora \
      --learning-rate "$LEARNING_RATE" \
      --iters "$ITERS" \
      --batch-size "$BATCH_SIZE" \
      --grad-checkpoint \
      --steps-per-report "$STEPS_PER_REPORT" \
      --save-every "$SAVE_EVERY" \
      --max-seq-length "$MAX_SEQ_LENGTH"

    echo "✓ Adapters saved to $ADAPTER_PATH"
fi

# ── 6. Fuse adapters into base model ──────────────────────────────────────────
if [ "$SKIP_FUSE" = "1" ]; then
    echo "SKIP_FUSE=1 — skipping fuse step."
else
    if [ ! -d "$ADAPTER_PATH" ]; then
        echo "ERROR: Adapter directory '$ADAPTER_PATH' not found."
        exit 1
    fi

    # Create the output directory (mkdir -p handles the space in the path)
    mkdir -p "$FUSED_MODEL_DIR"

    echo "=================================================="
    echo " Fusing adapters → $FUSED_MODEL_DIR"
    echo "=================================================="

    python -m mlx_lm fuse \
      --model "$MODEL" \
      --adapter-path "$ADAPTER_PATH" \
      --save-path "$FUSED_MODEL_DIR"

    echo "=================================================="
    echo " Done. Fused model saved to:"
    echo "  $FUSED_MODEL_DIR"
    echo " The Xcode app will load it automatically on next launch."
    echo "=================================================="
fi
