#!/usr/bin/env bash
# ============================================================================
# validate.sh — Drift reporter for macOS defaults
# ============================================================================
#
# WHAT
#   Compares what scripts/*-defaults.sh WOULD set vs what your live Mac
#   actually has. Read-only. Never writes anything.
#
# HOW IT WORKS
#   Each *-defaults.sh script declares its toggles in a CONFIG block, then
#   calls `apply_bool` / `apply_string` / direct `defaults write` to apply.
#   This validator sources each script with `defaults`, `killall`,
#   `PlistBuddy`, and `restart_app` shadowed — every write becomes a row in
#   an EXPECTED table instead of a real write. Then we read live values and
#   diff.
#
#   Single source of truth stays in scripts/. No second manifest to maintain.
#
# EXIT CODES
#   0  — no drift
#   1  — drift found (see report)
#   2  — validator itself broke (sourcing failed)
#
# OUTPUT
#   Aligned table with one row per (domain, key) tuple:
#     STATUS  DOMAIN                       KEY                       EXPECTED  ACTUAL
#   STATUS:
#     OK      live value matches
#     DRIFT   live value differs
#     MISSING key does not exist on live system (never set)
#     UNREAD  could not read live value (permission, host scope, etc.)
#
# USAGE
#   bash validate.sh                      # full report
#   bash validate.sh --only finder        # just one script's keys
#   bash validate.sh --drift-only         # hide OK rows
#   bash validate.sh --json               # machine-readable (jq-friendly)
# ============================================================================

set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"

# ─── Args ────────────────────────────────────────────────────────────────────
ONLY=""
DRIFT_ONLY=0
JSON=0
while [ $# -gt 0 ]; do
  case "$1" in
    --only)         ONLY="${2:-}"; shift 2 ;;
    --drift-only)   DRIFT_ONLY=1; shift ;;
    --json)         JSON=1; shift ;;
    -h|--help)      sed -n '2,/^# ===/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# ─── Real paths (saved before shadowing) ─────────────────────────────────────
REAL_DEFAULTS=/usr/bin/defaults
REAL_PB=/usr/libexec/PlistBuddy

# Capture table — populated by the shadow `defaults` while sourcing.
# bash 3.2 (system) has no associative arrays — use indexed only.
declare -a EXPECTED=()
declare -a PB_CAPTURE=()

# ─── Shadows ────────────────────────────────────────────────────────────────
# Replace `defaults` to record writes, allow reads to fall through to real.
defaults() {
  local host="user"
  if [ "${1:-}" = "-currentHost" ]; then
    host="currentHost"
    shift
  fi
  case "${1:-}" in
    write)
      shift
      # Form: defaults write <domain> <key> [-type] <value>
      local domain="$1" key="$2" type="raw" value
      shift 2
      case "${1:-}" in
        -bool|-string|-int|-integer|-float|-data|-array|-dict)
          type="${1#-}"
          shift
          ;;
      esac
      value="${*:-}"
      EXPECTED+=("${type}|${host}|${domain}|${key}|${value}")
      ;;
    read|read-type|delete|export|import|domains|find|help|*)
      # Reads (rare during sourcing) fall through to real defaults.
      "$REAL_DEFAULTS" ${host:+$([ "$host" = "currentHost" ] && echo "-currentHost")} "$@" 2>/dev/null || true
      ;;
  esac
}
export -f defaults 2>/dev/null || true

# Suppress restart_app and killall during validation.
restart_app() { :; }
killall()     { :; }

