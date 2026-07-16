#!/usr/bin/env bash
# ============================================================================
# default-apps.sh — Bind macOS Launch Services UTI → app defaults via duti.
#
# WHY THIS EXISTS
# ---------------
# Xcode aggressively claims ownership of every source-code UTI Apple has ever
# defined (public.swift-source, public.c-source, public.objective-c-source,
# public.json, public.xml, public.yaml, com.apple.property-list, and dozens
# more). On a fresh Mac, double-clicking a .swift/.json/.md/.plist opens Xcode
# — which is heavy, slow, and unwanted for anything but real Xcode projects.
# This script routes source + text/config files to VS Code (the daily editor)
# and leaves TRUE Xcode-native artefacts (.xcodeproj, .xcworkspace, .xib,
# .storyboard, .playground, .entitlements, .swiftpm) alone.
#
# HOW IT WORKS
# ------------
# `duti -s <bundle-id> <UTI> all` writes an LSHandler entry that overrides
# whatever the app claims via its Info.plist. UTI-level binding wins over
# extension-level binding on macOS 26+, so we bind by UTI where possible
# and only fall back to extension binding for the few UTIs LS refuses
# (e.g. `com.unknown.md` — deprecated, still shows up in LS DB).
#
# Discovered 2026-07-16 during a work-Mac audit: after macOS 26 upgrade,
# Xcode had grabbed 20+ common file extensions. This script is the fresh-
# Mac equivalent of that fix.
#
# REQUIREMENTS
# ------------
#   - duti (Brewfile: `brew "duti"`)
#   - Visual Studio Code installed (com.microsoft.VSCode)
# ============================================================================

source "$(dirname "$0")/lib/common.sh"

# ============================================================================
# CONFIG — comment out any line to leave that UTI at whatever macOS picks.
# ============================================================================

# Target app for source + text/config files.
# WHY: VS Code is Naren's daily editor. If it's missing, script warns & skips.
EDITOR_BUNDLE_ID="com.microsoft.VSCode"
EDITOR_APP_PATH="/Applications/Visual Studio Code.app"

# UTIs to bind to the editor.
# Grouped by intent. Comment out a line to skip that UTI.
# WHY: These are the Xcode-squatted UTIs discovered 2026-07-16 on macOS 26.5.1.
EDITOR_UTIS=(
  # --- source code ---
  public.swift-source                      # .swift
  public.objective-c-source                # .m
  public.objective-c-plus-plus-source      # .mm
  public.c-source                          # .c
  public.c-plus-plus-source                # .cc .cpp .cxx
  public.c-header                          # .h
  public.c-plus-plus-header                # .hpp .hxx
  public.ruby-script                       # .rb
  public.bash-script                       # .bash
  public.zsh-script                        # .zsh
  public.shell-script                      # .sh (usually wins vs Terminal/iTerm)

  # --- text / config ---
  public.json                              # .json
  public.xml                               # .xml
  public.yaml                              # .yaml .yml
  com.apple.property-list                  # .plist (all flavours)
  com.apple.xml-property-list              # .plist XML form
  com.apple.binary-property-list           # .plist binary form
  com.apple.dt.document.ascii-property-list # .plist ASCII form
  net.daringfireball.markdown              # .md (Daring Fireball UTI)
  com.topografix.gpx                       # .gpx

  # Note: `.txt` intentionally left with TextEdit (macOS default; usually right).
  # Note: `.html`/`.htm` intentionally left with the user's browser.
  # Note: `.log` intentionally left with Console.app.
  # Note: `.csv` intentionally left with Microsoft Excel.
)

# UTIs LS refuses to bind properly — fall back to extension binding.
# WHY: `public.markdown` and `com.unknown.md` don't conform to a UTI hierarchy
# on macOS 26 (duti warns). But extension-level binding on `.md` still works
# because net.daringfireball.markdown covers it via UTI-first resolution.
# Left empty for now; add exts here if a UTI ever refuses.
EDITOR_EXT_FALLBACKS=(
  # Format: "ext"
  # e.g. "md"
)

# ============================================================================
# APPLY
# ============================================================================

if ! command -v duti >/dev/null 2>&1; then
  warn "duti not installed — install via 'brew install duti' or run bootstrap.sh Phase 1"
  exit 0  # non-fatal: fresh Mac may run this before duti is installed
fi

if [ ! -d "$EDITOR_APP_PATH" ]; then
  warn "$EDITOR_APP_PATH not found — skipping default-apps binding"
  warn "install Visual Studio Code first (Brewfile: cask \"visual-studio-code\")"
  exit 0  # non-fatal
fi

log "binding UTIs → $EDITOR_BUNDLE_ID"
bound=0
failed=0
for uti in "${EDITOR_UTIS[@]}"; do
  # duti prints a "does not conform to any UTI hierarchy" warning to stderr
  # and exits 0 even on that soft failure. Capture and count real successes.
  err=$(duti -s "$EDITOR_BUNDLE_ID" "$uti" all 2>&1 1>/dev/null || true)
  if [ -n "$err" ]; then
    warn "  $uti: $err"
    failed=$((failed + 1))
  else
    printf "    bound  %s\n" "$uti"
    bound=$((bound + 1))
  fi
done

if [ ${#EDITOR_EXT_FALLBACKS[@]} -gt 0 ]; then
  log "extension-level fallbacks"
  for ext in "${EDITOR_EXT_FALLBACKS[@]}"; do
    duti -s "$EDITOR_BUNDLE_ID" "$ext" all 2>/dev/null && printf "    bound  .%s\n" "$ext"
  done
fi

log "done. $bound UTI(s) bound, $failed skipped."
log "verify with: duti -x swift  (should return VS Code)"
log ""
log "TRUE Xcode-native files (deliberately NOT rebound — stay with Xcode):"
log "  .xcodeproj .xcworkspace .playground .swiftpm .storyboard .xib .entitlements"

# ============================================================================
# REVERT
# ---------
# To send a UTI back to Xcode:
#   duti -s com.apple.dt.Xcode <uti> all
# To scan what's currently bound where:
#   for uti in "${EDITOR_UTIS[@]}"; do echo "$uti → $(duti -x "$uti" | head -1)"; done
# To nuke all overrides and let LS re-derive from Info.plists:
#   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
#   (NOTE: -kill was removed on Sonoma+; on Tahoe use System Settings toggles)
# ============================================================================
