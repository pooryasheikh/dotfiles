#!/usr/bin/env bash
# Sync AstroNvim plugins headlessly so the first real launch is not a wall of
# installers. lazy-lock.json in the repo pins the versions.
set -euo pipefail

command -v nvim >/dev/null 2>&1 || { echo "nvim missing, skipping"; exit 0; }

nvim --headless "+Lazy! restore" +qa 2>&1 | tail -5 || true
echo "Neovim plugins ✅"
