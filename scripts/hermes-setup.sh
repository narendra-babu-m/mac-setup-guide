#!/usr/bin/env bash
# ============================================================================
# hermes-setup.sh — Install Hermes Agent on a fresh Mac.
#
# What it does:
#   1. Clones nous-research/hermes-agent if ~/.hermes/hermes-agent/ missing.
#   2. Runs the upstream setup-hermes.sh (installs tools, deps, venv, CLI shim).
#   3. If this is a migrated Mac (data rsynced), skips clone step.
#   4. Installs LaunchAgents from dotfiles/launchagents/ (opt-in).
#   5. Creates ~/.local/bin/hai symlink if hai binary lives in a non-standard
#      location (migration pattern).
#
# Prereqs:
#   - git, python3, bash in PATH
#   - ~/.hermes/auth.json if migrating (or run `hermes setup` to generate)
#
# USAGE:
#   bash scripts/hermes-setup.sh            # install Hermes + skip LaunchAgents
#   LOAD_AGENTS=1 bash scripts/hermes-setup.sh   # also launchctl load the agents
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HERMES_HOME="$HOME/.hermes"
HERMES_AGENT="$HERMES_HOME/hermes-agent"
LAUNCH_AGENTS_SRC="$REPO_ROOT/dotfiles/launchagents"
LAUNCH_AGENTS_DST="$HOME/Library/LaunchAgents"

log()  { printf "  [hermes-setup] %s\n" "$*"; }
warn() { printf "  [hermes-setup] WARN: %s\n" "$*" >&2; }

# ── Step 1: Clone hermes-agent if missing ────────────────────────────────────
if [ ! -d "$HERMES_AGENT" ]; then
  log "No existing Hermes install — cloning nous-research/hermes-agent..."
  mkdir -p "$HERMES_HOME"
  git clone https://github.com/nous-research/hermes-agent.git "$HERMES_AGENT"
else
  log "Hermes-agent dir exists: $HERMES_AGENT (migration case — skipping clone)"
fi

# ── Step 2: Run upstream setup-hermes.sh ─────────────────────────────────────
if [ -x "$HERMES_AGENT/setup-hermes.sh" ]; then
  log "Running Hermes setup script..."
  cd "$HERMES_AGENT"
  bash setup-hermes.sh
else
  warn "setup-hermes.sh not found in $HERMES_AGENT — repo may be incomplete"
  exit 1
fi

# ── Step 3: Verify CLI works ─────────────────────────────────────────────────
if ! "$HOME/.local/bin/hermes" --version >/dev/null 2>&1; then
  warn "hermes CLI not working. Try: source $HERMES_AGENT/activate"
else
  log "hermes CLI: $("$HOME/.local/bin/hermes" --version | head -1)"
fi

# ── Step 4: hai binary symlink (for LaunchAgent compatibility) ───────────────
# LaunchAgents (specifically com.narendra.hai-proxy-hermes) expect
# /opt/homebrew/bin/hai. Migrated Macs have hai at ~/.local/bin/hai.
if [ -f "$HOME/.local/bin/hai" ] && [ ! -e "/opt/homebrew/bin/hai" ]; then
  log "Symlinking ~/.local/bin/hai -> /opt/homebrew/bin/hai (for LaunchAgent)"
  ln -sf "$HOME/.local/bin/hai" /opt/homebrew/bin/hai
fi

# ── Step 5: LaunchAgents (opt-in) ────────────────────────────────────────────
if [ "${LOAD_AGENTS:-0}" = "1" ]; then
  if [ -d "$LAUNCH_AGENTS_SRC" ]; then
    log "Rendering LaunchAgent templates → $LAUNCH_AGENTS_DST/"
    mkdir -p "$LAUNCH_AGENTS_DST"

    # Generate (or reuse) a stable per-user API key for the hai-proxy LaunchAgent.
    # NOTE: this is a LOCAL auth token between Hermes and hai-proxy (both run as
    # you); not a secret that reaches SAP. First run generates + stores it under
    # ~/.config/hai/local-proxy-api-key.
    HAI_KEY_FILE="$HOME/.config/hai/local-proxy-api-key"
    if [ ! -f "$HAI_KEY_FILE" ]; then
      mkdir -p "$(dirname "$HAI_KEY_FILE")"
      printf "hermes-%s" "$(uuidgen | tr '[:upper:]' '[:lower:]')" > "$HAI_KEY_FILE"
      chmod 600 "$HAI_KEY_FILE"
      log "  generated new hai-proxy local API key → $HAI_KEY_FILE"
    fi
    HAI_PROXY_API_KEY="$(cat "$HAI_KEY_FILE")"

    for tpl in "$LAUNCH_AGENTS_SRC"/*.plist.template; do
      [ -e "$tpl" ] || continue
      name="$(basename "$tpl" .template)"
      sed -e "s|__HOME__|$HOME|g" \
          -e "s|__HAI_PROXY_API_KEY__|$HAI_PROXY_API_KEY|g" \
          "$tpl" > "$LAUNCH_AGENTS_DST/$name"
      log "  rendered: $name"
    done

    # Load them. hai-proxy FIRST (gateway depends on it for HAI provider).
    for name in com.narendra.hai-proxy-hermes com.narendra.hermes-litellm-watchdog ai.hermes.gateway; do
      plist="$LAUNCH_AGENTS_DST/$name.plist"
      if [ -f "$plist" ]; then
        launchctl load -w "$plist" 2>&1 | head -2 || true
        log "  loaded: $name"
      fi
    done
    sleep 3
    log ""
    log "Active agents:"
    launchctl list | grep -E "hermes|hai" | head
  else
    warn "No LaunchAgent plists in $LAUNCH_AGENTS_SRC/ — skipping load."
  fi
else
  log ""
  log "LaunchAgents NOT loaded (LOAD_AGENTS=0). To load later:"
  log "  LOAD_AGENTS=1 bash scripts/hermes-setup.sh"
  log "  OR manually: launchctl load -w ~/Library/LaunchAgents/<name>.plist"
fi

log ""
log "Hermes setup complete."
log "Next steps:"
log "  1. If NOT migrating: run 'hermes setup' to configure API keys"
log "  2. If migrating: ensure ~/.hermes/auth.json rsynced from old Mac"
log "  3. Verify: hermes status"
