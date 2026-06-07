#!/usr/bin/env bash
# ============================================================================
# security-defaults.sh — Sensible security baseline.
# Edit CONFIG section. Comment out a var to leave macOS default.
#
# IMPORTANT: On MDM-managed Macs (corporate / SAP), some security settings
# are governed by configuration profiles that override `defaults` writes.
# Verify with `profiles status -type configuration` (sudo required for full).
# ============================================================================

source "$(dirname "$0")/lib/common.sh"

# ============================================================================
# CONFIG
# ============================================================================

# Require password immediately when screen sleeps / saver activates
# WHY: A Mac left at a desk should lock the moment it sleeps.
SEC_REQUIRE_PASSWORD=true

# Password delay (seconds, 0 = immediately on wake)
# WHY: 0 = no grace period. Pair with SEC_REQUIRE_PASSWORD=true.
SEC_PASSWORD_DELAY=0

# Auto-lock screen saver after N minutes of idle
# WHY: 5 minutes balances security with not nagging during reading/thinking.
#      Set 0 to never auto-start screen saver.
SEC_IDLE_LOCK_MINUTES=5

# ============================================================================
# APPLY
# ============================================================================

log "applying Security defaults..."

if [ -n "${SEC_REQUIRE_PASSWORD+x}" ]; then
  if [ "$SEC_REQUIRE_PASSWORD" = "true" ]; then
    defaults write com.apple.screensaver askForPassword -int 1
  else
    defaults write com.apple.screensaver askForPassword -int 0
  fi
  log "    set    askForPassword = $SEC_REQUIRE_PASSWORD"
fi

apply_int SEC_PASSWORD_DELAY com.apple.screensaver askForPasswordDelay

if [ -n "${SEC_IDLE_LOCK_MINUTES+x}" ]; then
  defaults -currentHost write com.apple.screensaver idleTime -int "$((SEC_IDLE_LOCK_MINUTES * 60))"
  log "    set    idleTime = ${SEC_IDLE_LOCK_MINUTES}min ($((SEC_IDLE_LOCK_MINUTES * 60))s)"
fi

log "done. Verify in System Settings → Lock Screen."
log ""
log "Manual security checklist (NOT scriptable, see MANUAL_STEPS.md):"
log "  - FileVault enabled (System Settings -> Privacy & Security)"
log "  - Firewall enabled (System Settings -> Network -> Firewall)"
log "  - Touch ID for sudo (edit /etc/pam.d/sudo)"
log "  - Find My Mac signed in"

# ============================================================================
# REVERT
#   defaults delete com.apple.screensaver askForPassword
#   defaults delete com.apple.screensaver askForPasswordDelay
#   defaults -currentHost delete com.apple.screensaver idleTime
# ============================================================================
