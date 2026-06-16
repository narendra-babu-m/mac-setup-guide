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
# WHY: TRADEOFF — three-finger drag steals the 3-finger-up gesture from
# Mission Control (macOS silently demotes Mission Control to FOUR fingers
# when this is enabled). Naren tried it Jun-2026 and hated the conflict —
# 3-finger swipe in iTerm2 was selecting text instead of opening Mission
# Control. Disabled. If a future Naren wants drag back, accept that
# Mission Control = 4 fingers from then on.
TRACKPAD_THREE_FINGER_DRAG=false

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
#
# Several trackpad settings need writes to MULTIPLE domains because macOS
# stores trackpad state across (a) the bluetooth driver, (b) the multitouch
# driver, (c) NSGlobalDomain, and sometimes (d) the per-host NSGlobalDomain.
# We just call apply_* multiple times against the same VAR — each call is
# independent and skips cleanly if the var is unset.

log "applying Trackpad defaults..."

# Tap-to-click — set on driver + multitouch domains (bool) + global (int).
# tapBehavior is an int (0/1), not bool, so we map true/false→1/0 first.
apply_bool TRACKPAD_TAP_TO_CLICK com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking
apply_bool TRACKPAD_TAP_TO_CLICK com.apple.AppleMultitouchTrackpad                  Clicking
if [ -n "${TRACKPAD_TAP_TO_CLICK+x}" ]; then
  case "$TRACKPAD_TAP_TO_CLICK" in
    true)  TRACKPAD_TAP_TO_CLICK_INT=1 ;;
    false) TRACKPAD_TAP_TO_CLICK_INT=0 ;;
    *) warn "TRACKPAD_TAP_TO_CLICK = '$TRACKPAD_TAP_TO_CLICK' (expected true/false)"; TRACKPAD_TAP_TO_CLICK_INT="" ;;
  esac
  apply_int             TRACKPAD_TAP_TO_CLICK_INT NSGlobalDomain com.apple.mouse.tapBehavior
  apply_int_currenthost TRACKPAD_TAP_TO_CLICK_INT NSGlobalDomain com.apple.mouse.tapBehavior
fi

# Three-finger drag — both driver domains.
apply_bool TRACKPAD_THREE_FINGER_DRAG com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag
apply_bool TRACKPAD_THREE_FINGER_DRAG com.apple.AppleMultitouchTrackpad                  TrackpadThreeFingerDrag

# Natural scrolling — single global key.
apply_bool TRACKPAD_NATURAL_SCROLL NSGlobalDomain com.apple.swipescrolldirection

# Tracking speed — float on global.
apply_float TRACKPAD_TRACKING_SPEED NSGlobalDomain com.apple.trackpad.scaling

log "done. Some changes take effect on next login."

# ============================================================================
# REVERT
#   defaults delete NSGlobalDomain com.apple.mouse.tapBehavior
#   defaults delete com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking
#   Reboot or sign out to fully revert.
# ============================================================================
