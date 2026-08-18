#!/usr/bin/env bash
# oh-my-zsh, powerlevel10k, and the custom plugins .zshrc depends on.
#
# Clones are verified by ENTRY POINT FILE, not by directory existence: an
# interrupted bootstrap leaves an empty directory behind, and a dir-only check
# then skips the clone forever, leaving oh-my-zsh with nothing to load and
# every new shell printing "command not found: lazyload".
set -euo pipefail

ZSH_DIR="$HOME/.oh-my-zsh"
CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

if [[ ! -f "$ZSH_DIR/oh-my-zsh.sh" ]]; then
    [[ -d "$ZSH_DIR" ]] && rm -rf "$ZSH_DIR"
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
[[ -f "$ZSH_DIR/oh-my-zsh.sh" ]] || { echo "oh-my-zsh install failed" >&2; exit 1; }

# clone_verified <dest> <repo> <entry-point-file-relative-to-dest>
clone_verified() {
    local dest="$1" repo="$2" entry="$3"
    if [[ ! -f "$dest/$entry" ]]; then
        rm -rf "$dest"
        git clone --depth=1 "$repo" "$dest"
    fi
    [[ -f "$dest/$entry" ]] || { echo "clone of $repo is missing $entry" >&2; exit 1; }
}

clone_verified "$CUSTOM/themes/powerlevel10k" \
    https://github.com/romkatv/powerlevel10k.git powerlevel10k.zsh-theme
clone_verified "$CUSTOM/plugins/zsh-lazyload" \
    https://github.com/qoomon/zsh-lazyload.git zsh-lazyload.plugin.zsh
clone_verified "$CUSTOM/plugins/zsh-vi-mode" \
    https://github.com/jeffreytse/zsh-vi-mode.git zsh-vi-mode.plugin.zsh

echo "Oh My Zsh ✅"
