#!/usr/bin/env bash
# Expose ~/.config/scripts on PATH via symlinks in ~/.local/bin.
# Symlinks (not copies) so edits to the tracked scripts take effect at once,
# and ~/.local/bin (not /usr/local/bin) so no sudo is needed.
set -euo pipefail

SRC="$HOME/.config/scripts"
DEST="$HOME/.local/bin"

[[ -d "$SRC" ]] || { echo "No $SRC, skipping"; exit 0; }
mkdir -p "$DEST"

for script in "$SRC"/*; do
    [[ -f "$script" ]] || continue
    chmod +x "$script"
    ln -sfn "$script" "$DEST/$(basename "$script")"
done

echo "User scripts ✅"
