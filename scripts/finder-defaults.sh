#!/usr/bin/env bash
# ============================================================================
# finder-defaults.sh — Reproducible Finder configuration
# ============================================================================
#
# PHILOSOPHY
#   Configuration is data, mechanism is code.
#   The CONFIG section below is the only thing you edit. Each setting has:
#     - a clear WHY (explaining the tradeoff)
#     - a true/false (or named-value) toggle
#   The APPLY section reads your toggles and runs the right `defaults` calls.
#
# HOW TO USE
#   1. Edit the CONFIG section to taste. Flip true ↔ false per your preference.
#   2. To leave macOS's default behavior untouched for a setting, COMMENT THAT
#      LINE OUT (prefix with #). Unset variables are skipped during apply.
#   3. Run:    bash scripts/finder-defaults.sh
#   4. Re-run anytime — it's idempotent.
#
# REVERT
#   Flip the value (true → false), comment out, or `defaults delete` the key.
#   See the REVERT block at the bottom of this file for examples.
# ============================================================================

source "$(dirname "$0")/lib/common.sh"

# ============================================================================
# CONFIG — Edit me. Each WHY explains the tradeoff so you can decide.
# ============================================================================

# ─── Visibility ─────────────────────────────────────────────────────────────

# Show hidden files (dotfiles, ~/Library, etc.)
# WHY: Terminal-heavy workflow needs config files visible in Finder.
#      `Cmd+Shift+.` still toggles on the fly even when this is false.
FINDER_SHOW_HIDDEN=true

# Always show every file extension (no auto-hiding .txt/.pdf/etc.)
# WHY: Prevents disguised-extension surprises (image.png.exe).
#      Disambiguates files with the same base name.
FINDER_SHOW_ALL_EXTENSIONS=true

# ─── Navigation context ─────────────────────────────────────────────────────

# Path bar at bottom of every Finder window (breadcrumb)
# WHY: Click any path segment to jump there. Big nav speedup, zero downside.
FINDER_SHOW_PATHBAR=true

# Status bar at bottom (item count + free disk space)
# WHY: Free space + count at a glance, no Cmd+I needed.
FINDER_SHOW_STATUSBAR=true

# Show full POSIX path in window title
# WHY: Finder window title matches `pwd` in your terminal — same mental model.
FINDER_POSIX_PATH_IN_TITLE=true

# ─── Default behavior ───────────────────────────────────────────────────────

# Default view for folders without a custom setting.
# Options: "Nlsv" (list), "icnv" (icon), "clmv" (column), "Flwv" (gallery)
# WHY: List view shows size/date/kind columns and pairs well with
#      calculateAllSizes. Icon view wastes space for real work.
FINDER_DEFAULT_VIEW="Nlsv"

# Default search scope when you Cmd+F.
# Options: "SCev" (this Mac), "SCcf" (current folder), "SCsp" (previous scope)
# WHY: "This Mac" is almost never what you want — you usually want to search
#      inside the folder you're already in.
FINDER_DEFAULT_SEARCH_SCOPE="SCcf"

# Warn before changing a file extension
# WHY: false = no nag. You know what you're doing when you rename.
FINDER_EXTENSION_CHANGE_WARNING=false

# Where new Finder windows and Cmd+N open.
# Options: "PfHm" (home), "PfDe" (desktop), "PfDo" (documents), "PfLo" (custom)
# WHY: $HOME is a deterministic starting point; "Recents" is unpredictable.
FINDER_NEW_WINDOW_TARGET="PfHm"

# Open folders in tabs instead of new windows
# WHY: Keeps window count low; tabbed nav matches modern browser ergonomics.
FINDER_OPEN_IN_TABS=true

# Calculate all folder sizes in list view
# WHY: Folder sizes visible at a glance. TRADEOFF: slight Finder lag in huge
#      folders (Downloads, ~/Library, node_modules dirs, iCloud Drive).
#      Accept the lag, or set false and use `du -sh *` from terminal instead.
FINDER_CALCULATE_ALL_SIZES=true

# ─── Vault / shared-drive hygiene ───────────────────────────────────────────

# Don't write .DS_Store on network drives (SMB/NFS shares)
# WHY: Pollutes shared folders for non-Mac users; clutters git diffs if a
#      vault sits on a network share.
FINDER_NO_DS_STORE_NETWORK=true

# Don't write .DS_Store on USB drives
# WHY: Pollutes USB drives shared with Windows/Linux.
FINDER_NO_DS_STORE_USB=true

# ─── Speed / annoyance reductions ───────────────────────────────────────────

# Disable all Finder window/info animations
# WHY: Snappier feel; optimize for action speed, not eye candy.
FINDER_DISABLE_ANIMATIONS=true

# Allow Cmd+Q to quit Finder (Apple disables this by default)
# WHY: Lets you fully close Finder when you don't need it. Saves background CPU.
FINDER_ALLOW_QUIT=true

# Warn before emptying trash
# WHY: false = no friction. Cmd+Shift+Delete used confidently.
FINDER_WARN_EMPTY_TRASH=false

# Auto-delete items from trash after 30 days
# WHY: Self-cleaning trash; prevents forever-undeleted-files growth.
FINDER_AUTO_EMPTY_TRASH_30_DAYS=true

