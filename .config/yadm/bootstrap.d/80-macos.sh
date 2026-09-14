#!/usr/bin/env bash
# macOS defaults that otherwise cost an hour of clicking on a new machine.
# Reversible: every key can be reset with `defaults delete <domain> <key>`.
set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || exit 0

# --- keyboard ---------------------------------------------------------------
defaults write NSGlobalDomain KeyRepeat -int 2             # fast repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15     # short delay
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false  # repeat, not accent menu
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3   # full keyboard access

# --- text entry: all of these fight with writing code -----------------------
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# --- finder -----------------------------------------------------------------
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # search current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true  # no .DS_Store on shares

# --- dock: aerospace/sketchybar own the screen, get the Dock out of the way --
# Captured from the personal machine so both Macs match.
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0        # no delay before it slides out
defaults write com.apple.dock autohide-time-modifier -float 0  # and no slide animation
defaults write com.apple.dock orientation -string right      # right edge; sketchybar owns the top
defaults write com.apple.dock tilesize -int 37
defaults write com.apple.dock largesize -int 128
defaults write com.apple.dock mineffect -string genie
defaults write com.apple.dock minimize-to-application -bool false
defaults write com.apple.dock launchanim -bool false         # no bouncing icon on launch
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false        # required by aerospace
defaults write com.apple.dock expose-group-apps -bool true

# --- menu bar ---------------------------------------------------------------
# sketchybar replaces the system menu bar, so hide the real one. This is the
# "Automatically hide and show the menu bar: Always" setting.
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# --- screenshots ------------------------------------------------------------
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture type -string "png"

# --- keyboard shortcuts: free up Ctrl+Left/Right for apps (nvim split
# resize, shell/editor word-jump) instead of Mission Control space-switching -
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 '<dict><key>enabled</key><false/></dict>'  # Move left a space (^Left)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 '<dict><key>enabled</key><false/></dict>'  # Move right a space (^Right)

# --- Secure Input -----------------------------------------------------------
# Terminal.app's "Secure Keyboard Entry" calls EnableSecureEventInput() and
# holds it for as long as Terminal runs. That is a SYSTEM-WIDE flag: while it is
# set, no application can read key events, so AeroSpace silently stops
# responding to every shortcut ("AeroSpace cannot respond to keyboard shortcuts
# while Secure Input is active"). It is a menu item that is easy to hit by
# accident, and the setting persists across relaunches.
#
# Which process holds it:
#   ioreg -l -w 0 | LC_ALL=C sed -n 's/.*"kCGSSessionSecureInputPID"=\([0-9]*\).*/\1/p'
defaults write com.apple.Terminal SecureKeyboardEntry -bool false
if pgrep -xq Terminal; then
    echo "  NOTE: Terminal.app is running, so it may rewrite this preference on quit." >&2
    echo "        If AeroSpace shortcuts stay dead, quit Terminal:" >&2
    echo "          osascript -e 'quit app \"Terminal\"'" >&2
fi

# --- misc -------------------------------------------------------------------
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write com.apple.LaunchServices LSQuarantine -bool false   # no "downloaded from internet"
defaults write com.apple.CrashReporter DialogType -string "none"

for app in Finder Dock SystemUIServer; do killall "$app" >/dev/null 2>&1 || true; done

echo "macOS defaults ✅  (log out and back in for all of them to apply)"