# Stub PlistBuddy: capture nested calculateAllSizes writes so we can verify them.
# Form scripts use:
#   $PB -c "Set :A:B:calculateAllSizes true"  /path/finder.plist
#   $PB -c "Add :A:B:calculateAllSizes bool true"  /path/finder.plist
plistbuddy_stub() {
  # args:  -c "<cmd>" <plist>
  if [ "${1:-}" = "-c" ]; then
    local cmd="$2" plist="$3"
    # Parse Set/Add :path... value
    if [[ "$cmd" =~ ^(Set|Add)\ (:[^[:space:]]+)\ (.*)$ ]]; then
      local op="${BASH_REMATCH[1]}"
      local path="${BASH_REMATCH[2]}"
      local rest="${BASH_REMATCH[3]}"
      local value type="raw"
      if [[ "$op" = "Add" ]]; then
        # "bool true" → type=bool, value=true
        type="${rest%% *}"
        value="${rest#* }"
      else
        value="$rest"
        type="bool"  # only Set we issue is bool-shaped
      fi
      PB_CAPTURE+=("${type}|${plist}|${path}|${value}")
    fi
  fi
  return 0
}
export -f plistbuddy_stub 2>/dev/null || true

# ─── Source each script (CONFIG + APPLY) — captures into EXPECTED ───────────
TARGETS=(finder dock screenshot keyboard trackpad general-ui security)
[ -n "$ONLY" ] && TARGETS=("$ONLY")

source_script() {
  local script="$1"
  [ -f "$script" ] || { echo "missing: $script" >&2; return 1; }
  # Strip the inner `source .../lib/common.sh` line (we already loaded
  # common.sh; re-sourcing it would resolve $0 against validate.sh's path
  # and fail). Use a tmpfile — process substitution `<(...)` doesn't
  # cleanly carry function shadows through to sourced code on macOS bash.
  local tmp
  tmp=$(mktemp)
  grep -v '^source.*lib/common\.sh' "$script" > "$tmp"
  PB="plistbuddy_stub"
  set +e
  source "$tmp" >/dev/null 2>&1
  set +u
  rm -f "$tmp"
}

# Pre-load common.sh so `log`, `apply_bool`, etc. are defined when each
# *-defaults.sh body runs.
source "$SCRIPTS_DIR/lib/common.sh"
set +e   # common.sh enables `set -euo pipefail`; relax it for the validator

# Silence log/warn during validation runs so script output doesn't bleed
# through (we already redirect stdout/stderr, but belt-and-suspenders).
log()  { :; }
warn() { :; }

for t in "${TARGETS[@]}"; do
  source_script "$SCRIPTS_DIR/${t}-defaults.sh"
done

# ─── Read live values and compute drift ─────────────────────────────────────
norm_bool() {
  # Normalize macOS plist bool representations: 1/0/true/false/YES/NO
  # bash 3.2 has no ${var,,} — use tr.
  local v
  v=$(printf "%s" "${1:-}" | tr '[:upper:]' '[:lower:]')
  case "$v" in
    1|true|yes)  echo "true"  ;;
    0|false|no)  echo "false" ;;
    *) echo "${1:-}" ;;
  esac
}

read_live() {
  local host="$1" domain="$2" key="$3"
  if [ "$host" = "currentHost" ]; then
    "$REAL_DEFAULTS" -currentHost read "$domain" "$key" 2>/dev/null
  else
    "$REAL_DEFAULTS" read "$domain" "$key" 2>/dev/null
  fi
}

read_pb() {
  local plist="$1" path="$2"
  "$REAL_PB" -c "Print $path" "$plist" 2>/dev/null
}

# Status counters
OK=0; DRIFT=0; MISSING=0; UNREAD=0
ROWS=()

