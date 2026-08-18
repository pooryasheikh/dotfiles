#!/usr/bin/env bash
#
# Installs Homebrew (if missing) and everything in the Brewfile.
# Uses brew-file (rcmdnk/file), which hooks `brew install` via brew-wrap so newly
# installed packages are appended to the Brewfile automatically.

set -euo pipefail

BREWFILE="$HOME/.config/brewfile/Brewfile"

if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Homebrew ✅"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if [[ ! -f "$BREWFILE" ]]; then
    echo "No Brewfile at $BREWFILE, skipping package install" >&2
    exit 0
fi

# Homebrew 6 refuses to load formulae/casks from third-party taps until they
# are trusted, which would make `brew bundle install` skip sketchybar, borders,
# flux, packer, vault and friends without a hard error.
TRUSTED_TAPS=(
    chipmk/tap
    cloudflare/cloudflare
    darksworm/tap
    felixkratz/formulae
    fluxcd/tap
    getsentry/tools
    hashicorp/tap
    hudochenkov/sshpass
    ksdme/tap
    minio/stable
    mongodb/brew
    nikitabobko/tap
    robusta-dev/krr
    ynqa/tap
)
for t in "${TRUSTED_TAPS[@]}"; do
    brew tap "$t" >/dev/null 2>&1 || true
    brew trust --tap "$t" >/dev/null 2>&1 || echo "  could not trust $t" >&2
done
echo "Third-party taps trusted ✅"

# brew-file provides the brew-wrap hook that auto-records installs.
if ! brew list --formula 2>/dev/null | grep -qx brew-file; then
    brew install rcmdnk/file/brew-file
fi

brew-file install
echo "Brewfile packages ✅"
