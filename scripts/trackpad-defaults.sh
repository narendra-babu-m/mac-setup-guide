#!/usr/bin/env bash
# ============================================================================
# trackpad-defaults.sh — Tap-to-click, three-finger drag, swipe gestures.
# Edit CONFIG section. Comment out a var to leave macOS default.
# ============================================================================

source "$(dirname "$0")/lib/common.sh"

# ============================================================================
# CONFIG
# ============================================================================

# Tap to click (no need to physically press)
# WHY: Faster, quieter, less wear on the trackpad mechanism.
TRACKPAD_TAP_TO_CLICK=true

# Three-finger drag (hold three fingers + move to drag a window/selection)
# WHY: Massive ergonomic win — drag without holding click. Worth re-learning.
TRACKPAD_THREE_FINGER_DRAG=true

# Natural scrolling (content moves with fingers, like iPhone)
# WHY: Keep ON to match iPad/iPhone muscle memory; toggle OFF if you ssh to
#      Linux/Windows machines all day where scroll is reverse.
TRACKPAD_NATURAL_SCROLL=true

# Trackpad speed (0.0–3.0). Higher = faster cursor.
# WHY: Default ~1.5 is sluggish on big screens; 2.5 still controllable.
TRACKPAD_TRACKING_SPEED=2.5

# ============================================================================
# APPLY
# ============================================================================

log "applying Trackpad defaults..."

# Tap-to-click is set on TWO domains: trackpad device + global UI.
if [ -n "${TRACKPAD_TAP_TO_CLICK+x}" ]; then
  if [ "$TRACKPAD_TAP_TO_CLICK" = "true" ]; then
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    log "    set    Clicking + tapBehavior = 1 (tap-to-click on)"
  else
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool false
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool false
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 0
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 0
    log "    set    Clicking + tapBehavior = 0 (tap-to-click off)"
  fi
else
  log "    skip   tap-to-click (TRACKPAD_TAP_TO_CLICK unset)"
fi

# Three-finger drag — must enable BOTH the legacy mode and dragLock=false.
# Modern macOS uses Accessibility → Pointer Control, so we set both surfaces.
if [ -n "${TRACKPAD_THREE_FINGER_DRAG+x}" ]; then
  if [ "$TRACKPAD_THREE_FINGER_DRAG" = "true" ]; then
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    log "    set    TrackpadThreeFingerDrag = true"
  else
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool false
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false
    log "    set    TrackpadThreeFingerDrag = false"
  fi
else
  log "    skip   three-finger drag (TRACKPAD_THREE_FINGER_DRAG unset)"
fi

# Natural scroll = inverted in defaults (true = traditional, false = natural)
if [ -n "${TRACKPAD_NATURAL_SCROLL+x}" ]; then
  if [ "$TRACKPAD_NATURAL_SCROLL" = "true" ]; then
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true
  else
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
  fi
  log "    set    com.apple.swipescrolldirection (natural=$TRACKPAD_NATURAL_SCROLL)"
fi

apply_float TRACKPAD_TRACKING_SPEED NSGlobalDomain com.apple.trackpad.scaling

log "done. Some changes take effect on next login."

# ============================================================================
# REVERT
#   defaults delete NSGlobalDomain com.apple.mouse.tapBehavior
#   defaults delete com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking
#   Reboot or sign out to fully revert.
# ============================================================================
