#!/usr/bin/env bash
# ============================================================================
# iterm2-setup.sh — Restore iTerm2 configuration on a fresh Mac.
#
# Pattern: canonical "Load prefs from custom folder" mechanism, NOT symlink.
# [SOURCE: gitlab.com/gnachman/iterm2 wiki — official iTerm2 migration guide]
# [SOURCE: subagent research deliverable 2026-11-03]
#
# USAGE:
#   bash scripts/iterm2-setup.sh
#
# ONE-TIME EXPORT (do this on OLD Mac before first run):
#   Open iTerm2 → Settings (⌘,) → General → Settings tab →
#   Enable "Load preferences from a custom folder or URL" →
#   Set folder to <mac-setup-guide>/dotfiles/iterm2/ →
#   Click "Save Current Settings to Folder" →
#   Convert to XML for diffable git: plutil -convert xml1 <path>/com.googlecode.iterm2.plist
#   Then sanitize (NoSync*, NSWindow Frame*, SU*, absolute paths) → commit.
#
# WHAT THIS SCRIPT DOES ON NEW MAC:
#   1. Verifies dotfiles/iterm2/ exists in repo (fails fast if not exported yet)
#   2. Copies plist to ~/.config/iterm2/ (NOT a symlink — cfprefsd ignores symlinks)
#   3. Tells iTerm2 to load prefs from that folder via `defaults write`
#   4. Installs Dynamic Profiles to ~/Library/Application Support/iTerm2/DynamicProfiles/
#   5. Downloads shell integration script to ~/.iterm2_shell_integration.zsh
#   6. Applies security hardening (CVE-2024-38395 — disable window title reporting)
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ITERM_DOTFILES="$REPO_ROOT/dotfiles/iterm2"
ITERM_STAGING="$HOME/.config/iterm2"
ITERM_APP_SUPPORT="$HOME/Library/Application Support/iTerm2"
DYNAMIC_PROFILES_DIR="$ITERM_APP_SUPPORT/DynamicProfiles"
SHELL_INT="$HOME/.iterm2_shell_integration.zsh"

log()  { printf "  [iterm2-setup] %s\n" "$*"; }
warn() { printf "  [iterm2-setup] WARN: %s\n" "$*" >&2; }

# ── Prereq: iTerm2 installed? ────────────────────────────────────────────────
if [ ! -d "/Applications/iTerm.app" ]; then
  warn "iTerm.app not found in /Applications. Install first: brew install --cask iterm2"
  exit 0
fi

# ── Prereq: plist exported from old Mac? ─────────────────────────────────────
if [ ! -f "$ITERM_DOTFILES/com.googlecode.iterm2.plist" ]; then
  warn "No plist in $ITERM_DOTFILES/"
  warn "This is expected on first run — export from your OLD Mac first:"
  warn "  1. iTerm2 → Settings → General → Settings tab"
  warn "  2. Enable 'Load preferences from a custom folder or URL'"
  warn "  3. Set folder: $ITERM_DOTFILES"
  warn "  4. Click 'Save Current Settings to Folder'"
  warn "  5. plutil -convert xml1 $ITERM_DOTFILES/com.googlecode.iterm2.plist"
  warn "  6. Sanitize (NoSync*, NSWindow Frame*, SU*, /Users/<name>)"
  warn "  7. git add + commit + push"
  warn "  8. Re-run this script on the new Mac after pulling."
  log "Skipping plist restore (nothing exported yet)."
else
  # ── Step 1: Quit iTerm2 so cfprefsd doesn't overwrite our writes ───────────
  # [SOURCE: synclet.dev — "quit iTerm2 before defaults write"]
  if pgrep -x iTerm2 >/dev/null 2>&1 || pgrep -x iTerm >/dev/null 2>&1; then
    warn "iTerm2 is running. Please quit it (⌘Q), then re-run this script."
    warn "cfprefsd flushes in-memory state over on-disk changes if iTerm2 is alive."
    exit 1
  fi

  # ── Step 2: Stage plist in ~/.config/iterm2/ ───────────────────────────────
  mkdir -p "$ITERM_STAGING"
  cp "$ITERM_DOTFILES/com.googlecode.iterm2.plist" "$ITERM_STAGING/com.googlecode.iterm2.plist"
  log "Plist staged at $ITERM_STAGING"

  # ── Step 3: Tell iTerm2 to load from custom folder ─────────────────────────
  # [SOURCE: iterm2.com/documentation-preferences-general.html]
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$ITERM_STAGING"
  log "LoadPrefsFromCustomFolder=true, PrefsCustomFolder=$ITERM_STAGING"
  log "Next iTerm2 launch will read your settings from the staged folder."
fi

# ── Step 4: Dynamic Profiles ─────────────────────────────────────────────────
# [SOURCE: iterm2.com/documentation-dynamic-profiles.html]
mkdir -p "$DYNAMIC_PROFILES_DIR"
if [ -d "$ITERM_DOTFILES/DynamicProfiles" ]; then
  for jf in "$ITERM_DOTFILES/DynamicProfiles"/*.json; do
    [ -e "$jf" ] || continue
    cp "$jf" "$DYNAMIC_PROFILES_DIR/$(basename "$jf")"
    log "Dynamic profile: $(basename "$jf")"
  done
else
  log "No dynamic profiles to install (dotfiles/iterm2/DynamicProfiles/ not present)"
fi

# ── Step 5: Shell integration script ─────────────────────────────────────────
# [SOURCE: iterm2.com/documentation-shell-integration.html]
# [SOURCE: subagent research — brew has no formula, must curl from iterm2.com]
if [ -f "$SHELL_INT" ]; then
  log "Shell integration already installed: $SHELL_INT"
else
  log "Downloading iTerm2 shell integration..."
  if curl -fsSL "https://iterm2.com/shell_integration/zsh" -o "$SHELL_INT"; then
    log "Shell integration downloaded ✓"
    log "Source it from .zshrc AFTER oh-my-zsh:"
    log "  [[ \$TERM_PROGRAM == 'iTerm.app' ]] && [[ -f ~/.iterm2_shell_integration.zsh ]] && source ~/.iterm2_shell_integration.zsh"
  else
    warn "Failed to download shell integration — check network"
  fi
fi

# ── Step 6: Security — disable window title reporting ────────────────────────
# CVE-2024-38395/38396: title reporting + tmux integration = RCE
# [SOURCE: vin01.github.io iTerm2 RCE writeup]
# Only applies if plist was restored (otherwise iTerm2 uses its default)
if [ -f "$ITERM_STAGING/com.googlecode.iterm2.plist" ]; then
  defaults write com.googlecode.iterm2 "AllowTitleReportingBase64" -bool false 2>/dev/null || true
  log "Security: window title reporting disabled (CVE-2024-38395 mitigation)"
fi

log ""
log "iTerm2 setup done."
log ""
log "Manual verification steps on new Mac:"
log "  1. Launch iTerm2 (first launch applies the custom-folder prefs)"
log "  2. Verify profiles: iTerm2 → Settings → Profiles — your 4 profiles should appear"
log "  3. Verify theme/colors look right"
log "  4. If using Zellij: shell integration DOES NOT work inside Zellij panes — expected"
log "  5. CVE check: Settings → Profiles → Terminal → 'Terminal may report window title' MUST be OFF"