# ============================================================================
# APPLY — You shouldn't need to edit below this line.
# ============================================================================

PLIST="$HOME/Library/Preferences/com.apple.finder.plist"
PB=/usr/libexec/PlistBuddy

log "applying Finder defaults..."

# Visibility
apply_bool   FINDER_SHOW_HIDDEN              com.apple.finder      AppleShowAllFiles
apply_bool   FINDER_SHOW_ALL_EXTENSIONS      NSGlobalDomain        AppleShowAllExtensions

# Navigation context
apply_bool   FINDER_SHOW_PATHBAR             com.apple.finder      ShowPathbar
apply_bool   FINDER_SHOW_STATUSBAR           com.apple.finder      ShowStatusBar
apply_bool   FINDER_POSIX_PATH_IN_TITLE      com.apple.finder      _FXShowPosixPathInTitle

# Default behavior
apply_string FINDER_DEFAULT_VIEW             com.apple.finder      FXPreferredViewStyle
apply_string FINDER_DEFAULT_SEARCH_SCOPE     com.apple.finder      FXDefaultSearchScope
apply_bool   FINDER_EXTENSION_CHANGE_WARNING com.apple.finder      FXEnableExtensionChangeWarning
apply_string FINDER_NEW_WINDOW_TARGET        com.apple.finder      NewWindowTarget
# Window target path is fixed to $HOME when target = "PfHm"
if [ "${FINDER_NEW_WINDOW_TARGET:-}" = "PfHm" ]; then
  defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
  printf "  set    %-45s = file://%s/\n" "NewWindowTargetPath" "$HOME"
fi
apply_bool   FINDER_OPEN_IN_TABS             com.apple.finder      FinderSpawnTab

# Vault hygiene
apply_bool   FINDER_NO_DS_STORE_NETWORK      com.apple.desktopservices DSDontWriteNetworkStores
apply_bool   FINDER_NO_DS_STORE_USB          com.apple.desktopservices DSDontWriteUSBStores

# Speed / annoyance
apply_bool   FINDER_DISABLE_ANIMATIONS       com.apple.finder      DisableAllAnimations
apply_bool   FINDER_ALLOW_QUIT               com.apple.finder      QuitMenuItem
apply_bool   FINDER_WARN_EMPTY_TRASH         com.apple.finder      WarnOnEmptyTrash
apply_bool   FINDER_AUTO_EMPTY_TRASH_30_DAYS com.apple.finder      FXRemoveOldTrashItems

# ─── calculateAllSizes — nested keys, needs PlistBuddy ──────────────────────
# `defaults write` cannot reach into dictionary children, so we walk the
# known list-view containers and set the value in each.
if [ -n "${FINDER_CALCULATE_ALL_SIZES+x}" ]; then
  NESTED=(
    ":FK_StandardViewSettings:ListViewSettings:calculateAllSizes"
    ":FK_StandardViewSettings:ExtendedListViewSettingsV2:calculateAllSizes"
    ":FK_DefaultListViewSettingsV2:calculateAllSizes"
    ":FK_iCloudListViewSettingsV2:calculateAllSizes"
    ":ICloudViewSettings:ListViewSettings:calculateAllSizes"
    ":ICloudViewSettings:ExtendedListViewSettingsV2:calculateAllSizes"
    ":StandardViewSettings:ListViewSettings:calculateAllSizes"
    ":StandardViewSettings:ExtendedListViewSettingsV2:calculateAllSizes"
  )
  for path in "${NESTED[@]}"; do
    $PB -c "Set $path ${FINDER_CALCULATE_ALL_SIZES}" "$PLIST" 2>/dev/null \
      || $PB -c "Add $path bool ${FINDER_CALCULATE_ALL_SIZES}" "$PLIST" 2>/dev/null \
      || true
  done
  printf "  set    %-45s = %s (8 list-view variants)\n" \
    "calculateAllSizes" "${FINDER_CALCULATE_ALL_SIZES}"
else
  printf "  skip   %-45s (var %s unset)\n" \
    "calculateAllSizes" "FINDER_CALCULATE_ALL_SIZES"
fi

# ─── Apply ──────────────────────────────────────────────────────────────────
restart_app Finder
log "done. Finder restarted."
echo
echo "Verify a few keys:"
echo "  defaults read com.apple.finder AppleShowAllFiles"
echo "  defaults read com.apple.finder ShowPathbar"
echo "  defaults read com.apple.finder | grep -i calculateAllSizes"

# ============================================================================
# REVERT EXAMPLES (run manually as needed)
# ============================================================================
#
# Flip a single key off:
#   defaults write com.apple.finder AppleShowAllFiles -bool false
#   killall Finder
#
# Wipe a key entirely (revert to macOS default):
#   defaults delete com.apple.finder FXPreferredViewStyle
#   killall Finder
#
# Turn calculateAllSizes off everywhere:
#   FINDER_CALCULATE_ALL_SIZES=false bash scripts/finder-defaults.sh
#   (or set false in CONFIG above and re-run)
#
# Nuclear: reset all Finder prefs (loses other customizations too):
#   defaults delete com.apple.finder; killall Finder
# ============================================================================
