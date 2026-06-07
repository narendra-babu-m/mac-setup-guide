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
#   log <msg>                                — info line
#   warn <msg>                               — warning line (stderr)
#   apply_bool          VAR DOMAIN KEY       — write -bool   if VAR set, else skip
#   apply_string        VAR DOMAIN KEY       — write -string if VAR set, else skip
#   apply_int           VAR DOMAIN KEY       — write -int    if VAR set, else skip
#   apply_float         VAR DOMAIN KEY       — write -float  if VAR set, else skip
#   apply_bool_inverted VAR DOMAIN KEY       — write -bool with VALUE INVERTED.
#                                              For "DISABLE_X=true" semantics →
#                                              "FeatureEnabled=false" plist key.
#   apply_*_currenthost VAR DOMAIN KEY       — same as above but -currentHost
#                                              scope. Adds currenthost variants
#                                              for bool / int as needed.
#   restart_app <AppName>                    — killall App, ignore "no process"
# ============================================================================

set -euo pipefail

log()  { printf "  [%s] %s\n" "$(basename "${0:-script}" .sh)" "$*"; }
warn() { printf "  [%s] WARN: %s\n" "$(basename "${0:-script}" .sh)" "$*" >&2; }

# Internal: unified apply for any defaults type, optionally to -currentHost,
# optionally with the bool inverted (for DISABLE_X-style semantics).
_apply() {
  local type=$1 var=$2 domain=$3 key=$4 host="${5:-user}" invert="${6:-false}"
  if [ -z "${!var+x}" ]; then
    printf "    skip   %-45s (var %s unset)\n" "$key" "$var"
    return 0
  fi
  local value="${!var}"
  if [ "$invert" = "true" ]; then
    case "$value" in
      true)  value=false ;;
      false) value=true  ;;
      *) warn "$var = '$value' but apply_bool_inverted only handles true/false"; return 1 ;;
    esac
  fi
  local host_flag=()
  [ "$host" = "currentHost" ] && host_flag=(-currentHost)
  # bash 3.2 + set -u: empty arrays are "unbound" — guard the expansion.
  defaults ${host_flag[@]+"${host_flag[@]}"} write "$domain" "$key" "$type" "$value"
  printf "    set    %-45s = %s%s\n" "$key" "$value" \
    "$([ "$host" = "currentHost" ] && printf ' [currentHost]')"
}

apply_bool()                  { _apply -bool   "$1" "$2" "$3" user        false; }
apply_string()                { _apply -string "$1" "$2" "$3" user        false; }
apply_int()                   { _apply -int    "$1" "$2" "$3" user        false; }
apply_float()                 { _apply -float  "$1" "$2" "$3" user        false; }
apply_bool_inverted()         { _apply -bool   "$1" "$2" "$3" user        true;  }
apply_bool_currenthost()      { _apply -bool   "$1" "$2" "$3" currentHost false; }
apply_int_currenthost()       { _apply -int    "$1" "$2" "$3" currentHost false; }

restart_app() {
  killall "$1" 2>/dev/null || true
}
