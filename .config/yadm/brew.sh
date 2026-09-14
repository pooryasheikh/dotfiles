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
    ksdme/tap
    minio/stable
    mongodb/brew
    nikitabobko/tap
    robusta-dev/krr
)
BROKEN_TAPS=()
for t in "${TRUSTED_TAPS[@]}"; do
    if ! brew tap "$t" >/dev/null 2>&1; then
        BROKEN_TAPS+=("$t")
        continue
    fi
    brew trust --tap "$t" >/dev/null 2>&1 || echo "  could not trust $t" >&2
done

if [ ${#BROKEN_TAPS[@]} -gt 0 ]; then
    {
        echo
        echo "These taps could not be tapped:"
        printf '  - %s\n' "${BROKEN_TAPS[@]}"
        echo
        echo "Homebrew 7 validates every formula and cask in a tap, for every"
        echo "platform, at clone time -- so a single upstream syntax error rejects"
        echo "the entire tap. brew-file then aborts the whole install with a Python"
        echo "traceback and nothing gets installed."
        echo
        echo "Fix: remove that tap line and its tap-qualified packages from"
        echo "  $BREWFILE"
        echo "Check homebrew-core/cask first -- packages keep moving there"
        echo "(jnv and font-sketchybar-app-font both did)."
        echo
    } >&2
fi

echo "Third-party taps trusted ✅"

# brew-file provides the brew-wrap hook that auto-records installs.
if ! brew list --formula 2>/dev/null | grep -qx brew-file; then
    brew install rcmdnk/file/brew-file
fi

CLASS="$(yadm config --get local.class 2>/dev/null || echo unknown)"
if [[ "$CLASS" == "work" ]]; then
    # No personal Apple ID sign-in on work hardware: skip mas entirely
    # instead of failing bootstrap on the first Mac App Store app.
    export HOMEBREW_BREWFILE_APPSTORE=0
    echo "class=work: skipping Mac App Store apps (mas)"
fi

# hashicorp/tap cannot be cloned on Homebrew 7: its vagrant.rb declares a URL
# only for Linux/Intel, so the formula is invalid on macOS and Homebrew rejects
# the whole tap -- which would take packer and vault with it, and make brew-file
# abort the entire install. Mirror just those two (valid) formulae into a local
# tap instead. Fetched fresh each bootstrap so versions stay current.
mirror_hashicorp_formulae() {
    local dest upstream f
    dest="$(brew --repository)/Library/Taps/local/homebrew-hashicorp/Formula"
    upstream="https://raw.githubusercontent.com/hashicorp/homebrew-tap/master/Formula"
    mkdir -p "$dest"
    for f in packer vault; do
        if curl -fsSL "$upstream/$f.rb" -o "$dest/$f.rb.tmp"; then
            mv "$dest/$f.rb.tmp" "$dest/$f.rb"
        else
            rm -f "$dest/$f.rb.tmp"
            if [ -f "$dest/$f.rb" ]; then
                echo "  could not refresh $f.rb, keeping the existing copy" >&2
            else
                echo "  could not fetch $f.rb -- $f will not install" >&2
            fi
        fi
    done
    echo "Local tap local/hashicorp (packer, vault) ✅"
}
mirror_hashicorp_formulae

brew-file install
echo "Brewfile packages ✅"
