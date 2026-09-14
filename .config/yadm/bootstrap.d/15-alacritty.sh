#!/usr/bin/env bash
# Alacritty, installed from the upstream DMG.
#
# The homebrew-cask formula was DISABLED on 2026-09-01:
#   disable! date: "2026-09-01", because: :fails_gatekeeper_check
# Alacritty's macOS builds are not notarized, so homebrew-cask dropped it. A
# disabled cask cannot be installed at all -- not with --cask, not with --force
# -- and the hard error aborts the whole brew-file run.
#
# This resolves the latest release itself so there is no version to maintain
# here, and re-running bootstrap upgrades in place, the way brew would have.
#
# NOTE: it clears the quarantine attribute, which is the Gatekeeper check
# homebrew-cask disabled the cask over -- a deliberate choice to trust upstream
# Alacritty releases. ghostty, wezterm and kitty are notarized alternatives
# still in homebrew-cask if that trade is unwanted.
set -euo pipefail

APP="/Applications/Alacritty.app"
# Used only if GitHub cannot be reached; not a version to keep updated.
FALLBACK_VERSION="0.17.0"

installed_version() {
    [[ -d "$APP" ]] || return 1
    /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
        "$APP/Contents/Info.plist" 2>/dev/null
}

latest_version() {
    # The releases/latest redirect gives the newest tag without touching the
    # GitHub API, which is rate-limited to 60 requests/hour for anonymous users.
    local url tag
    url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' --max-time 20 \
        https://github.com/alacritty/alacritty/releases/latest 2>/dev/null)" || return 1
    tag="${url##*/}"
    case "$tag" in v[0-9]*.[0-9]*) printf '%s' "${tag#v}" ;; *) return 1 ;; esac
}

have="$(installed_version || true)"
want="$(latest_version || true)"

if [[ -z "$want" ]]; then
    if [[ -n "$have" ]]; then
        echo "Alacritty $have ✅ (could not check for updates)"
        exit 0
    fi
    echo "  could not resolve the latest release, falling back to $FALLBACK_VERSION" >&2
    want="$FALLBACK_VERSION"
fi

if [[ "$have" == "$want" ]]; then
    echo "Alacritty $have ✅"
    exit 0
fi

TMP="$(mktemp -d)"
MOUNT=""
cleanup() {
    [[ -n "$MOUNT" ]] && hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
    rm -rf "$TMP"
}
trap cleanup EXIT

echo "  installing Alacritty ${want}${have:+ (replacing $have)}"
if ! curl -fsSL --max-time 180 -o "$TMP/alacritty.dmg" \
    "https://github.com/alacritty/alacritty/releases/download/v${want}/Alacritty-v${want}.dmg"; then
    echo "  download failed -- leaving Alacritty as-is" >&2
    exit 0
fi

MOUNT="$(hdiutil attach -nobrowse -readonly -mountrandom "$TMP" "$TMP/alacritty.dmg" \
    | awk '/Apple_HFS|Apple_APFS/ {print $NF; exit}')"
if [[ -z "$MOUNT" || ! -d "$MOUNT/Alacritty.app" ]]; then
    echo "  could not mount the DMG -- leaving Alacritty as-is" >&2
    exit 0
fi

rm -rf "$APP"
cp -R "$MOUNT/Alacritty.app" /Applications/
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

echo "Alacritty $(installed_version) ✅"
