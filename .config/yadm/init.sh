#!/usr/bin/env bash
#
# Fresh-machine entry point. Installs the prerequisites needed to get yadm
# running, then hands off to `yadm bootstrap` for everything else.
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/pooryasheikh/dotfiles/main/.config/yadm/init.sh)"
#
# Safe to re-run.

set -euo pipefail

REPO_URL="https://github.com/pooryasheikh/dotfiles.git"
SYSTEM_TYPE="$(uname -s)"

log() { printf '\033[0;34m==>\033[0m %s\n' "$*"; }
ok()  { printf '\033[0;32m  ✓\033[0m %s\n' "$*"; }

# --- Xcode command line tools -----------------------------------------------
if [[ "$SYSTEM_TYPE" == "Darwin" ]]; then
    if ! xcode-select --print-path >/dev/null 2>&1; then
        log "Installing Xcode command line tools (accept the GUI prompt)"
        xcode-select --install || true
        # xcode-select --install returns immediately; wait for it to finish.
        until xcode-select --print-path >/dev/null 2>&1; do sleep 10; done
    fi
    ok "Xcode command line tools"
fi

# --- Homebrew ---------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Put brew on PATH for the remainder of this script (Apple Silicon and Intel).
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
ok "Homebrew $(brew --version | head -1 | awk '{print $2}')"

# --- yadm -------------------------------------------------------------------
if ! command -v yadm >/dev/null 2>&1; then
    log "Installing yadm"
    brew install yadm
fi
ok "yadm $(yadm --version | awk '{print $3}')"

# --- clone ------------------------------------------------------------------
if yadm rev-parse --git-dir >/dev/null 2>&1; then
    ok "dotfiles repo already present"
else
    log "Cloning dotfiles"
    yadm clone --no-bootstrap "$REPO_URL"
fi

# --- machine class ----------------------------------------------------------
# Keeps the work and personal laptops from sharing identity/host config.
if [[ -z "$(yadm config --get local.class || true)" ]]; then
    printf '\nWhich machine is this? [work/personal] '
    read -r class
    case "$class" in
        work|personal) yadm config local.class "$class" ;;
        *) echo "Unrecognised class '$class', defaulting to 'work'"; yadm config local.class work ;;
    esac
fi
ok "class = $(yadm config --get local.class)"

log "Running bootstrap"
yadm bootstrap
