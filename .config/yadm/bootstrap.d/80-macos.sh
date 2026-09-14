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
# Captured from the personal machine. AeroSpace owns window and workspace
# management, so the macOS shortcuts that fight it are turned off:
#   32,33     Mission Control / Application windows
#   60,61     Select previous / next input source
#   79,81     Move left / right a space (^Left, ^Right - also frees them for
#             nvim split resize and shell word-jump)
#   118-125   Switch to Desktop 1-8
# The rest were disabled on the reference machine; replicated verbatim rather
# than guessed at individually.
for _hk in 15 16 17 18 19 20 21 22 23 24 25 26 32 33 60 61 79 81 \
           118 119 120 121 122 123 124 125 164 176 179; do
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
        -dict-add "$_hk" '<dict><key>enabled</key><false/></dict>'
done

# --- trackpad ----------------------------------------------------------------
# Captured from the personal machine. Written to both the built-in and the
# Magic Trackpad domains so an external trackpad behaves the same.
for _tp in com.apple.AppleMultitouchTrackpad \
           com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    defaults write "$_tp" Clicking -bool true                 # tap to click
    defaults write "$_tp" ActuationStrength -int 0            # silent clicking
    defaults write "$_tp" TrackpadRightClick -bool true
    defaults write "$_tp" Dragging -bool false
    defaults write "$_tp" DragLock -bool false
    defaults write "$_tp" TrackpadThreeFingerDrag -bool false
    defaults write "$_tp" TrackpadHandResting -bool true
    defaults write "$_tp" TrackpadPinch -bool true
    defaults write "$_tp" TrackpadRotate -bool true
    defaults write "$_tp" TrackpadScroll -bool true
    defaults write "$_tp" TrackpadHorizScroll -bool true
    defaults write "$_tp" TrackpadMomentumScroll -bool true
    defaults write "$_tp" TrackpadTwoFingerDoubleTapGesture -int 1
    defaults write "$_tp" TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
    # Horizontal swipes are disabled: they switch macOS spaces and fight
    # AeroSpace. Vertical swipes and pinch stay on for Mission Control.
    defaults write "$_tp" TrackpadThreeFingerHorizSwipeGesture -int 0
    defaults write "$_tp" TrackpadFourFingerHorizSwipeGesture -int 0
    defaults write "$_tp" TrackpadThreeFingerVertSwipeGesture -int 2
    defaults write "$_tp" TrackpadFourFingerVertSwipeGesture -int 2
    defaults write "$_tp" TrackpadFourFingerPinchGesture -int 2
    defaults write "$_tp" TrackpadFiveFingerPinchGesture -int 2
    defaults write "$_tp" TrackpadThreeFingerTapGesture -int 0
    defaults write "$_tp" TrackpadCornerSecondaryClick -int 0
done
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false  # natural scrolling OFF
defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool false
# Tap-to-click also needs the global mirrors, or it does not take effect until
# System Settings is opened.
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

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