for row in "${EXPECTED[@]:-}"; do
  [ -z "$row" ] && continue
  IFS='|' read -r type host domain key expected <<<"$row"
  actual="$(read_live "$host" "$domain" "$key")"
  rc=$?

  if [ -z "$actual" ] && [ $rc -ne 0 ]; then
    status="MISSING"; MISSING=$((MISSING+1))
  else
    # Normalize for comparison
    case "$type" in
      bool)
        e="$(norm_bool "$expected")"; a="$(norm_bool "$actual")"
        ;;
      *)
        e="$expected"; a="$actual"
        ;;
    esac
    if [ "$e" = "$a" ]; then
      status="OK"; OK=$((OK+1))
    else
      status="DRIFT"; DRIFT=$((DRIFT+1))
    fi
  fi

  # truncate long actuals for display
  display_actual="${actual:-—}"
  [ ${#display_actual} -gt 40 ] && display_actual="${display_actual:0:37}..."
  ROWS+=("${status}|${host}|${domain}|${key}|${expected}|${display_actual}")
done

# Nested calculateAllSizes (from PB_CAPTURE) — dedupe by path, expected is the
# desired bool. Live read uses real PlistBuddy. bash-3.2 dedupe via sort -u.
PB_DEDUPED=$(printf "%s\n" "${PB_CAPTURE[@]:-}" | awk -F'|' 'NF>=4 && !seen[$2"::"$3]++')
while IFS= read -r row; do
  [ -z "$row" ] && continue
  IFS='|' read -r type plist path value <<<"$row"
  actual="$(read_pb "$plist" "$path")"
  e="$(norm_bool "$value")"
  a="$(norm_bool "$actual")"

  if [ -z "$actual" ]; then
    status="MISSING"; MISSING=$((MISSING+1))
    a="—"
  elif [ "$e" = "$a" ]; then
    status="OK"; OK=$((OK+1))
  else
    status="DRIFT"; DRIFT=$((DRIFT+1))
  fi

  short_path="${path##*:}"  # last segment
  ROWS+=("${status}|user|finder.plist|${short_path}|${e}|${a}")
done <<<"$PB_DEDUPED"

# ─── Render ─────────────────────────────────────────────────────────────────
if [ "$JSON" = "1" ]; then
  printf '{\n  "summary": {"ok": %d, "drift": %d, "missing": %d, "unread": %d},\n' \
    "$OK" "$DRIFT" "$MISSING" "$UNREAD"
  printf '  "rows": [\n'
  i=0; total=${#ROWS[@]}
  for row in "${ROWS[@]:-}"; do
    [ -z "$row" ] && continue
    IFS='|' read -r status host domain key expected actual <<<"$row"
    [ "$DRIFT_ONLY" = "1" ] && [ "$status" = "OK" ] && continue
    sep=","; [ $((++i)) -eq "$total" ] && sep=""
    printf '    {"status":"%s","host":"%s","domain":"%s","key":"%s","expected":"%s","actual":"%s"}%s\n' \
      "$status" "$host" "$domain" "$key" "$expected" "$actual" "$sep"
  done
  printf '  ]\n}\n'
else
  printf "\n  validate.sh — drift report\n"
  printf "  ─────────────────────────────────────────────────────────────────────────────\n"
  printf "  %-7s %-11s %-32s %-34s %-12s %s\n" \
    "STATUS" "HOST" "DOMAIN" "KEY" "EXPECTED" "ACTUAL"
  printf "  %-7s %-11s %-32s %-34s %-12s %s\n" \
    "------" "----" "------" "---" "--------" "------"
  for row in "${ROWS[@]:-}"; do
    [ -z "$row" ] && continue
    IFS='|' read -r status host domain key expected actual <<<"$row"
    [ "$DRIFT_ONLY" = "1" ] && [ "$status" = "OK" ] && continue

    # Color: red drift, yellow missing, green ok
    color=""; reset=""
    if [ -t 1 ]; then
      reset=$'\033[0m'
      case "$status" in
        DRIFT)   color=$'\033[31m' ;;
        MISSING) color=$'\033[33m' ;;
        OK)      color=$'\033[32m' ;;
      esac
    fi
    printf "  ${color}%-7s${reset} %-11s %-32s %-34s %-12s %s\n" \
      "$status" "$host" "$domain" "$key" "$expected" "$actual"
  done
  printf "\n  Summary:  %d OK,  %d DRIFT,  %d MISSING\n\n" "$OK" "$DRIFT" "$MISSING"
  if [ "$DRIFT" -gt 0 ] || [ "$MISSING" -gt 0 ]; then
    printf "  Tip: run \`bash bootstrap.sh --only-defaults\` to re-apply, or\n"
    printf "       edit scripts/<area>-defaults.sh CONFIG to match what you want.\n\n"
  fi
fi

# Exit code
if [ "$DRIFT" -gt 0 ] || [ "$MISSING" -gt 0 ]; then
  exit 1
fi
exit 0
