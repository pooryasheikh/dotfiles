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

# --- completion directory permissions ----------------------------------------
# oh-my-zsh refuses to load completions from group- or world-writable
# directories and prints a warning at every shell start. Homebrew makes
# /opt/homebrew/share group-writable for the admin group, which trips it:
#
#   [oh-my-zsh] Insecure completion-dependent directories detected:
#   drwxrwxr-x  ... /opt/homebrew/share
#
# That console output during startup also breaks powerlevel10k's instant
# prompt, which is why the p10k warning appears alongside it.
#
# Fixing the permissions is preferable to setting ZSH_DISABLE_COMPFIX, which
# would silence the check rather than address it. Homebrew may restore group
# write on upgrade; re-run this (or `compaudit | xargs chmod g-w,o-w`) if the
# warning comes back.
insecure="$(zsh -fc 'autoload -Uz compaudit; compaudit' 2>/dev/null)" || insecure=""
if [[ -n "$insecure" ]]; then
    echo "  tightening permissions on completion directories:"
    while IFS= read -r dir; do
        [[ -e "$dir" ]] || continue
        if chmod g-w,o-w "$dir" 2>/dev/null; then
            echo "    fixed $dir"
        else
            echo "    could not chmod $dir (not owned by you)" >&2
            unfixable=1
        fi
    done <<< "$insecure"

    # Anything left unfixable means no admin rights over that directory. Rather
    # than warn on every shell start forever, drop a marker .zshrc reads to skip
    # oh-my-zsh's compfix check. Untracked, so it stays machine-local.
    if [[ -n "${unfixable:-}" ]]; then
        mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
        touch "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/disable-compfix"
        echo "    -> set ZSH_DISABLE_COMPFIX marker; delete it if you regain write access:" >&2
        echo "       rm ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/disable-compfix" >&2
    fi
fi

echo "Oh My Zsh ✅"
