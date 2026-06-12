#!/usr/bin/env bash
# ============================================================================
# dotfiles-link.sh — Symlink dotfiles from this repo into the right places.
#
# Pattern: SOURCE OF TRUTH lives under ~/mac-setup-guide/dotfiles/<tool>/...
# We symlink (not copy) so editing the live config IS editing the repo file.
# Idempotent — safe to re-run; warns on existing non-symlink files instead
# of clobbering.
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOTFILES="$REPO_ROOT/dotfiles"

# shellcheck source=lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"

# ── Toggles (top-of-file config-as-data, with WHYs) ─────────────────────────

# Ghostty config — ported iTerm2 prefs + modern features (quick-terminal,
# Kitty graphics, scrollback 100k). See dotfiles/ghostty/config for details.
LINK_GHOSTTY=true

# Zellij config + fleet layout — multiplexer for parallel agent panes.
LINK_ZELLIJ=true

# ── Apply ───────────────────────────────────────────────────────────────────

# link_into <src-relative-to-DOTFILES> <dest-absolute>
link_into() {
  local src="$DOTFILES/$1"
  local dest="$2"
  if [ ! -e "$src" ]; then
    warn "source missing: $src — skip"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      printf "    ok     %s\n" "$dest"
      return 0
    fi
    warn "symlink at $dest points to $current (not $src) — replacing"
    rm "$dest"
  elif [ -e "$dest" ]; then
    local backup="${dest}.pre-mac-setup.$(date +%Y%m%d-%H%M%S)"
    warn "non-symlink already at $dest — backing up to $backup"
    mv "$dest" "$backup"
  fi
  ln -s "$src" "$dest"
  printf "    link   %s -> %s\n" "$dest" "$src"
}

if [ "$LINK_GHOSTTY" = "true" ]; then
  log "Ghostty"
  link_into "ghostty/config" \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
fi

if [ "$LINK_ZELLIJ" = "true" ]; then
  log "Zellij"
  link_into "zellij/config.kdl"            "$HOME/.config/zellij/config.kdl"
  link_into "zellij/layouts/fleet.kdl"     "$HOME/.config/zellij/layouts/fleet.kdl"
  # Aliases live in a sourced file; ~/.zshrc must source it (one-time manual
  # step — see MANUAL_STEPS.md §4).
  link_into "zsh/zellij.zsh"               "$HOME/.config/zsh/zellij.zsh"
fi

log "done."
