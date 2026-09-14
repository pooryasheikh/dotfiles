#!/usr/bin/env bash
# Alacritty, installed from the upstream DMG.
#
# The homebrew-cask formula was DISABLED on 2026-09-01:
#   disable! date: "2026-09-01", because: :fails_gatekeeper_check
# Alacritty's macOS builds are not notarized, so Homebrew dropped the cask and
# `brew install --cask alacritty` now hard-errors -- which aborted the whole
# brew-file run. This installs the same artifact the cask used to.
#
# NOTE: this clears the quarantine attribute, which is exactly the Gatekeeper
# check Homebrew disabled the cask over. That is a deliberate choice to trust
# upstream Alacritty releases. If you would rather not, install a notarized
# terminal instead (ghostty, wezterm and kitty are all still in homebrew-cask).
set -euo pipefail

VERSION="0.17.0"
APP="/Applications/Alacritty.app"

if [[ -d "$APP" ]]; then
    echo "Alacritty already installed ✅"
    exit 0
fi

DMG_URL="https://github.com/alacritty/alacritty/releases/download/v${VERSION}/Alacritty-v${VERSION}.dmg"
TMP="$(mktemp -d)"
MOUNT=""
cleanup() {
    [[ -n "$MOUNT" ]] && hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
    rm -rf "$TMP"
}
trap cleanup EXIT

echo "  downloading Alacritty ${VERSION}"
if ! curl -fsSL --max-time 120 -o "$TMP/alacritty.dmg" "$DMG_URL"; then
    echo "  could not download $DMG_URL -- skipping Alacritty" >&2
    exit 0
fi

MOUNT="$(hdiutil attach -nobrowse -readonly -mountrandom "$TMP" "$TMP/alacritty.dmg" \
    | awk '/\/Volumes|\/private\/tmp|'"${TMP//\//\\/}"'/ {print $NF; exit}')"
if [[ -z "$MOUNT" || ! -d "$MOUNT/Alacritty.app" ]]; then
    echo "  could not mount the DMG -- skipping Alacritty" >&2
    exit 0
fi

cp -R "$MOUNT/Alacritty.app" /Applications/
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

echo "Alacritty ${VERSION} ✅"
