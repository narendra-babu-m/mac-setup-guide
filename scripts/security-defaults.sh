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
# Type: int (1 = require, 0 = no). Stored as int even though it's a bool concept.
SEC_REQUIRE_PASSWORD=1

# Password delay (seconds). 0 = require immediately on wake.
# WHY: 0 = no grace period. Pair with SEC_REQUIRE_PASSWORD=1.
SEC_PASSWORD_DELAY=0

# Auto-lock screen saver after N minutes of idle
# WHY: 5 minutes balances security with not nagging during reading/thinking.
#      Set 0 to never auto-start screen saver.
SEC_IDLE_LOCK_MINUTES=5

# ============================================================================
# APPLY
# ============================================================================

log "applying Security defaults..."

apply_int             SEC_REQUIRE_PASSWORD com.apple.screensaver askForPassword
apply_int             SEC_PASSWORD_DELAY   com.apple.screensaver askForPasswordDelay

# Idle lock is stored on the per-host scope as seconds, not minutes — convert.
if [ -n "${SEC_IDLE_LOCK_MINUTES+x}" ]; then
  SEC_IDLE_LOCK_SECONDS=$((SEC_IDLE_LOCK_MINUTES * 60))
  apply_int_currenthost SEC_IDLE_LOCK_SECONDS com.apple.screensaver idleTime
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
