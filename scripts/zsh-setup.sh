#!/usr/bin/env bash
# ============================================================================
# zsh-setup.sh — Install oh-my-zsh + powerlevel10k + plugins, link modular configs.
#
# Idempotent. Skips anything already installed.
#
# What it does:
#   1. Install oh-my-zsh (~/.oh-my-zsh/)
#   2. Clone powerlevel10k to ~/powerlevel10k/ (NOT via brew — matches live Mac)
#   3. Clone 4 custom OMZ plugins into ~/.oh-my-zsh/custom/plugins/
#   4. Symlink dotfiles/zsh/config/*.zsh → ~/.config/zsh/
#   5. Symlink dotfiles/zsh/.p10k.zsh → ~/.p10k.zsh
#   6. If ~/.zshrc missing, copy from dotfiles/zsh/zshrc.template (user must edit MII_PASS)
#   7. If ~/.zprofile missing, copy from dotfiles/zsh/zprofile.template
#
# Why not symlink .zshrc?
#   .zshrc is agent-protected on both macs AND holds device-specific state
#   (login shell env, interactive guards, secret placeholders). Templated copy
#   is safer than symlink.
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ZSH_DIR="$REPO_ROOT/dotfiles/zsh"

log()  { printf "  [zsh-setup] %s\n" "$*"; }
warn() { printf "  [zsh-setup] WARN: %s\n" "$*" >&2; }

# ── 1. Place .zshrc + .zprofile FIRST (before OMZ install) ───────────────────
# WHY: OMZ installer's setup_zshrc() only honours KEEP_ZSHRC=yes if ~/.zshrc
# ALREADY EXISTS when the installer runs. Fresh Mac = no .zshrc = OMZ writes
# its template unconditionally. Place real files first so KEEP_ZSHRC guards fire.
# [SOURCE: https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh]
if [ ! -f "$HOME/.zshrc" ]; then
  cp "$ZSH_DIR/zshrc.template" "$HOME/.zshrc"
  log ".zshrc placed from template (pre-OMZ)"
  warn ".zshrc contains REPLACE_FROM_BITWARDEN placeholder — edit after boot."
else
  # Check if it's the OMZ default (user has 611-line real one, OMZ default is ~107)
  LINES=$(wc -l < "$HOME/.zshrc")
  if [ "$LINES" -lt 150 ] && grep -q "^export ZSH=\"\\\$HOME/\\.oh-my-zsh\"" "$HOME/.zshrc" 2>/dev/null \
     && ! grep -q "powerlevel10k\|p10k" "$HOME/.zshrc" 2>/dev/null; then
    warn "Detected OMZ default .zshrc ($LINES lines, no p10k ref). Backing up + replacing."
    mv "$HOME/.zshrc" "$HOME/.zshrc.omz-default.bak.$(date +%s)"
    cp "$ZSH_DIR/zshrc.template" "$HOME/.zshrc"
    log ".zshrc replaced with real template"
  else
    log ".zshrc exists ($LINES lines, looks custom) — leaving alone"
  fi
fi

if [ ! -f "$HOME/.zprofile" ]; then
  cp "$ZSH_DIR/zprofile.template" "$HOME/.zprofile"
  log ".zprofile placed from template (pre-OMZ)"
fi

# ── 2. oh-my-zsh ─────────────────────────────────────────────────────────────
if [ -d "$HOME/.oh-my-zsh" ]; then
  log "oh-my-zsh already installed, skipping"
else
  log "installing oh-my-zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1
  log "oh-my-zsh ✓"
fi

# ── 2. powerlevel10k theme ───────────────────────────────────────────────────
if [ -d "$HOME/powerlevel10k" ]; then
  log "powerlevel10k already cloned, skipping"
else
  log "cloning powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k" >/dev/null 2>&1
  log "powerlevel10k ✓"
fi

# ── 3. Custom OMZ plugins ────────────────────────────────────────────────────
PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"
mkdir -p "$PLUGINS_DIR"

clone_plugin() {
  local name="$1" url="$2"
  if [ -d "$PLUGINS_DIR/$name" ]; then
    log "  plugin $name already installed"
  else
    log "  cloning plugin $name..."
    git clone --depth=1 "$url" "$PLUGINS_DIR/$name" >/dev/null 2>&1 && log "  $name ✓" || warn "  failed: $name"
  fi
}

log "installing custom OMZ plugins..."
clone_plugin zsh-autosuggestions     https://github.com/zsh-users/zsh-autosuggestions.git
clone_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
clone_plugin zsh-completions         https://github.com/zsh-users/zsh-completions.git
clone_plugin fzf-tab                 https://github.com/Aloxaf/fzf-tab.git

# ── 4. Modular zsh config → ~/.config/zsh/ ───────────────────────────────────
mkdir -p "$HOME/.config/zsh"
log "linking modular zsh configs..."
for src in "$ZSH_DIR/config"/*.zsh; do
  name=$(basename "$src")
  dst="$HOME/.config/zsh/$name"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    printf "    skip  %s (already linked)\n" "$name"
  else
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
      cp "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
      log "    backed up existing $name → ${name}.bak.<ts>"
    fi
    ln -sfn "$src" "$dst"
    printf "    link  %s\n" "$name"
  fi
done

# ── 5. .p10k.zsh ─────────────────────────────────────────────────────────────
dst="$HOME/.p10k.zsh"
src="$ZSH_DIR/.p10k.zsh"
if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
  log ".p10k.zsh already linked"
else
  [ -e "$dst" ] && [ ! -L "$dst" ] && cp "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
  ln -sfn "$src" "$dst"
  log ".p10k.zsh linked"
fi

# ── 6. .zshrc + .zprofile — handled at Step 1 (pre-OMZ) ──────────────────────
# NOTE: moved to Step 1 to prevent OMZ from overwriting on fresh Mac.
# [SOURCE: subagent research 2026-11-03, ohmyzsh install.sh asymmetry]

log ""
log "zsh setup done."
log "Next: open a new shell. On first launch p10k may re-prompt for config — just accept defaults or press q."
log "If MII_PASS matters, edit ~/.zshrc line 139 (search REPLACE_FROM_BITWARDEN)."
