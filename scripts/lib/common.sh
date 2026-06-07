# shellcheck shell=bash
# ============================================================================
# common.sh — Shared helpers for all *-defaults.sh scripts.
# Source this from each script:    source "$(dirname "$0")/lib/common.sh"
# ============================================================================
#
# Why a shared lib:
#   - One implementation of "apply if set, skip if unset" — no copy-paste drift.
#   - One consistent log format across every defaults script.
#   - Single place to add features later (dry-run mode, JSON output, etc.).
#
# Public functions:
#   log <msg>                          — info line
#   warn <msg>                         — warning line (stderr)
#   apply_bool   VAR DOMAIN KEY        — write -bool if VAR set, else skip
#   apply_string VAR DOMAIN KEY        — write -string if VAR set, else skip
#   apply_int    VAR DOMAIN KEY        — write -int if VAR set, else skip
#   apply_float  VAR DOMAIN KEY        — write -float if VAR set, else skip
#   restart_app <AppName>              — killall App, ignore "no process" error
# ============================================================================

set -euo pipefail

log()  { printf "  [%s] %s\n" "$(basename "${0:-script}" .sh)" "$*"; }
warn() { printf "  [%s] WARN: %s\n" "$(basename "${0:-script}" .sh)" "$*" >&2; }

# Internal: unified apply for any defaults type.
_apply() {
  local type=$1 var=$2 domain=$3 key=$4
  if [ -z "${!var+x}" ]; then
    printf "    skip   %-45s (var %s unset)\n" "$key" "$var"
    return 0
  fi
  defaults write "$domain" "$key" "$type" "${!var}"
  printf "    set    %-45s = %s\n" "$key" "${!var}"
}

apply_bool()   { _apply -bool   "$@"; }
apply_string() { _apply -string "$@"; }
apply_int()    { _apply -int    "$@"; }
apply_float()  { _apply -float  "$@"; }

restart_app() {
  killall "$1" 2>/dev/null || true
}
