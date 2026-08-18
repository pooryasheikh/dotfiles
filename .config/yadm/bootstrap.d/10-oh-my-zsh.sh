#!/usr/bin/env bash
# oh-my-zsh, powerlevel10k, and the custom plugins that .zshrc depends on.
set -euo pipefail

ZSH_DIR="$HOME/.oh-my-zsh"
CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

if [[ ! -d "$ZSH_DIR" ]]; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

clone_if_missing() {
    local url="$1" dest="$2"
    [[ -d "$dest" ]] || git clone --depth=1 "$url" "$dest"
}

# .zshrc sets ZSH_THEME=powerlevel10k/powerlevel10k
clone_if_missing https://github.com/romkatv/powerlevel10k.git "$CUSTOM/themes/powerlevel10k"

# .zshrc lists these in plugins=() and calls `lazyload`; without them every new
# shell prints errors.
clone_if_missing https://github.com/qoomon/zsh-lazyload.git  "$CUSTOM/plugins/zsh-lazyload"
clone_if_missing https://github.com/jeffreytse/zsh-vi-mode.git "$CUSTOM/plugins/zsh-vi-mode"

echo "Oh My Zsh ✅"
