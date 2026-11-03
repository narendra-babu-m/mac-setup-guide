#!/usr/bin/env bash
# ============================================================================
# migrate-to-new-mac.sh — ONE-SHOT MIGRATION BATCH (local Mac → new Mac SSH)
#
# Transfers: Hermes, Claude Code, Claude Desktop, Obsidian vaults, Obsidian app
#            state, Hyperspace AI app bundle, hai CLI binary, AI Core config.
# Prereqs:   SSH key auth to new Mac, brew-rsync 3.5.1 installed BOTH sides.
# ============================================================================

set -u

REMOTE_HOST="USER@IP"
RSYNC="/opt/homebrew/bin/rsync"
LOGDIR="$HOME/.hermes-migration-logs"
mkdir -p "$LOGDIR"

# Common flags: archive, compress, partial resume, human stats, PROGRESS2 (brew rsync has it)
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

# ── 1. HERMES (biggest, cache-heavy — strict excludes) ──────────────────────
run_rsync "hermes" "$HOME/.hermes/" "$REMOTE_HOST:.hermes/" \
  --exclude='auth.lock' \
  --exclude='bootstrap-cache/__pycache__' \
  --exclude='audio_cache/' \
  --exclude='browser-profile/Default/Cache' \
  --exclude='browser-profile/Default/Code Cache' \
  --exclude='browser-profile/Default/GPUCache' \
  --exclude='browser-profile/Default/Service Worker' \
  --exclude='cache/' \
  --exclude='logs/gateway.*' \
  --exclude='logs/*.log.*' \
  --exclude='tools/python-*/'

# ── 2. CLAUDE CODE ──────────────────────────────────────────────────────────
run_rsync "claude-code" "$HOME/.claude/" "$REMOTE_HOST:.claude/" \
  --exclude='paste-cache' \
  --exclude='cache' \
  --exclude='file-history' \
  --exclude='shell-snapshots' \
  --exclude='ide'

# ── 3. CLAUDE DESKTOP APP STATE (quote remote path for spaces) ──────────────
# Trick: single quotes around the full path in the arg, since ssh re-splits.
run_rsync "claude-desktop" \
  "$HOME/Library/Application Support/Claude/" \
  "$REMOTE_HOST:'Library/Application Support/Claude/'" \
  --exclude='Cache' --exclude='Code Cache' --exclude='GPUCache' \
  --exclude='DawnGraphiteCache' --exclude='DawnWebGPUCache' \
  --exclude='Service Worker' --exclude='SavedState' --exclude='Crashpad'

# ── 4. OBSIDIAN VAULTS ──────────────────────────────────────────────────────
run_rsync "obsidian-vaults" "$HOME/Vaults/" "$REMOTE_HOST:Vaults/" \
  --exclude='.trash' --exclude='.obsidian/workspace.json'

# ── 5. OBSIDIAN APP STATE (quote remote path) ───────────────────────────────
run_rsync "obsidian-app" \
  "$HOME/Library/Application Support/obsidian/" \
  "$REMOTE_HOST:'Library/Application Support/obsidian/'" \
  --exclude='Cache' --exclude='Code Cache' --exclude='GPUCache' \
  --exclude='DawnGraphiteCache' --exclude='DawnWebGPUCache' \
  --exclude='Service Worker' --exclude='DIPS'

# ── 6. AI CORE CONFIG (small — already done but refresh in case of drift) ───
run_rsync "aicore" "$HOME/.aicore/" "$REMOTE_HOST:.aicore/"

# ── 7. HAI CLI config dir ───────────────────────────────────────────────────
run_rsync "hai-config" "$HOME/.config/hai/" "$REMOTE_HOST:.config/hai/"

# ── 8. HAI CLI BINARY (not in brew path) ────────────────────────────────────
run_rsync "hai-binary" "$HOME/.local/bin/hai" "$REMOTE_HOST:.local/bin/hai"

# ── 9. HYPERSPACE AI app (SAP internal — no public cask) ────────────────────
run_rsync "hyperspace-app" "/Applications/Hyperspace AI.app/" \
  "$REMOTE_HOST:'/Applications/Hyperspace AI.app/'"

# ── 10. HYPERSPACE prefs plist ──────────────────────────────────────────────
run_rsync "hyperspace-prefs" \
  "$HOME/Library/Preferences/com.sap.hyperspace.AI.plist" \
  "$REMOTE_HOST:Library/Preferences/com.sap.hyperspace.AI.plist"

echo ""
echo "============================================================================"
echo "MIGRATION DONE at $(date +%H:%M:%S)"
echo "Logs: $LOGDIR"
echo "============================================================================"
