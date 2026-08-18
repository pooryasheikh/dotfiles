#!/usr/bin/env bash
# alacritty.toml imports a theme from this repo; it was a broken submodule.
set -euo pipefail

DEST="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/themes"
[[ -d "$DEST" ]] || git clone --depth=1 https://github.com/alacritty/alacritty-theme "$DEST"

echo "Alacritty themes ✅"
