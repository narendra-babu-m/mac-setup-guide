#!/usr/bin/env bash
# ============================================================================
# safari-defaults.sh — Safari power-user + privacy defaults.
# Edit CONFIG section. Comment out a var to leave macOS default.
# NOTE: macOS Sonoma+ moved many of these into a sandboxed Safari container.
#       Some keys may no-op until you launch Safari at least once.
# ============================================================================

source "$(dirname "$0")/lib/common.sh"

# ============================================================================
# CONFIG
# ============================================================================

# Show the Develop menu in the menu bar
# WHY: Web Inspector access; needed any time you debug a webapp.
SAFARI_DEVELOP_MENU=true

# Show the full URL in the address bar (not just the domain)
# WHY: You read URLs to spot phishing / weird redirects. Show all of it.
SAFARI_SHOW_FULL_URL=true

# Don't auto-open "safe" downloads (DMGs, zips)
# WHY: Defense-in-depth — never auto-execute anything from a download.
SAFARI_AUTO_OPEN_SAFE_DOWNLOADS=false

# Show status bar (URL preview on link hover)
# WHY: Always know where a link points before clicking.
SAFARI_SHOW_STATUS_BAR=true

# Block all cross-site tracking
# WHY: Privacy default; if a site breaks, override per-site in Safari Settings.
SAFARI_BLOCK_CROSS_SITE_TRACKING=true

# Send "Do Not Track" header
# WHY: Symbolic, but cheap. Enabled by default in modern Safari anyway.
SAFARI_SEND_DNT=true

# ============================================================================
# APPLY
# ============================================================================

log "applying Safari defaults..."
log "(safari may need to launch once for sandboxed prefs to register)"

apply_bool SAFARI_DEVELOP_MENU                com.apple.Safari IncludeDevelopMenu
apply_bool SAFARI_DEVELOP_MENU                com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey
apply_bool SAFARI_DEVELOP_MENU                com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled"

apply_bool SAFARI_SHOW_FULL_URL               com.apple.Safari ShowFullURLInSmartSearchField
apply_bool SAFARI_AUTO_OPEN_SAFE_DOWNLOADS    com.apple.Safari AutoOpenSafeDownloads
apply_bool SAFARI_SHOW_STATUS_BAR             com.apple.Safari ShowOverlayStatusBar
apply_bool SAFARI_BLOCK_CROSS_SITE_TRACKING   com.apple.Safari WebKitPreferences.storageBlockingPolicy
apply_bool SAFARI_SEND_DNT                    com.apple.Safari SendDoNotTrackHTTPHeader

log "done. Restart Safari to see changes."

# ============================================================================
# REVERT
#   defaults delete com.apple.Safari <key>
#   Restart Safari.
# ============================================================================
