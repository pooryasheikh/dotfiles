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
    ksdme/tap
    minio/stable
    mongodb/brew
    nikitabobko/tap
    robusta-dev/krr
)
# Homebrew rejects an entire tap if ANY formula in it is invalid on ANY
# platform. Some upstream taps ship formulae we never use that fail that check
# -- hashicorp/tap's vagrant.rb declares a URL only for Linux/Intel, so the
# whole tap is unusable on macOS (hashicorp/homebrew-tap#405). HOMEBREW_DEVELOPER
# skips the check (Library/Homebrew/tap.rb:754). Scoped to this one command so
# developer mode is not enabled for anything else.
needs_developer_bypass() {
    case "$1" in
        hashicorp/tap) return 0 ;;
        *) return 1 ;;
    esac
}

BROKEN_TAPS=()
for t in "${TRUSTED_TAPS[@]}"; do
    if needs_developer_bypass "$t"; then
        tap_rc=0; HOMEBREW_DEVELOPER=1 brew tap "$t" >/dev/null 2>&1 || tap_rc=$?
    else
        tap_rc=0; brew tap "$t" >/dev/null 2>&1 || tap_rc=$?
    fi
    if [ "$tap_rc" -ne 0 ]; then
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

brew-file install
echo "Brewfile packages ✅"
