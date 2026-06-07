#!/usr/bin/env bash
# ============================================================================
# screenshot-defaults.sh — Reproducible screencapture (Cmd+Shift+3/4/5) config.
# Edit CONFIG section. Comment out a var to leave macOS default.
# ============================================================================

source "$(dirname "$0")/lib/common.sh"

# ============================================================================
# CONFIG
# ============================================================================

# Where screenshots are saved (created if missing).
# Detection order:
#   1. SCREENSHOT_LOCATION_OVERRIDE — set explicitly to skip detection.
#   2. ~/Library/CloudStorage/OneDrive-* (work Mac with OneDrive synced)
#         → uses <onedrive>/Screenshots so screenshots back up automatically.
#   3. ~/Pictures/Screenshots (personal Mac fallback, conventional choice).
# WHY: On the work Mac, OneDrive is the de-facto shared drop-zone — keeping
#      screenshots inside it means they survive disk wipe and are reachable
#      from Windows / Teams / browser without copy-paste.
#      On a personal Mac without OneDrive, ~/Pictures/Screenshots is the
#      cleanest non-Desktop home that Spotlight + Photos already index.
#      The DECISION is data-driven: filesystem state at run-time, not user
#      mood. Re-running the script always resolves to the same path.
if [ -n "${SCREENSHOT_LOCATION_OVERRIDE:-}" ]; then
  SCREENSHOT_LOCATION="$SCREENSHOT_LOCATION_OVERRIDE"
elif _onedrive=$(ls -d "$HOME"/Library/CloudStorage/OneDrive-* 2>/dev/null | head -1) && [ -n "$_onedrive" ]; then
  SCREENSHOT_LOCATION="$_onedrive/Screenshots"
else
  SCREENSHOT_LOCATION="$HOME/Pictures/Screenshots"
fi

# File format: "png", "jpg", "pdf", "tiff"
# WHY: PNG is lossless and pastes cleanly into docs/issues.
SCREENSHOT_FORMAT="png"

# Disable the drop-shadow on window screenshots (Cmd+Shift+4 → Space)
# WHY: Cleaner crops for documentation / issue reports.
SCREENSHOT_DISABLE_SHADOW=true

# Filename prefix
# WHY: Default "Screen Shot 2026-…" has a space; programmatic-friendly = no space.
SCREENSHOT_NAME="Screenshot"

# Show thumbnail in the corner after capture
# WHY: Lets you mark up / drag-and-drop without opening the file.
SCREENSHOT_SHOW_THUMBNAIL=true

# Include cursor in screenshots
# WHY: Usually you want the cursor *out* of docs; turn on selectively in app.
SCREENSHOT_INCLUDE_CURSOR=false

# ============================================================================
# APPLY
# ============================================================================

log "applying Screenshot defaults..."

if [ -n "${SCREENSHOT_LOCATION+x}" ]; then
  mkdir -p "$SCREENSHOT_LOCATION"
fi

apply_string SCREENSHOT_LOCATION       com.apple.screencapture location
apply_string SCREENSHOT_FORMAT         com.apple.screencapture type
apply_bool   SCREENSHOT_DISABLE_SHADOW com.apple.screencapture disable-shadow
apply_string SCREENSHOT_NAME           com.apple.screencapture name
apply_bool   SCREENSHOT_SHOW_THUMBNAIL com.apple.screencapture show-thumbnail
apply_bool   SCREENSHOT_INCLUDE_CURSOR com.apple.screencapture showsCursor

restart_app SystemUIServer
log "done. SystemUIServer restarted."

# ============================================================================
# REVERT
#   defaults delete com.apple.screencapture <key>
#   killall SystemUIServer
# ============================================================================
