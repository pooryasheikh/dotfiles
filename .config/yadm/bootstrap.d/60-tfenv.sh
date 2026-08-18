#!/usr/bin/env bash
# tfenv installs no toolchain by itself; install the pinned version.
set -euo pipefail

command -v tfenv >/dev/null 2>&1 || { echo "tfenv missing, skipping"; exit 0; }

VERSION_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/tfenv/version"
if [[ -f "$VERSION_FILE" ]]; then
    tfenv install "$(cat "$VERSION_FILE")"
    tfenv use "$(cat "$VERSION_FILE")"
else
    tfenv install latest && tfenv use latest
fi

echo "Terraform via tfenv ✅"
