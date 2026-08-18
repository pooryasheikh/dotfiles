#!/usr/bin/env bash
# tpm plus the plugins tmux.conf declares. These used to be broken git
# submodules in the repo; tpm owns them now.
set -euo pipefail

TPM="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins/tpm"

if [[ ! -d "$TPM" ]]; then
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM"
fi

# Installs every `set -g @plugin` from tmux.conf. Needs no running server.
"$TPM/bin/install_plugins" || echo "tpm reported errors; run prefix+I inside tmux" >&2

echo "tmux plugins ✅"
