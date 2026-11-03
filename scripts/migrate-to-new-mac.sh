#!/usr/bin/env bash
# ============================================================================
# migrate-to-new-mac.sh — ONE-SHOT MIGRATION BATCH (local Mac → new Mac SSH)
#
# Transfers: Hermes, Claude Code, Claude Desktop, Obsidian vaults, Obsidian app
#            state, Hyperspace AI app bundle, hai CLI binary, AI Core config.
# Prereqs:   SSH key auth to new Mac, brew-rsync 3.5+ installed BOTH sides.
#
# Usage:
#   NEW_MAC_HOST=192.168.1.42 bash scripts/migrate-to-new-mac.sh
#   NEW_MAC_HOST=mymac.local NEW_MAC_USER=alice bash scripts/migrate-to-new-mac.sh
#   NEW_MAC_HOST=192.168.1.42 bash scripts/migrate-to-new-mac.sh --no-python-runtimes
#
# Environment:
#   NEW_MAC_HOST  (required)  IP or hostname of the target Mac
#   NEW_MAC_USER  (optional)  SSH user on target (default: $USER)
# ============================================================================

set -uo pipefail

bold()    { printf "\033[1m%s\033[0m\n" "$*"; }
section() { printf "\n\033[1;34m── %s ──\033[0m\n" "$*"; }
fail()    { printf "\033[1;31mERROR:\033[0m %s\n" "$*" >&2; exit 1; }

# ── Parse args ───────────────────────────────────────────────────────────────
NO_PYTHON_RUNTIMES=false

for arg in "$@"; do
  case "$arg" in
    --no-python-runtimes) NO_PYTHON_RUNTIMES=true ;;
    -h|--help)
      echo "Usage: NEW_MAC_HOST=<ip> [NEW_MAC_USER=<user>] bash scripts/migrate-to-new-mac.sh [--no-python-runtimes]"
      echo ""
      echo "  --no-python-runtimes   Skip syncing Hermes python-* tool runtimes"
      echo ""
      echo "Environment variables:"
      echo "  NEW_MAC_HOST  (required) IP or hostname of the target Mac"
      echo "  NEW_MAC_USER  (optional) SSH user on target (default: \$USER)"
      exit 0
      ;;
    *) fail "Unknown argument: $arg" ;;
  esac
done

# ── Validate env ─────────────────────────────────────────────────────────────
if [ -z "${NEW_MAC_HOST:-}" ]; then
  fail "NEW_MAC_HOST is required.\nUsage: NEW_MAC_HOST=192.168.1.42 bash scripts/migrate-to-new-mac.sh"
fi

NEW_MAC_USER="${NEW_MAC_USER:-$USER}"
REMOTE_HOST="${NEW_MAC_USER}@${NEW_MAC_HOST}"

# ── Check rsync version ─────────────────────────────────────────────────────
RSYNC="/opt/homebrew/bin/rsync"
if [ ! -x "$RSYNC" ]; then
  RSYNC="$(command -v rsync 2>/dev/null || true)"
fi

if [ -z "$RSYNC" ] || [ ! -x "$RSYNC" ]; then
  fail "rsync not found. Install: brew install rsync"
fi

RSYNC_VER="$("$RSYNC" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
RSYNC_MAJOR="${RSYNC_VER%%.*}"
if [ "${RSYNC_MAJOR:-0}" -lt 3 ]; then
  fail "rsync version $RSYNC_VER is too old (need ≥ 3.0).\nInstall: brew install rsync\nThen use /opt/homebrew/bin/rsync"
fi

bold ""
bold "rsync $RSYNC_VER at $RSYNC — OK"

# ── Show transfer plan + confirm ─────────────────────────────────────────────
LOGDIR="$HOME/.hermes-migration-logs"
mkdir -p "$LOGDIR"

bold ""
bold "═══════════════════════════════════════════════════"
bold "  MIGRATION PLAN"
bold "═══════════════════════════════════════════════════"
bold ""
bold "  Target:  $REMOTE_HOST"
bold "  rsync:   $RSYNC ($RSYNC_VER)"
bold "  Logs:    $LOGDIR/"
bold ""
bold "  Transfers:"
echo "    1.  ~/.hermes/              → Hermes agent + config"
echo "    2.  ~/.hermes/hermes-agent/ → Hermes repo code (full)"
echo "    3.  ~/.claude/              → Claude Code config"
echo "    4.  ~/Library/.../Claude/   → Claude Desktop app state"
echo "    5.  ~/Vaults/               → Obsidian vaults"
echo "    6.  ~/Library/.../obsidian/ → Obsidian app state"
echo "    7.  ~/.aicore/              → AI Core config"
echo "    8.  ~/.config/hai/          → HAI CLI config"
echo "    9.  ~/.local/bin/hai        → HAI CLI binary"
echo "   10.  /Applications/Hyperspace AI.app/"
echo "   11.  Hyperspace prefs plist"
if [ "$NO_PYTHON_RUNTIMES" = "true" ]; then
  echo ""
  echo "  ⚠ Skipping: Hermes python-* tool runtimes (--no-python-runtimes)"
fi
bold ""
printf "  Proceed? [y/N] "
read -r CONFIRM
case "$CONFIRM" in
  [yY]|[yY][eE][sS]) ;;
  *) bold "Aborted."; exit 0 ;;
esac

# ── Common rsync flags ───────────────────────────────────────────────────────
# archive, compress, partial resume, human stats, PROGRESS2 (brew rsync has it)
COMMON_FLAGS=(-az --partial --stats --human-readable --info=progress2,stats2
              --rsync-path=/opt/homebrew/bin/rsync
              --exclude='*.sock' --exclude='*.lock'
              --exclude='*.pyc' --exclude='__pycache__')

