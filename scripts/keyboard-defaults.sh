#!/usr/bin/env bash
# ============================================================================
# keyboard-defaults.sh — Keyboard repeat, accent menu, full keyboard access.
# Edit CONFIG section. Comment out a var to leave macOS default.
# ============================================================================

source "$(dirname "$0")/lib/common.sh"

# ============================================================================
# CONFIG
# ============================================================================

# Key repeat rate (lower = faster). Range: 1-120. Slider min in System Settings = 2.
# WHY: 2 = fastest possible key repeat. Critical for vim/code editing.
KB_KEY_REPEAT=2

# Initial delay before repeat starts (lower = faster). Range: 15-120.
# WHY: 15 = shortest delay. Hold-to-repeat triggers almost instantly.
KB_INITIAL_KEY_REPEAT=15

# Disable press-and-hold for accented characters (so holding "e" repeats "eeee")
# WHY: vim/coding ergonomics — you want repeat, not á/à/â menu.
KB_DISABLE_PRESS_AND_HOLD=true

# Full keyboard access: Tab moves focus to ALL controls (not just text/lists)
# WHY: Lets you operate dialogs without touching the mouse.
#      Value: 0 = text/lists only (default), 2 = all controls.
KB_FULL_KEYBOARD_ACCESS=2

# Disable smart quotes (curly “”)
# WHY: Code, JSON, and shell paste cleanly without curly-quote corruption.
KB_DISABLE_SMART_QUOTES=true

# Disable smart dashes (-- → —)
# WHY: Per Naren's "humanize" rule — em/en-dashes are an AI tell.
#      Also breaks code/markdown when typed in normal text.
KB_DISABLE_SMART_DASHES=true

# Disable auto-capitalization
# WHY: Code, commit messages, and filenames are case-sensitive — no surprises.
KB_DISABLE_AUTO_CAPITALIZATION=true

# Disable auto-correct
# WHY: It miscorrects technical terms 100% of the time.
KB_DISABLE_AUTO_CORRECT=true

# Disable period substitution (double-space → period)
# WHY: Catches you in markdown/code where double-space is meaningful.
KB_DISABLE_PERIOD_SUBSTITUTION=true

# Disable automatic spelling correction (the underline + change)
# WHY: Spell-check yes, auto-rewrite no.
KB_DISABLE_AUTOMATIC_SPELLING=true

# ============================================================================
# APPLY
# ============================================================================
#
# NOTE on naming: variables read as "DISABLE_X=true" but the underlying plist
# key is "FeatureEnabled". apply_bool_inverted handles the flip so the CONFIG
# section reads naturally (DISABLE=true → Enabled=false).

log "applying Keyboard defaults..."

apply_int          KB_KEY_REPEAT                  NSGlobalDomain KeyRepeat
apply_int          KB_INITIAL_KEY_REPEAT          NSGlobalDomain InitialKeyRepeat
apply_bool_inverted KB_DISABLE_PRESS_AND_HOLD     NSGlobalDomain ApplePressAndHoldEnabled
apply_int          KB_FULL_KEYBOARD_ACCESS        NSGlobalDomain AppleKeyboardUIMode

apply_bool_inverted KB_DISABLE_SMART_QUOTES         NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled
apply_bool_inverted KB_DISABLE_SMART_DASHES         NSGlobalDomain NSAutomaticDashSubstitutionEnabled
apply_bool_inverted KB_DISABLE_AUTO_CAPITALIZATION  NSGlobalDomain NSAutomaticCapitalizationEnabled
apply_bool_inverted KB_DISABLE_AUTO_CORRECT         NSGlobalDomain NSAutomaticTextCompletionEnabled
apply_bool_inverted KB_DISABLE_PERIOD_SUBSTITUTION  NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled
apply_bool_inverted KB_DISABLE_AUTOMATIC_SPELLING   NSGlobalDomain NSAutomaticSpellingCorrectionEnabled

log "done. Sign out + back in for keyboard repeat changes to take full effect."

# ============================================================================
# REVERT
#   defaults delete NSGlobalDomain KeyRepeat
#   defaults delete NSGlobalDomain InitialKeyRepeat
#   defaults write  NSGlobalDomain ApplePressAndHoldEnabled -bool true
# ============================================================================
