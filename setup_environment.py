#!/usr/bin/env python3

import subprocess
import sys
import os
from pathlib import Path

print("=" * 50)
print(" AVELA MLX Environment Setup")
print("=" * 50)

def run(cmd, check=True):
    print(f"\n$ {' '.join(str(c) for c in cmd)}\n")
    sys.stdout.flush()
    result = subprocess.run(cmd)
    if check and result.returncode != 0:
        print(f"\nERROR: command failed (exit {result.returncode})")
        input("\nPress Enter to close...")
        sys.exit(result.returncode)

def command_exists(cmd):
    return subprocess.run(["which", cmd], capture_output=True).returncode == 0

# ── Step 1: Homebrew ──────────────────────────────────────────────────────────
print("\n── Step 1: Homebrew ──")
if command_exists("brew"):
    print("✓ Homebrew already installed")
else:
    print("Installing Homebrew (you may be asked for your password)...")
    run(["/bin/bash", "-c",
         '$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)'])

# Add Homebrew to PATH for this session
brew_env = subprocess.run(
    ["/opt/homebrew/bin/brew", "shellenv"],
    capture_output=True, text=True
)
if brew_env.returncode == 0:
    for line in brew_env.stdout.splitlines():
        if line.startswith("export "):
            key, _, value = line[7:].partition("=")
            os.environ[key] = value.strip('"')

# Persist to ~/.zprofile
zprofile = Path.home() / ".zprofile"
brew_line = 'eval "$(/opt/homebrew/bin/brew shellenv)"'
if not zprofile.exists() or brew_line not in zprofile.read_text():
    with open(zprofile, "a") as f:
        f.write(f'\n{brew_line}\n')
    print("✓ Added Homebrew to ~/.zprofile")

# ── Step 2: Python 3.11 ───────────────────────────────────────────────────────
print("\n── Step 2: Python 3.11 ──")
if command_exists("python3.11"):
    print("✓ Python 3.11 already installed")
else:
    print("Installing Python 3.11 via Homebrew...")
    run(["brew", "install", "python@3.11"])

# ── Step 3: Virtual environment ───────────────────────────────────────────────
print("\n── Step 3: Virtual environment ──")
venv = Path.home() / "Documents" / ".venv311"
python311 = Path("/opt/homebrew/bin/python3.11")

if not python311.exists():
    python311 = Path(subprocess.run(
        ["which", "python3.11"], capture_output=True, text=True
    ).stdout.strip())

if venv.exists():
    print(f"✓ Virtual environment already exists at {venv}")
else:
    (Path.home() / "Documents").mkdir(parents=True, exist_ok=True)
    run([str(python311), "-m", "venv", str(venv)])
    print(f"✓ Created virtual environment at {venv}")

# ── Step 4: mlx-lm ───────────────────────────────────────────────────────────
print("\n── Step 4: Installing mlx-lm ──")
pip = venv / "bin" / "pip"
run([str(pip), "install", "--upgrade", "pip"])
run([str(pip), "install", "mlx-lm"])
print("✓ mlx-lm installed")

# ── Step 5: Move repo to ~/Documents/GitHub/ ─────────────────────────────────
print("\n── Step 5: Moving repo ──")
github = Path.home() / "Documents" / "GitHub"
github.mkdir(parents=True, exist_ok=True)

src  = Path(__file__).parent.resolve()
dest = github / "MLX-chatbot"

if dest.exists():
    print(f"✓ Repo already at {dest}")
elif src == dest:
    print(f"✓ Repo already in the right place")
else:
    import shutil
    shutil.move(str(src), str(dest))
    print(f"✓ Repo moved to {dest}")

# ── Done ──────────────────────────────────────────────────────────────────────
print("\n" + "=" * 50)
print("✅ Setup complete!")
print(f"\n   Next: open Terminal and run:")
print(f"   python3 {dest}/MLX-chatbot/train_qwen_lora.py")
print("=" * 50)

input("\nPress Enter to close...")
