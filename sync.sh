#!/usr/bin/env bash
# ============================================================================
# sync.sh — Compare live Mac state against the repo and surface drift.
#
# Run this AFTER you install/change something on your Mac so the repo stays
# the source of truth. Without this, the repo drifts and "fresh-Mac in a day"
# stops working.
#
# DESIGN NOTE — why this script does NOT auto-overwrite Brewfile:
#   `brew bundle dump --force` produces a FLAT, alphabetised list. Naren's
#   Brewfile is hand-curated with section headers, inline `# WHY` comments,
#   and a deliberate ordering. Overwriting it with a dump destroys all that
#   context and is silently lossy.
#
#   Instead this script computes a SET DIFFERENCE between the curated
#   Brewfile and the live system, prints what's missing in either direction,
#   and lets the user decide where in the file to add new entries (so the
#   section/comment structure is preserved).
#
#   `--apply-additions` will append unknown entries to the bottom of the
#   Brewfile under a clearly-marked "auto-added" section — never inline.
#
# Usage:
#   bash sync.sh                     show drift report only
#   bash sync.sh --dry               same as no args (kept for back-compat)
#   bash sync.sh --apply-additions   append missing entries to bottom of Brewfile
#   bash sync.sh --strict            exit 1 if any drift detected (CI-friendly)
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
BREWFILE="$REPO_ROOT/Brewfile"

APPLY_ADDITIONS=false
STRICT=false
for arg in "$@"; do
  case "$arg" in
    --dry)               : ;;  # default behavior; kept for back-compat
    --apply-additions)   APPLY_ADDITIONS=true ;;
    --strict)            STRICT=true ;;
    -h|--help)           sed -n '1,30p' "$0"; exit 0 ;;
    *)                   echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

bold()    { printf "\033[1m%s\033[0m\n" "$*"; }
section() { printf "\n\033[1;34m── %s ──\033[0m\n" "$*"; }

