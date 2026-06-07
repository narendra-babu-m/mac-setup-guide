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

# ============================================================================
# assert_cloud_safe <path>
# ============================================================================
# Validate that <path> is safe to use as a cloud-sync destination (OneDrive,
# iCloud, Dropbox, etc.). Cloud sync + certain filesystem features = silent
# data corruption. Refuse early with a clear error.
#
# Checks (each is a hard fail except where noted):
#   1. Path is INSIDE a known cloud-sync root (CloudStorage/Mobile Documents
#      etc.) — only run the rest of the checks then. Local paths skip silently.
#   2. Path itself is NOT a symlink. Cloud syncs follow symlinks differently
#      across vendors; some upload the link, some upload the target, some
#      break and never sync. Always materialize as a real directory.
#   3. Path does NOT contain a `.git` directory anywhere up to the cloud root.
#      Git's atomic-rename + lockfile dance corrupts when OneDrive/Dropbox/
#      iCloud touches `.git/index` or `.git/HEAD` mid-write. Two machines
#      racing on the same repo through cloud sync = wedged refs.
#   4. Path is not the cloud root itself or a top-level company-managed dir
#      (some MDMs lock those — write fails silently, file appears in Finder
#      then disappears on next sync).
#
# Exit codes:
#   0 — path is safe (or not in any cloud root, in which case checks skip)
#   1 — unsafe; warn + return 1 so caller can fall back
# ============================================================================
assert_cloud_safe() {
  local target="$1"
  [ -z "$target" ] && return 0

  # 1. Is this path inside a known cloud-sync root?
  local cloud_root=""
  case "$target" in
    "$HOME"/Library/CloudStorage/OneDrive-*)         cloud_root=$(printf "%s\n" "$target" | awk -F/ 'BEGIN{OFS="/"} {print $1,$2,$3,$4,$5,$6}') ;;
    "$HOME"/Library/CloudStorage/Dropbox*)           cloud_root="$HOME/Library/CloudStorage/Dropbox" ;;
    "$HOME"/Library/Mobile\ Documents/com~apple~*)   cloud_root=$(printf "%s\n" "$target" | awk -F/ 'BEGIN{OFS="/"} {print $1,$2,$3,$4,$5,$6}') ;;
    "$HOME"/Dropbox*)                                cloud_root="$HOME/Dropbox" ;;
    "$HOME"/OneDrive*)                               cloud_root="$HOME/OneDrive" ;;
    *) return 0 ;;  # not in a cloud root — local path, no checks needed
  esac

  # 2. Symlink check — neither the target nor any segment up to cloud root
  #    should be a symlink. Cloud vendors disagree on symlink semantics.
  local probe="$target"
  while [ "$probe" != "$cloud_root" ] && [ "$probe" != "/" ] && [ -n "$probe" ]; do
    if [ -L "$probe" ]; then
      warn "cloud-unsafe: '$probe' is a symlink. OneDrive/Dropbox/iCloud handle symlinks inconsistently."
      warn "  Fix: replace the symlink with a real directory. rm '$probe' && mkdir -p '$probe'"
      return 1
    fi
    probe=$(dirname "$probe")
  done

  # 3. Git repo check — walk from target up to cloud root, refuse if any
  #    ancestor contains a `.git` directory or file (worktree marker).
  probe="$target"
  while [ "$probe" != "$cloud_root" ] && [ "$probe" != "/" ] && [ -n "$probe" ]; do
    if [ -e "$probe/.git" ]; then
      warn "cloud-unsafe: '$probe' is a git repo inside a cloud-sync folder."
      warn "  Git + OneDrive/Dropbox/iCloud corrupts .git/index and refs."
      warn "  Fix: move the repo out of cloud sync, or use ~/Pictures/Screenshots fallback."
      return 1
    fi
    probe=$(dirname "$probe")
  done

  # 4. Don't write to the cloud root itself (some MDMs make it read-only).
  if [ "$target" = "$cloud_root" ]; then
    warn "cloud-unsafe: '$target' is the cloud-sync root itself. Use a subfolder."
    return 1
  fi

  return 0
}
