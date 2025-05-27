#======
# P10K
#======
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


#=====
# ZSH
#=====

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode reminder
export UPDATE_ZSH_DAYS=30
DISABLE_MAGIC_FUNCTIONS="true"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export GPG_TTY=$TTY

plugins=(
    git
    docker
    # zsh-vi-mode
    kubectl
    Kube-ps1
    zsh-lazyload
)

[[ -e $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

#=====
# Fzf
#=====
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


#=====================
# zsh-autosuggestions
#=====================
[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] &&  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# function zvm_after_init() {
# }

function zvm_after_lazy_keybindings() {
  bindkey -M vicmd "k" up-line-or-beginning-search
  bindkey -M vicmd "j" down-line-or-beginning-search
}

#=================
# zsh-completions
#=================
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

    autoload -Uz compinit
    compinit
fi

#=========================
# zsh-syntax-highlighting
#=========================
[[ -e "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#==================
# Homebrew wrap 
#==================
if [ -f $(brew --prefix)/etc/brew-wrap ];then
  source $(brew --prefix)/etc/brew-wrap
fi

#=========
# Aliases
#=========
[[ -e $HOME/.config/aliases/.aliases ]] && source $HOME/.config/aliases/.aliases

#=======
# Other
#=======
export EDITOR='nvim'
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$HOME/.local/bin/:$PATH
export PATH="/usr/local/opt/ncurses/bin:$PATH"
export PATH="/usr/local/opt/node@14/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/node@14/lib"
export CPPFLAGS="-I/usr/local/opt/node@14/include"
export GOPATH=$HOME/go
export GOROOT="$(brew --prefix go)/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"
export GPG_TTY=$(tty)
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export PATH="$HOME/Library/Python/3.10/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
if [[ -z "$XDG_CONFIG_HOME" ]]
then
    export XDG_CONFIG_HOME="$HOME/.config"
fi
if [ -f "$HOME/.config/sops/age/keys.txt" ]
then
    export SOPS_AGE_RECIPIENTS=$(sed -n -E 's/^# public key: (.*)/\1/p' "$HOME/.config/sops/age/keys.txt" )
fi

#=========
# Kubectl
#=========
lazyload kubectl -- 'source <(kubectl completion zsh)'

#=============
# Yandex Cloud
#=============
lazyload yc -- 'source  /opt/homebrew/Caskroom/yandex-cloud-cli/*/yandex-cloud-cli/completion.zsh.inc'

#=====
# K9s
#=====
export K9S_CONFIG_DIR=~/.config/k9s/

#=======
# Helm
#=======
lazyload helm -- 'source <(helm completion zsh)'
