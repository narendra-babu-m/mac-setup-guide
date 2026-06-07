#!/usr/bin/env bash
# ============================================================================
# sync.sh — Pull current Mac state back into the repo.
#
# Run this AFTER you install/change something on your Mac so the repo stays
# the source of truth. Without this, the repo drifts and "fresh-Mac in a day"
# stops working.
#
# Usage:
#   bash sync.sh           # update Brewfile (and dump current defaults — TODO)
#   bash sync.sh --dry     # show what would change, no writes
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
DRY=false
[ "${1:-}" = "--dry" ] && DRY=true

bold()    { printf "\033[1m%s\033[0m\n" "$*"; }
section() { printf "\n\033[1;34m── %s ──\033[0m\n" "$*"; }

# ── Brewfile sync ──────────────────────────────────────────────────────────
section "Brewfile sync"

if [ "$DRY" = "true" ]; then
  bold "DRY: would write Brewfile from current brew bundle"
  brew bundle dump --file=- --force | head -30
  echo "(diff would be against $REPO_ROOT/Brewfile)"
else
  TMP=$(mktemp)
  trap 'rm -f "$TMP"' EXIT

  # Dump everything currently installed (formulae, casks, taps, mas)
  brew bundle dump --file="$TMP" --force

  if diff -q "$REPO_ROOT/Brewfile" "$TMP" >/dev/null 2>&1; then
    echo "  ✓ Brewfile already in sync"
  else
    echo "  Δ Brewfile drift detected:"
    diff "$REPO_ROOT/Brewfile" "$TMP" | head -40 || true
    echo
    bold "Updating $REPO_ROOT/Brewfile from current state"
    cp "$TMP" "$REPO_ROOT/Brewfile"
    echo "  ✓ written. Review the diff and commit:"
    echo "     cd $REPO_ROOT && git diff Brewfile"
    echo "     git add Brewfile && git commit -m 'chore(brewfile): sync from \$(hostname)'"
  fi
fi

# ── TODO: defaults sync ────────────────────────────────────────────────────
# Future: read every defaults domain we manage and report drift between the
# values you've changed via System Settings vs what's in scripts/*-defaults.sh.
# For now, edit the script's CONFIG block manually if you change something via
# System Settings and want it reproducible.

section "Reminders"
cat <<EOF

Things sync.sh does NOT capture (you must edit the relevant script + commit):
  • Changes you made via System Settings (Dock, Finder, Keyboard, etc.)
    → edit scripts/<area>-defaults.sh, flip the var, commit
  • New Login Items (System Settings → General → Login Items)
    → document in MANUAL_STEPS.md (not scriptable on Sonoma+)
  • Raycast extensions, VS Code extensions, browser extensions
    → these have their own sync mechanisms (sign in + cloud sync)

EOF

bold "Sync complete."