# Extract just the meaningful lines (entry types) from a Brewfile-shaped file.
# Strips comments, blanks, and inline trailing comments. Sorts for set-compare.
# Output: one canonical line per entry, e.g. `brew "ripgrep"` or `cask "ghostty"`.
extract_entries() {
  local file=$1
  awk '
    # strip leading whitespace
    { sub(/^[[:space:]]+/, "") }
    # skip blanks + full-line comments
    /^$/ || /^#/ { next }
    # drop trailing inline comments + trailing whitespace
    {
      sub(/[[:space:]]+#.*$/, "")
      sub(/[[:space:]]+$/, "")
    }
    # only keep recognisable entry types
    /^(tap|brew|cask|mas|vscode|whalebrew)[[:space:]]/ { print }
  ' "$file" \
  | sort -u
}

# ── Brewfile drift report ──────────────────────────────────────────────────
section "Brewfile drift"

if [ ! -f "$BREWFILE" ]; then
  echo "  ✗ Brewfile missing at $BREWFILE — aborting" >&2
  exit 1
fi

TMP_DUMP=$(mktemp)
TMP_REPO=$(mktemp)
TMP_LIVE=$(mktemp)
trap 'rm -f "$TMP_DUMP" "$TMP_REPO" "$TMP_LIVE"' EXIT

# Dump current system to a throwaway file (NEVER touch the canonical Brewfile).
# Scope-limit to what we actually manage: taps, formulae, casks, mas IDs.
# Skip vscode/npm/uv — those have their own sync mechanisms.
brew bundle dump --file="$TMP_DUMP" --force \
  --formula --cask --tap --mas \
  --no-vscode --no-npm --no-uv >/dev/null

extract_entries "$BREWFILE"  > "$TMP_REPO"
extract_entries "$TMP_DUMP"  > "$TMP_LIVE"

# Set differences.
ON_MAC_ONLY=$(comm -23 "$TMP_LIVE" "$TMP_REPO")   # in live, not in repo
IN_REPO_ONLY=$(comm -13 "$TMP_LIVE" "$TMP_REPO")  # in repo, not on live

ADDED_COUNT=$(printf "%s" "$ON_MAC_ONLY"   | grep -c . || true)
MISSING_COUNT=$(printf "%s" "$IN_REPO_ONLY" | grep -c . || true)

if [ "$ADDED_COUNT" -eq 0 ] && [ "$MISSING_COUNT" -eq 0 ]; then
  echo "  ✓ Brewfile in sync with live system ($(wc -l < "$TMP_REPO" | tr -d ' ') entries)"
else
  if [ "$ADDED_COUNT" -gt 0 ]; then
    bold "  + ON MAC, NOT IN REPO ($ADDED_COUNT)"
    printf "%s\n" "$ON_MAC_ONLY" | sed 's/^/      /'
    echo
    echo "    → Decide for each: add to the right section of Brewfile (with a"
    echo "      WHY comment), or remove from the Mac if it was a one-off."
    echo "    → Or run: bash sync.sh --apply-additions  (appends to bottom"
    echo "      under an auto-added section — you re-home them later)."
  fi
  if [ "$MISSING_COUNT" -gt 0 ]; then
    echo
    bold "  - IN REPO, NOT ON MAC ($MISSING_COUNT)"
    printf "%s\n" "$IN_REPO_ONLY" | sed 's/^/      /'
    echo
    echo "    → These were in Brewfile but aren't installed. If the loss was"
    echo "      intentional, remove them from Brewfile. Otherwise:"
    echo "      brew bundle --file=$BREWFILE   # re-installs missing items"
  fi
fi

# Apply additions (additive only — never deletes, never reorders).
if [ "$APPLY_ADDITIONS" = "true" ] && [ "$ADDED_COUNT" -gt 0 ]; then
  echo
  bold "  Applying additions — appending $ADDED_COUNT entries to bottom of Brewfile"
  STAMP=$(date +%Y-%m-%d)
  {
    printf "\n# ── Auto-added by sync.sh on %s ─────────────────────────────────\n" "$STAMP"
    echo   "# TODO: re-home each entry to the correct section above (with a WHY)."
    printf "%s\n" "$ON_MAC_ONLY"
  } >> "$BREWFILE"
  echo "    ✓ written. Review and re-home before commit:"
  echo "       cd $REPO_ROOT && git diff Brewfile"
fi

# ── Defaults drift report ──────────────────────────────────────────────────
section "Defaults drift (validate.sh)"

if [ -f "$REPO_ROOT/validate.sh" ]; then
  bash "$REPO_ROOT/validate.sh" --drift-only || true
  echo
  echo "  Full report: bash $REPO_ROOT/validate.sh"
else
  echo "  (validate.sh missing — skipping)"
fi

# ── Dotfile symlink health ─────────────────────────────────────────────────
section "Dotfile symlink health"

if [ -x "$REPO_ROOT/scripts/dotfiles-link.sh" ]; then
  # Re-run the linker — idempotent, prints "ok" for healthy links and
  # "link"/"WARN" for anything that needs attention.
  bash "$REPO_ROOT/scripts/dotfiles-link.sh" || true
else
  echo "  (scripts/dotfiles-link.sh missing — skipping)"
fi

# ── Reminders ──────────────────────────────────────────────────────────────
section "Reminders"
cat <<EOF

Things sync.sh does NOT auto-capture (you must edit the relevant file + commit):
  • System Settings toggles (Dock, Finder, Keyboard, etc.)
    → edit scripts/<area>-defaults.sh, flip the var, commit
  • New Login Items (System Settings → General → Login Items)
    → document in MANUAL_STEPS.md (not scriptable on Sonoma+)
  • Raycast extensions, VS Code extensions, browser extensions
    → these have their own sync mechanisms (sign in + cloud sync)

EOF

# Strict mode: non-zero exit if drift exists. CI / pre-commit hook friendly.
if [ "$STRICT" = "true" ]; then
  if [ "$ADDED_COUNT" -gt 0 ] || [ "$MISSING_COUNT" -gt 0 ]; then
    echo "  --strict: drift detected, exiting 1" >&2
    exit 1
  fi
fi

bold "Sync complete."
