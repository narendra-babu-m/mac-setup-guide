#!/usr/bin/env bash
# finder-defaults.sh
# ---------------------------------------------------------------------------
# Phoenix-aligned Finder configuration for Naren's Mac setup.
# Idempotent: safe to re-run any time; rebuilds preferences from scratch
# after a fresh install or pref-blowout.
#
# Usage:
#   bash scripts/finder-defaults.sh
#
# Revert hint: see REVERT block at the bottom of this file (commented out).
# ---------------------------------------------------------------------------

set -euo pipefail

echo "[finder-defaults] applying Finder preferences..."

PLIST="$HOME/Library/Preferences/com.apple.finder.plist"
PB=/usr/libexec/PlistBuddy

# --- Visibility -------------------------------------------------------------
# Show all files including dotfiles (Cmd+Shift+. still toggles on the fly)
defaults write com.apple.finder AppleShowAllFiles -bool true
# Always show every file extension
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# --- Navigation context ----------------------------------------------------
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# --- Default behavior ------------------------------------------------------
# Default view: List (Nlsv). Other options: icnv (icon), clmv (column), Flwv (gallery)
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Search the current folder by default (not "This Mac")
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Skip the "are you sure" prompt when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# New windows + Cmd+N open at $HOME
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
# Open folders in tabs instead of new windows
defaults write com.apple.finder FinderSpawnTab -bool true

# --- Vault hygiene (no .DS_Store on shared storage) ------------------------
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --- Speed / annoyance reductions ------------------------------------------
defaults write com.apple.finder DisableAllAnimations -bool true
# Allow Cmd+Q to quit Finder (it's the one app where it's normally disabled)
defaults write com.apple.finder QuitMenuItem -bool true
# Don't ask before emptying Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false
# Auto-delete items from Trash after 30 days
defaults write com.apple.finder FXRemoveOldTrashItems -bool true

# --- Calculate all sizes (list view) ---------------------------------------
# This setting lives nested inside several view-setting dicts. Plain
# `defaults write` cannot reach nested keys, so we use PlistBuddy and
# flip every list-view variant we know Finder uses.
NESTED_PATHS=(
  ":FK_StandardViewSettings:ListViewSettings:calculateAllSizes"
  ":FK_StandardViewSettings:ExtendedListViewSettingsV2:calculateAllSizes"
  ":FK_DefaultListViewSettingsV2:calculateAllSizes"
  ":FK_iCloudListViewSettingsV2:calculateAllSizes"
  ":ICloudViewSettings:ListViewSettings:calculateAllSizes"
  ":ICloudViewSettings:ExtendedListViewSettingsV2:calculateAllSizes"
  ":StandardViewSettings:ListViewSettings:calculateAllSizes"
  ":StandardViewSettings:ExtendedListViewSettingsV2:calculateAllSizes"
)
for path in "${NESTED_PATHS[@]}"; do
  $PB -c "Set $path true" "$PLIST" 2>/dev/null \
    || $PB -c "Add $path bool true" "$PLIST" 2>/dev/null \
    || true
done

# --- Apply ------------------------------------------------------------------
killall Finder 2>/dev/null || true

echo "[finder-defaults] done. Finder restarted."
echo
echo "Verify with:"
echo "  defaults read com.apple.finder AppleShowAllFiles"
echo "  defaults read com.apple.finder | grep -i calculateAllSizes"
echo "  defaults read com.apple.finder ShowPathbar"

# ---------------------------------------------------------------------------
# REVERT (manual — uncomment lines as needed):
#
#   defaults write com.apple.finder AppleShowAllFiles -bool false
#   defaults write com.apple.finder ShowPathbar -bool false
#   defaults write com.apple.finder ShowStatusBar -bool false
#   defaults write com.apple.finder _FXShowPosixPathInTitle -bool false
#   defaults delete com.apple.finder FXPreferredViewStyle
#   defaults delete com.apple.finder FXDefaultSearchScope
#   defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true
#   defaults write com.apple.finder DisableAllAnimations -bool false
#   defaults write com.apple.finder QuitMenuItem -bool false
#   defaults write com.apple.finder WarnOnEmptyTrash -bool true
#   defaults write com.apple.finder FXRemoveOldTrashItems -bool false
#   # For calculateAllSizes: open the folder in List view, Cmd+J,
#   # untick "Calculate all sizes", click "Use as Defaults".
#   killall Finder
# ---------------------------------------------------------------------------
