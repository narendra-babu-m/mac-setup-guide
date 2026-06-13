#!/usr/bin/env bash
# ============================================================================
# git-defaults.sh — Global ~/.gitconfig settings (delta pager, conflict style,
# diff.colorMoved, etc.). Idempotent: skips writes that already match intent.
#
# WHY THIS EXISTS AS A SCRIPT (not in ~/.zshrc):
#   These settings used to live as `git config --global ...` lines in
#   ~/.zshrc. That worked for one shell at a time, but every shell start
#   raced for ~/.gitconfig.lock. When Zellij spawned multiple panes (or
#   any tool fired up several shells in parallel), the loser saw:
#     error: could not lock config file /Users/<u>/.gitconfig: File exists
#   These are write-once settings. They belong in setup, not shell init.
# ============================================================================

set -euo pipefail

log()  { printf "  [%s] %s\n" "$(basename "$0" .sh)" "$*"; }
warn() { printf "  [%s] WARN: %s\n" "$(basename "$0" .sh)" "$*" >&2; }

# ============================================================================
# CONFIG
# ============================================================================
#
# Each entry: KEY VALUE comment. Comment a line out to leave that setting
# at git's default. Adding a new line here is the way to extend.
#
# Values are written to --global scope (~/.gitconfig). If you want repo-local
# overrides, set them with `git -C <repo> config <key> <value>` separately.

# Format: "<git-config-key>=<value>"
GIT_SETTINGS=(
  # delta as pager + interactive diff filter
  # WHY: dramatic upgrade over plain `git diff` — syntax highlighting,
  #      side-by-side, hunk navigation, theme.
  "core.pager=delta"
  "interactive.diffFilter=delta --color-only"

  # delta cosmetics
  # WHY: navigate=n/N between hunks; side-by-side reads like a code review.
  "delta.navigate=true"
  "delta.side-by-side=true"
  "delta.syntax-theme=Dracula"

  # 3-way conflict style
  # WHY: shows the original ancestor between <<<< and ==== so you can
  #      tell whose intent is whose during a merge.
  "merge.conflictstyle=diff3"

  # Detect moved code blocks separately from add/delete
  # WHY: refactors that move blocks unchanged read as moves, not noise.
  "diff.colorMoved=default"
)

# ============================================================================
# APPLY
# ============================================================================

if ! command -v git >/dev/null 2>&1; then
  warn "git not in PATH — skipping. Install git first (Brewfile)."
  exit 0
fi

if ! command -v delta >/dev/null 2>&1; then
  warn "delta not in PATH — settings reference it but installation is separate."
  warn "Continuing anyway: ~/.gitconfig writes are harmless without delta installed."
fi

log "applying global git settings..."

for entry in "${GIT_SETTINGS[@]}"; do
  key="${entry%%=*}"
  want="${entry#*=}"
  have="$(git config --global --default '' --get "$key" 2>/dev/null || true)"
  if [ "$have" = "$want" ]; then
    printf "    skip   %-40s (already = %s)\n" "$key" "$want"
  else
    git config --global "$key" "$want"
    if [ -z "$have" ]; then
      printf "    set    %-40s = %s\n" "$key" "$want"
    else
      printf "    update %-40s %s -> %s\n" "$key" "$have" "$want"
    fi
  fi
done

log "done. ~/.gitconfig is the source of truth — do NOT re-add these to ~/.zshrc."

# ============================================================================
# REVERT
#   for k in core.pager interactive.diffFilter delta.navigate \
#            delta.side-by-side delta.syntax-theme \
#            merge.conflictstyle diff.colorMoved; do
#     git config --global --unset "$k" 2>/dev/null || true
#   done
# ============================================================================
