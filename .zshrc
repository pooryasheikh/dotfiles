#======
# P10K
#======
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#==========
# Homebrew
#==========
# Resolved once. `brew --prefix` was called 5x below, costing a subprocess each.
if [[ -x /opt/homebrew/bin/brew ]]; then
  BREW_PREFIX=/opt/homebrew
elif [[ -x /usr/local/bin/brew ]]; then
  BREW_PREFIX=/usr/local
fi
export BREW_PREFIX

#=====
# ZSH
#=====

export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode reminder
export UPDATE_ZSH_DAYS=30
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

plugins=(
    git
    docker
    # zsh-vi-mode
    # kubectl   -- dropped: its aliases (k/kgp/kgs) are unused and it sources
    #              completions eagerly, defeating the lazyload below.
    # Kube-ps1  -- dropped: p10k already renders the kubecontext segment.
    zsh-lazyload
)

[[ -e $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

#=================
# zsh-completions
#=================
# oh-my-zsh already ran compinit. Extend fpath and reuse the dump (-C) instead
# of paying for a second full scan of every completion function.
if [[ -n "$BREW_PREFIX" ]]; then
  FPATH="$BREW_PREFIX/share/zsh-completions:$FPATH"
  autoload -Uz compinit && compinit -C
fi

#=====
# Fzf
#=====
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#=====================
# zsh-autosuggestions
#=====================
[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

function zvm_after_lazy_keybindings() {
  bindkey -M vicmd "k" up-line-or-beginning-search
  bindkey -M vicmd "j" down-line-or-beginning-search
}

#=========================
# zsh-syntax-highlighting
#=========================
# Must be sourced last of the zsh plugins.
[[ -e "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

#==================
# Homebrew wrap
#==================
# brew-file's hook: appends newly installed packages to
# ~/.config/brewfile/Brewfile automatically on `brew install`.
if [ -f "$BREW_PREFIX/etc/brew-wrap" ]; then
  source "$BREW_PREFIX/etc/brew-wrap"
fi

#=========
# Aliases
#=========
[[ -e $HOME/.config/aliases/.aliases ]] && source $HOME/.config/aliases/.aliases

#=======
# Other
#=======
export EDITOR='nvim'
export GPG_TTY=$TTY
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

export GOPATH="$HOME/go"
export GOROOT="$BREW_PREFIX/opt/go/libexec"
export KREW_ROOT="${KREW_ROOT:-$HOME/.krew}"

path=(
  "$HOME/.local/bin"
  "$KREW_ROOT/bin"
  "$BREW_PREFIX/opt/coreutils/libexec/gnubin"
  "$BREW_PREFIX/opt/mysql-client/bin"
  "$BREW_PREFIX/share/google-cloud-sdk/bin"
  "$BREW_PREFIX/opt/python/libexec/bin"
  $path
  "$GOPATH/bin"
  "$GOROOT/bin"
)
# Drop duplicates, then non-existent directories (N-/ glob qualifier).
typeset -U path
path=($^path(N-/))
export PATH

if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
    export SOPS_AGE_RECIPIENTS=$(sed -n -E 's/^# public key: (.*)/\1/p' "$HOME/.config/sops/age/keys.txt")
fi

#=====
# K9s
#=====
export K9S_CONFIG_DIR="$HOME/.config/k9s/"

#=====================
# Lazy-loaded completions
#=====================
lazyload kubectl -- 'source <(kubectl completion zsh)'
lazyload helm    -- 'source <(helm completion zsh)'
lazyload ut      -- 'source <(ut completions zsh)'
lazyload yc      -- 'source '"$BREW_PREFIX"'/Caskroom/yandex-cloud-cli/*/yandex-cloud-cli/completion.zsh.inc'

#================
# Machine-local
#================
# Employer/machine specific PATH, exports and aliases. Not tracked by yadm --
# this is what keeps the work and personal laptops from bleeding into each other.
[[ -f "$XDG_CONFIG_HOME/zsh/local.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/local.zsh"
