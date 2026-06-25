#!/usr/bin/env python3

import shutil
from pathlib import Path

print("=" * 50)
print(" MLX-chatbot — Transfer to Documents/GitHub")
print("=" * 50)

# Create ~/Documents/GitHub/ if it doesn't exist
github = Path.home() / "Documents" / "GitHub"
github.mkdir(parents=True, exist_ok=True)
print(f"\n✓ Folder ready: {github}")

src  = Path(__file__).parent.resolve()
dest = github / "MLX-chatbot"

if src == dest:
    print(f"✓ Project is already at {dest}")
elif dest.exists():
    print(f"✓ Destination already exists: {dest}")
    print("  Nothing to do — folder is already there.")
else:
    print(f"\nCopying project to {dest} ...")
    shutil.copytree(str(src), str(dest))
    print(f"✓ Done! Project copied to {dest}")

print("\n" + "=" * 50)
print("✅ Transfer complete!")
print(f"\n   Project is at: {dest}")
print("=" * 50)

input("\nPress Enter to close...")
