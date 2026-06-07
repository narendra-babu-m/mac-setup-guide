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

# ── Defaults drift report ──────────────────────────────────────────────────
section "Defaults drift (validate.sh)"

if [ -x "$REPO_ROOT/validate.sh" ] || [ -f "$REPO_ROOT/validate.sh" ]; then
  # Don't fail sync if drift exists — we just want the user to see it.
  bash "$REPO_ROOT/validate.sh" --drift-only || true
  echo
  echo "  Full report: bash $REPO_ROOT/validate.sh"
else
  echo "  (validate.sh missing — skipping)"
fi

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
