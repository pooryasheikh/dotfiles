#!/usr/bin/env bash
# Alacritty, installed from the upstream DMG.
#
# homebrew-cask DISABLED the cask on 2026-09-01:
#   disable! date: "2026-09-01", because: :fails_gatekeeper_check
# Alacritty's macOS builds are not notarized. A disabled cask cannot be
# installed at all -- not with --cask, not with --force -- and the hard error
# aborts the whole brew-file run, so Alacritty is installed here instead.
#
# Resolves the newest release itself, so there is no version to maintain, and
# re-running bootstrap upgrades in place.
#
# NOTE: clears the quarantine attribute, i.e. the Gatekeeper check the cask was
# disabled over. Deliberate: it trusts upstream Alacritty releases. ghostty,
# wezterm and kitty are notarized alternatives still in homebrew-cask.
#
# Deliberately does NOT use `set -e`: every failure below is reported with its
# real cause and exits 0, so a terminal download problem cannot abort the rest
# of bootstrap. An earlier version used `set -euo pipefail` and died inside a
# command substitution, printing nothing at all.
set -uo pipefail

APP_NAME="Alacritty.app"
DEST_DIR="/Applications"
[[ -w "$DEST_DIR" ]] || DEST_DIR="$HOME/Applications"
APP="$DEST_DIR/$APP_NAME"
FALLBACK_VERSION="0.17.0"   # last resort only; not kept current

warn() { printf '  %s\n' "$*" >&2; }

installed_version() {
    [[ -d "$APP" ]] || return 1
    /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
        "$APP/Contents/Info.plist" 2>/dev/null
}

latest_version() {
    # releases/latest redirects to the newest tag. Avoids api.github.com,
    # which is rate-limited to 60 requests/hour for anonymous callers.
    local url tag
    url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' --max-time 20 \
        https://github.com/alacritty/alacritty/releases/latest 2>/dev/null)" || return 1
    tag="${url##*/}"
    case "$tag" in v[0-9]*.[0-9]*) printf '%s' "${tag#v}" ;; *) return 1 ;; esac
}

have="$(installed_version)" || have=""
want="$(latest_version)" || want=""

if [[ -z "$want" ]]; then
    if [[ -n "$have" ]]; then
        echo "Alacritty $have ✅ (could not reach GitHub to check for updates)"
        exit 0
    fi
    warn "could not resolve the latest release; trying $FALLBACK_VERSION"
    want="$FALLBACK_VERSION"
fi

if [[ -n "$have" && "$have" == "$want" ]]; then
    echo "Alacritty $have ✅"
    exit 0
fi

TMP="$(mktemp -d)" || { warn "mktemp failed"; exit 0; }
MOUNT=""
cleanup() {
    [[ -n "$MOUNT" ]] && hdiutil detach "$MOUNT" -quiet 2>/dev/null
    rm -rf "$TMP"
}
trap cleanup EXIT

echo "  installing Alacritty ${want}${have:+ (replacing $have)} into $DEST_DIR"

DMG="$TMP/alacritty.dmg"
if ! curl -fsSL --max-time 300 -o "$DMG" \
    "https://github.com/alacritty/alacritty/releases/download/v${want}/Alacritty-v${want}.dmg" \
    2>"$TMP/curl.err"; then
    warn "download failed:"; sed 's/^/    /' "$TMP/curl.err" >&2
    warn "install manually: https://github.com/alacritty/alacritty/releases"
    exit 0
fi

if ! hdiutil attach -nobrowse -readonly -mountrandom "$TMP" "$DMG" \
        >"$TMP/attach.out" 2>"$TMP/attach.err"; then
    warn "could not mount the DMG:"; sed 's/^/    /' "$TMP/attach.err" >&2
    exit 0
fi
# hdiutil output is tab-separated; the mount point is the last field, and only
# on the row that actually has one.
MOUNT="$(awk -F'\t' '$NF ~ /^\// {print $NF; exit}' "$TMP/attach.out")"
if [[ -z "$MOUNT" ]]; then
    warn "no mount point in hdiutil output:"; sed 's/^/    /' "$TMP/attach.out" >&2
    exit 0
fi
if [[ ! -d "$MOUNT/$APP_NAME" ]]; then
    warn "$APP_NAME not found in the DMG (mounted at $MOUNT):"
    ls -1 "$MOUNT" 2>/dev/null | sed 's/^/    /' >&2
    exit 0
fi

mkdir -p "$DEST_DIR"
rm -rf "$APP"
if ! cp -R "$MOUNT/$APP_NAME" "$DEST_DIR/" 2>"$TMP/cp.err"; then
    warn "could not copy into $DEST_DIR:"; sed 's/^/    /' "$TMP/cp.err" >&2
    exit 0
fi
xattr -dr com.apple.quarantine "$APP" 2>/dev/null

now="$(installed_version)" || now="$want"
echo "Alacritty $now ✅"
