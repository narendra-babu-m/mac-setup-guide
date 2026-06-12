#!/usr/bin/env bash
# ============================================================================
# dock-defaults.sh — Reproducible Dock + Mission Control configuration.
# Edit the CONFIG section. Comment out a var to leave macOS default.
# ============================================================================

source "$(dirname "$0")/lib/common.sh"

# ============================================================================
# CONFIG
# ============================================================================

# Auto-hide the Dock
# WHY: Reclaims vertical screen space; Dock is a launcher, not a status bar.
#      Use Raycast / Cmd+Tab instead.
DOCK_AUTOHIDE=true

# Dock auto-hide animation duration (seconds)
# WHY: Default is ~0.5s. Set to 0 = instant feel.
DOCK_AUTOHIDE_TIME_MODIFIER=0

# Dock show/hide delay (seconds before it appears on hover)
# WHY: 0 = no lag when you push the cursor to the edge.
DOCK_AUTOHIDE_DELAY=0

# Icon size (pixels)
# WHY: 54 is the macOS default. Tried 42 (smaller, more screen real estate)
#      but the icons became hard to target on a 13" laptop screen and the
#      ergonomic gain wasn't worth the squint. 54 won the live test.
DOCK_TILESIZE=54

# Magnification on hover
# WHY: Originally off ("cute, distracting"). Live experience: with autohide
#      on + tilesize 54, magnification adds useful target feedback and the
#      "distraction" never materialised. Adopted.
DOCK_MAGNIFICATION=true

# Don't show recently used apps in Dock
# WHY: You launch via Raycast/Spotlight; recents column is noise.
DOCK_SHOW_RECENTS=false

# Minimize windows into application icon (not their own dock tile)
# WHY: Keeps Dock compact; Cmd+Tab + click reopens.
DOCK_MINIMIZE_TO_APPLICATION=true

# Animation when minimizing windows: "genie", "scale", "suck"
# WHY: "scale" is the fastest perceptually.
DOCK_MIN_EFFECT="scale"

# Show indicator dots for open applications
# WHY: Quick visual cue for what's running.
DOCK_SHOW_PROCESS_INDICATORS=true

# Position on screen: "bottom", "left", "right"
# WHY: Bottom is muscle memory for most macOS users.
DOCK_ORIENTATION="bottom"

# Speed up Mission Control animations (seconds)
# WHY: Default ~0.2s; halve it for snappier desktop switching.
DOCK_MISSION_CONTROL_TIME=0.1

# Don't automatically rearrange Spaces based on most recent use
# WHY: Stable Space order = stable muscle memory (Ctrl+1, Ctrl+2, …).
MC_REARRANGE_SPACES=false

# Group windows by application in Mission Control
# WHY: Easier to spot the right window in a sea of thumbnails.
MC_GROUP_BY_APP=true

# ============================================================================
# APPLY
# ============================================================================

log "applying Dock + Mission Control defaults..."

apply_bool   DOCK_AUTOHIDE                   com.apple.dock autohide
apply_float  DOCK_AUTOHIDE_TIME_MODIFIER     com.apple.dock autohide-time-modifier
apply_float  DOCK_AUTOHIDE_DELAY             com.apple.dock autohide-delay
apply_int    DOCK_TILESIZE                   com.apple.dock tilesize
apply_bool   DOCK_MAGNIFICATION              com.apple.dock magnification
apply_bool   DOCK_SHOW_RECENTS               com.apple.dock show-recents
apply_bool   DOCK_MINIMIZE_TO_APPLICATION    com.apple.dock minimize-to-application
apply_string DOCK_MIN_EFFECT                 com.apple.dock mineffect
apply_bool   DOCK_SHOW_PROCESS_INDICATORS    com.apple.dock show-process-indicators
apply_string DOCK_ORIENTATION                com.apple.dock orientation
apply_float  DOCK_MISSION_CONTROL_TIME       com.apple.dock expose-animation-duration
apply_bool   MC_REARRANGE_SPACES             com.apple.dock mru-spaces
apply_bool   MC_GROUP_BY_APP                 com.apple.dock expose-group-apps

restart_app Dock
log "done. Dock restarted."

# ============================================================================
# REVERT
#   defaults write com.apple.dock autohide -bool false
#   defaults delete com.apple.dock <key>
#   killall Dock
# ============================================================================
