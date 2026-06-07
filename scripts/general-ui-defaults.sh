#!/usr/bin/env bash
# ============================================================================
# general-ui-defaults.sh — System-wide UI ergonomics, dialogs, save panel.
# Edit CONFIG section. Comment out a var to leave macOS default.
# ============================================================================

source "$(dirname "$0")/lib/common.sh"

# ============================================================================
# CONFIG
# ============================================================================

# Always expand the save panel by default (full file picker, not collapsed)
# WHY: Skips one click on every save dialog ever.
UI_EXPAND_SAVE_PANEL=true

# Always expand the print panel by default
# WHY: Same reason — skip the "More options" click.
UI_EXPAND_PRINT_PANEL=true

# Disable the "Are you sure you want to open this app?" warning
# WHY: For apps you've already approved once. Gatekeeper still gates first launch.
UI_DISABLE_OPEN_APP_WARNING=true

# Disable the resume feature (don't reopen documents/windows on relaunch)
# WHY: Cleaner relaunch state; no zombie windows from yesterday.
UI_DISABLE_RESUME=true

# Save to disk (not iCloud) by default
# WHY: Avoids accidentally putting work into iCloud Drive without intent.
UI_SAVE_TO_DISK=true

# Sidebar icon size: 1=small, 2=medium, 3=large
# WHY: Medium hits the readability/density sweet spot.
UI_SIDEBAR_ICON_SIZE=2

# Show scroll bars: "WhenScrolling", "Automatic", "Always"
# WHY: WhenScrolling is the cleanest — appears when you need it.
UI_SCROLLBAR_BEHAVIOR="WhenScrolling"

# Use F1, F2, … as standard function keys (need fn for media keys)
# WHY: F-keys matter for IDEs, debuggers, terminals. Media keys are rarer.
UI_FN_KEYS_AS_STANDARD=true

# Disable rubber-band scrolling
# WHY: Optional — leave commented unless it actively annoys you.
# UI_DISABLE_RUBBER_BAND=true

# ============================================================================
# APPLY
# ============================================================================

log "applying General UI defaults..."

apply_bool          UI_EXPAND_SAVE_PANEL        NSGlobalDomain NSNavPanelExpandedStateForSaveMode
apply_bool          UI_EXPAND_SAVE_PANEL        NSGlobalDomain NSNavPanelExpandedStateForSaveMode2
apply_bool          UI_EXPAND_PRINT_PANEL       NSGlobalDomain PMPrintingExpandedStateForPrint
apply_bool          UI_EXPAND_PRINT_PANEL       NSGlobalDomain PMPrintingExpandedStateForPrint2
apply_bool          UI_DISABLE_OPEN_APP_WARNING com.apple.LaunchServices LSQuarantine
apply_bool          UI_DISABLE_RESUME           NSGlobalDomain NSDisableAutomaticTermination

# UI_SAVE_TO_DISK=true → NSDocumentSaveNewDocumentsToCloud=false (inverted)
apply_bool_inverted UI_SAVE_TO_DISK             NSGlobalDomain NSDocumentSaveNewDocumentsToCloud

apply_int           UI_SIDEBAR_ICON_SIZE        NSGlobalDomain NSTableViewDefaultSizeMode
apply_string        UI_SCROLLBAR_BEHAVIOR       NSGlobalDomain AppleShowScrollBars
apply_bool          UI_FN_KEYS_AS_STANDARD      NSGlobalDomain com.apple.keyboard.fnState
apply_bool          UI_DISABLE_RUBBER_BAND      NSGlobalDomain NSScrollViewRubberbanding

log "done. Some settings need a restart of the affected app."

# ============================================================================
# REVERT
#   defaults delete NSGlobalDomain <key>
# ============================================================================
