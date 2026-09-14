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
    rcmdnk/file
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

# brew-wrap regenerates the Brewfile from the CURRENTLY INSTALLED state on
# every brew install/reinstall/tap/untap/uninstall, so the working copy cannot
# be trusted during bootstrap -- a single `brew untap` beforehand once shrank
# it from 115 formulae to 9. Install from the committed copy instead.
#
# And do NOT use `brew-file install` here: it is all-or-nothing. One package
# that fails -- flux-app's download timing out behind a corporate network, a
# cask disabled upstream -- raises CmdError and abandons every remaining
# package, which is how a fresh machine ended up with zero of its 115
# formulae. Install directly, tolerate individual failures, report them.
COMMITTED_BREWFILE="$(mktemp "${TMPDIR:-/tmp}/Brewfile.committed.XXXXXX")"
if ! yadm show "HEAD:.config/brewfile/Brewfile" > "$COMMITTED_BREWFILE" 2>/dev/null ||
   [ ! -s "$COMMITTED_BREWFILE" ]; then
    echo "  could not read the committed Brewfile; using the working copy" >&2
    cp "$BREWFILE" "$COMMITTED_BREWFILE"
fi

if ! cmp -s "$COMMITTED_BREWFILE" "$BREWFILE"; then
    {
        echo
        echo "NOTE: $BREWFILE differs from the committed version"
        echo "  committed: $(grep -c '^brew ' "$COMMITTED_BREWFILE") formulae, $(grep -c '^cask ' "$COMMITTED_BREWFILE") casks"
        echo "  on disk  : $(grep -c '^brew ' "$BREWFILE") formulae, $(grep -c '^cask ' "$BREWFILE") casks"
        echo "  Installing the committed set. To restore the working copy:"
        echo "      yadm checkout -- .config/brewfile/Brewfile"
        echo
    } >&2
fi

# "brew \"name\"" / "cask \"name\"" -> name
brewfile_entries() {
    sed -n "s/^$1 \"\([^\"]*\)\".*/\1/p" "$COMMITTED_BREWFILE"
}

FORMULAE=(); while IFS= read -r n; do [ -n "$n" ] && FORMULAE+=("$n"); done < <(brewfile_entries brew)
CASKS=();    while IFS= read -r n; do [ -n "$n" ] && CASKS+=("$n");    done < <(brewfile_entries cask)
echo "  Brewfile: ${#FORMULAE[@]} formulae, ${#CASKS[@]} casks"

# Pass 1: batch. Fast, and Homebrew installs what it can.
[ ${#FORMULAE[@]} -gt 0 ] && brew install --formula "${FORMULAE[@]}" || true
[ ${#CASKS[@]} -gt 0 ]    && brew install --cask "${CASKS[@]}"       || true

# Pass 2: whatever is still missing, one at a time, so a single failure cannot
# take the rest down. Only stragglers reach here, so this is usually a no-op.
FAILED=()
installed_formulae="$(brew list --formula -1 2>/dev/null)"
installed_casks="$(brew list --cask -1 2>/dev/null)"
for f in "${FORMULAE[@]}"; do
    printf '%s\n' "$installed_formulae" | grep -qx "${f##*/}" && continue
    brew install --formula "$f" >/dev/null 2>&1 || FAILED+=("brew $f")
done
for c in "${CASKS[@]}"; do
    printf '%s\n' "$installed_casks" | grep -qx "${c##*/}" && continue
    brew install --cask "$c" >/dev/null 2>&1 || FAILED+=("cask $c")
done
rm -f "$COMMITTED_BREWFILE"

if [ ${#FAILED[@]} -gt 0 ]; then
    {
        echo
        echo "These packages could not be installed (everything else did):"
        printf '  - %s\n' "${FAILED[@]}"
        echo "Common causes: the download host is blocked on this network, or the"
        echo "cask was disabled upstream. Install them by hand or drop them from"
        echo "the Brewfile."
        echo
    } >&2
fi

echo "Brewfile packages ✅"
