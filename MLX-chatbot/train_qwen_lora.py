#!/usr/bin/env python3
"""
train_qwen_lora.py

HOW TO RUN:
  Open Terminal, paste this line, press Enter:
    python3 ~/Documents/GitHub/MLX-chatbot/train_qwen_lora.py
"""

import subprocess
import sys
from pathlib import Path

print("=" * 50)
print(" AVELA LoRA Training Script")
print("=" * 50)

# ── Paths ──────────────────────────────────────────────────────────────────────
PROJECT_DIR     = Path(__file__).parent.resolve()
REPO_ROOT       = PROJECT_DIR.parent
DATA_DIR        = PROJECT_DIR / "DATA_DIR"
SANDBOX_DIR     = Path.home() / "Library/Containers/AVELA.MLX-chatbot/Data/Library/Application Support/MLX-chatbot"
ADAPTER_PATH    = SANDBOX_DIR / "adapters"
FUSED_MODEL_DIR = SANDBOX_DIR / "fused_model"

print(f"\nProject : {PROJECT_DIR}")
print(f"Data    : {DATA_DIR}")
print(f"Adapters: {ADAPTER_PATH}")
print(f"Output  : {FUSED_MODEL_DIR}")

# ── Training config ────────────────────────────────────────────────────────────
MODEL            = "Qwen/Qwen2.5-1.5B-Instruct"
LEARNING_RATE    = "1e-5"
ITERS            = "200"
BATCH_SIZE       = "1"
STEPS_PER_REPORT = "10"
SAVE_EVERY       = "50"
MAX_SEQ_LENGTH   = "1024"

def run(cmd):
    print(f"\n$ {' '.join(str(c) for c in cmd)}\n")
    sys.stdout.flush()
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print(f"\nERROR: command failed (exit {result.returncode})")
        input("\nPress Enter to close...")
        sys.exit(result.returncode)

# ── 1. Verify data folder ──────────────────────────────────────────────────────
print("\n── Checking data ──")
if not DATA_DIR.exists():
    print(f"\nERROR: Data folder not found:\n  {DATA_DIR}")
    print("\nFiles found in project root:")
    for f in PROJECT_DIR.iterdir():
        print(f"  {f.name}")
    input("\nPress Enter to close...")
    sys.exit(1)

train_file = DATA_DIR / "train.jsonl"
valid_file = DATA_DIR / "valid.jsonl"

if not train_file.exists():
    print(f"ERROR: train.jsonl not found in {DATA_DIR}")
    input("\nPress Enter to close...")
    sys.exit(1)

print(f"✓ Found: {train_file}")

# ── 2. Create valid.jsonl if missing ──────────────────────────────────────────
if not valid_file.exists():
    lines = [l for l in train_file.read_text().strip().splitlines() if l.strip()]
    split = int(len(lines) * 0.8)
    train_file.write_text("\n".join(lines[:split]))
    valid_file.write_text("\n".join(lines[split:]))
    print(f"✓ Created valid.jsonl  ({split} train / {len(lines)-split} valid)")
else:
    print(f"✓ Found: {valid_file}")

# ── 3. Skip if already trained ────────────────────────────────────────────────
if FUSED_MODEL_DIR.exists():
    print(f"\n✓ Fused model already exists at:\n  {FUSED_MODEL_DIR}")
    print("  Delete that folder and re-run to retrain.")
    input("\nPress Enter to close...")
    sys.exit(0)

# ── 4. Virtual environment ────────────────────────────────────────────────────
print("\n── Setting up environment ──")
venv    = REPO_ROOT / ".mlx_venv"
python  = venv / "bin" / "python"

if not venv.exists():
    print("Creating virtual environment...")
    run([sys.executable, "-m", "venv", str(venv)])

print(f"✓ Venv: {venv}")

# ── 5. Install mlx-lm ─────────────────────────────────────────────────────────
check = subprocess.run([str(python), "-c", "import mlx_lm"], capture_output=True)
if check.returncode != 0:
    print("Installing mlx-lm...")
    run([str(python), "-m", "pip", "install", "--upgrade", "pip"])
    run([str(python), "-m", "pip", "install", "mlx-lm"])

print("✓ mlx-lm ready")

# ── 6. LoRA training ──────────────────────────────────────────────────────────
print("\n" + "=" * 50)
print(f" Training {MODEL}")
print("=" * 50)
sys.stdout.flush()

run([
    str(python), "-m", "mlx_lm", "lora",
    "--model",            MODEL,
    "--train",
    "--data",             str(DATA_DIR),
    "--fine-tune-type",   "lora",
    "--learning-rate",    LEARNING_RATE,
    "--iters",            ITERS,
    "--batch-size",       BATCH_SIZE,
    "--grad-checkpoint",
    "--steps-per-report", STEPS_PER_REPORT,
    "--save-every",       SAVE_EVERY,
    "--max-seq-length",   MAX_SEQ_LENGTH,
])

print(f"\n✓ Adapters saved to {ADAPTER_PATH}")

# ── 7. Fuse adapters ──────────────────────────────────────────────────────────
print("\n" + "=" * 50)
print(" Fusing adapters into base model")
print("=" * 50)
sys.stdout.flush()

FUSED_MODEL_DIR.mkdir(parents=True, exist_ok=True)

run([
    str(python), "-m", "mlx_lm", "fuse",
    "--model",        MODEL,
    "--adapter-path", str(ADAPTER_PATH),
    "--save-path",    str(FUSED_MODEL_DIR),
])

print("\n" + "=" * 50)
print("✅ Done!")
print(f"   {FUSED_MODEL_DIR}")
print("\n   Launch the Xcode app — model loads automatically.")
print("=" * 50)

input("\nPress Enter to close...")