run_rsync() {
  local label="$1"; shift
  local src="$1"; shift
  local dst="$1"; shift
  local -a extra=("$@")
  local log="$LOGDIR/$label.log"
  echo "=== $label — $src → $dst ==="
  "$RSYNC" "${COMMON_FLAGS[@]}" "${extra[@]}" "$src" "$dst" 2>&1 | tee "$log" | tail -5
  echo ""
}

# ── Build python exclude list ────────────────────────────────────────────────
HERMES_EXTRA_EXCLUDES=(
  --exclude='auth.lock'
  --exclude='bootstrap-cache/__pycache__'
  --exclude='audio_cache/'
  --exclude='browser-profile/Default/Cache'
  --exclude='browser-profile/Default/Code Cache'
  --exclude='browser-profile/Default/GPUCache'
  --exclude='browser-profile/Default/Service Worker'
  --exclude='cache/'
  --exclude='logs/gateway.*'
  --exclude='logs/*.log.*'
)

if [ "$NO_PYTHON_RUNTIMES" = "true" ]; then
  HERMES_EXTRA_EXCLUDES+=(--exclude='tools/python-*/')
fi

# ── 1. HERMES (biggest, cache-heavy — strict excludes) ──────────────────────
run_rsync "hermes" "$HOME/.hermes/" "$REMOTE_HOST:.hermes/" \
  "${HERMES_EXTRA_EXCLUDES[@]}"

# ── 2. HERMES AGENT REPO CODE (full sync for completeness) ──────────────────
# Ensures the hermes-agent repo itself is fully transferred, including
# any local changes not covered by the broader .hermes/ sync above.
section "hermes-agent repo (dedicated sync)"
if [ -d "$HOME/.hermes/hermes-agent/.git" ]; then
  run_rsync "hermes-agent-repo" "$HOME/.hermes/hermes-agent/" "$REMOTE_HOST:.hermes/hermes-agent/" \
    --exclude='node_modules/' \
    --exclude='.hermes/tools/' \
    --exclude='.hermes/cache/'
else
  echo "  (no hermes-agent repo found — skipping)"
fi

# ── 3. CLAUDE CODE ──────────────────────────────────────────────────────────
run_rsync "claude-code" "$HOME/.claude/" "$REMOTE_HOST:.claude/" \
  --exclude='paste-cache' \
  --exclude='cache' \
  --exclude='file-history' \
  --exclude='shell-snapshots' \
  --exclude='ide'

# ── 4. CLAUDE DESKTOP APP STATE (quote remote path for spaces) ──────────────
run_rsync "claude-desktop" \
  "$HOME/Library/Application Support/Claude/" \
  "$REMOTE_HOST:'Library/Application Support/Claude/'" \
  --exclude='Cache' --exclude='Code Cache' --exclude='GPUCache' \
  --exclude='DawnGraphiteCache' --exclude='DawnWebGPUCache' \
  --exclude='Service Worker' --exclude='SavedState' --exclude='Crashpad'

# ── 5. OBSIDIAN VAULTS ──────────────────────────────────────────────────────
run_rsync "obsidian-vaults" "$HOME/Vaults/" "$REMOTE_HOST:Vaults/" \
  --exclude='.trash' --exclude='.obsidian/workspace.json'

# ── 6. OBSIDIAN APP STATE (quote remote path) ───────────────────────────────
run_rsync "obsidian-app" \
  "$HOME/Library/Application Support/obsidian/" \
  "$REMOTE_HOST:'Library/Application Support/obsidian/'" \
  --exclude='Cache' --exclude='Code Cache' --exclude='GPUCache' \
  --exclude='DawnGraphiteCache' --exclude='DawnWebGPUCache' \
  --exclude='Service Worker' --exclude='DIPS'

# ── 7. AI CORE CONFIG (small — already done but refresh in case of drift) ───
run_rsync "aicore" "$HOME/.aicore/" "$REMOTE_HOST:.aicore/"

# ── 8. HAI CLI config dir ───────────────────────────────────────────────────
run_rsync "hai-config" "$HOME/.config/hai/" "$REMOTE_HOST:.config/hai/"

# ── 9. HAI CLI BINARY (not in brew path) ────────────────────────────────────
run_rsync "hai-binary" "$HOME/.local/bin/hai" "$REMOTE_HOST:.local/bin/hai"

# ── 10. HYPERSPACE AI app (SAP internal — no public cask) ────────────────────
run_rsync "hyperspace-app" "/Applications/Hyperspace AI.app/" \
  "$REMOTE_HOST:'/Applications/Hyperspace AI.app/'"

# ── 11. HYPERSPACE prefs plist ──────────────────────────────────────────────
run_rsync "hyperspace-prefs" \
  "$HOME/Library/Preferences/com.sap.hyperspace.AI.plist" \
  "$REMOTE_HOST:Library/Preferences/com.sap.hyperspace.AI.plist"

echo ""
echo "============================================================================"
echo "MIGRATION DONE at $(date +%H:%M:%S)"
echo "Logs: $LOGDIR"
echo "============================================================================"
bold ""
bold "Next steps on the NEW Mac:"
echo "  1. Run: bash ~/mac-setup-guide/scripts/hermes-setup.sh"
echo "  2. Run: LOAD_AGENTS=1 bash ~/mac-setup-guide/scripts/hermes-setup.sh"
echo "  3. Stop the OLD Mac's LaunchAgents before using the new one"
