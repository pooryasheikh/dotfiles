#!/usr/bin/env bash
# SbarLua: the Lua bindings sketchybar's Lua config (helpers/init.lua) requires
# via package.cpath. Not installed by the sketchybar formula itself -- it's a
# separate project that has to be cloned and built.
set -euo pipefail

command -v sketchybar >/dev/null 2>&1 || { echo "sketchybar missing, skipping SbarLua"; exit 0; }

INSTALL_DIR="$HOME/.local/share/sketchybar_lua"

if [[ ! -f "$INSTALL_DIR/sketchybar.so" ]]; then
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    git clone --depth=1 https://github.com/FelixKratz/SbarLua "$tmp/SbarLua"
    make -C "$tmp/SbarLua" install
fi

[[ -f "$INSTALL_DIR/sketchybar.so" ]] || { echo "SbarLua build failed" >&2; exit 1; }

echo "SbarLua ✅"
