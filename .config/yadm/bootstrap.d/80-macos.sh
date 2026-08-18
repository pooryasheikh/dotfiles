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
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false        # required by aerospace
defaults write com.apple.dock expose-group-apps -bool true

# --- screenshots ------------------------------------------------------------
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture type -string "png"

# --- misc -------------------------------------------------------------------
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write com.apple.LaunchServices LSQuarantine -bool false   # no "downloaded from internet"
defaults write com.apple.CrashReporter DialogType -string "none"

for app in Finder Dock SystemUIServer; do killall "$app" >/dev/null 2>&1 || true; done

echo "macOS defaults ✅  (log out and back in for all of them to apply)"
