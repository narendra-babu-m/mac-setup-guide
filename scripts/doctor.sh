#!/usr/bin/env bash
# ============================================================================
# doctor.sh — 10-point preflight health check for a fresh Mac.
#
# Runs read-only checks and reports PASS/WARN/FAIL for each.
# Exit 0 if no FAILs (WARNs allowed), exit 1 if any FAIL.
#
# Usage:
#   bash scripts/doctor.sh          # check only
#   bash scripts/doctor.sh --fix    # attempt safe auto-fixes
# ============================================================================

set -uo pipefail

bold()    { printf "\033[1m%s\033[0m\n" "$*"; }
green()   { printf "\033[32m%s\033[0m" "$*"; }
yellow()  { printf "\033[33m%s\033[0m" "$*"; }
red()     { printf "\033[31m%s\033[0m" "$*"; }

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
FIX_MODE=false

for arg in "$@"; do
  case "$arg" in
    --fix) FIX_MODE=true ;;
    -h|--help)
      echo "Usage: bash scripts/doctor.sh [--fix]"
      echo "  --fix   Attempt safe auto-fixes (xcode-select --install, etc.)"
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

pass() { printf "  $(green PASS)  %s\n" "$*"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn_msg() { printf "  $(yellow WARN)  %s\n" "$*"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail_msg() { printf "  $(red FAIL)  %s\n" "$*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
hint() { printf "        → %s\n" "$*"; }

bold ""
bold "doctor.sh — preflight health check"
bold "──────────────────────────────────────────────"

# ── 1. macOS version (≥ 15.0 Sequoia) ───────────────────────────────────────
MACOS_VER="$(sw_vers -productVersion 2>/dev/null || echo "0.0")"
MACOS_MAJOR="${MACOS_VER%%.*}"
if [ "$MACOS_MAJOR" -ge 15 ] 2>/dev/null; then
  pass "macOS version: $MACOS_VER (≥ 15.0)"
else
  fail_msg "macOS version: $MACOS_VER (need ≥ 15.0 Sequoia)"
  hint "Upgrade via System Settings → General → Software Update"
fi

# ── 2. Architecture ─────────────────────────────────────────────────────────
ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ]; then
  pass "Architecture: $ARCH (Apple Silicon)"
else
  warn_msg "Architecture: $ARCH (arm64 recommended for best performance)"
  hint "Intel Macs work but some brew packages are slower"
fi

# ── 3. Admin group ──────────────────────────────────────────────────────────
if id -Gn 2>/dev/null | tr ' ' '\n' | grep -qx admin; then
  pass "Admin group: $(whoami) is in admin group"
else
  fail_msg "Admin group: $(whoami) is NOT in admin group"
  hint "Some setup steps require admin. Ask IT to add your account."
fi

# ── 4. Disk free (≥ 20 GB) ──────────────────────────────────────────────────
# df -g gives GB on macOS
DISK_FREE_GB="$(df -g / | awk 'NR==2 {print $4}')"
if [ "${DISK_FREE_GB:-0}" -ge 20 ] 2>/dev/null; then
  pass "Disk free: ${DISK_FREE_GB}GB available (≥ 20GB)"
else
  fail_msg "Disk free: ${DISK_FREE_GB:-unknown}GB available (need ≥ 20GB)"
  hint "Free up space: empty Trash, remove old Xcode archives, prune Docker"
fi

# ── 5. Internet reachable ───────────────────────────────────────────────────
if curl -sI --max-time 10 https://github.com 2>/dev/null | head -1 | grep -q "200\|301\|302"; then
  pass "Internet: github.com reachable"
else
  fail_msg "Internet: cannot reach github.com"
  hint "Check Wi-Fi, VPN, or proxy settings"
fi

# ── 6. Xcode CLT ────────────────────────────────────────────────────────────
if xcode-select -p >/dev/null 2>&1; then
  pass "Xcode CLT: present at $(xcode-select -p)"
else
  fail_msg "Xcode CLT: not installed"
  if [ "$FIX_MODE" = "true" ]; then
    hint "Attempting fix: xcode-select --install"
    xcode-select --install 2>/dev/null || true
    hint "GUI prompt should appear. Re-run doctor after install completes."
  else
    hint "Fix: xcode-select --install (or run with --fix)"
  fi
fi

# ── 7. Homebrew ──────────────────────────────────────────────────────────────
if command -v brew >/dev/null 2>&1; then
  BREW_VER="$(brew --version 2>/dev/null | head -1)"
  BREW_WARNINGS="$(brew doctor 2>&1 | grep -c "Warning:" || true)"
  if [ "${BREW_WARNINGS:-0}" -eq 0 ]; then
    pass "Homebrew: $BREW_VER (healthy)"
  else
    warn_msg "Homebrew: $BREW_VER ($BREW_WARNINGS warning(s) from brew doctor)"
    hint "Run 'brew doctor' to see details"
  fi
else
  fail_msg "Homebrew: not installed"
  hint "Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
fi

# ── 8. Remote Login (sshd) ──────────────────────────────────────────────────
if systemsetup -getremotelogin 2>/dev/null | grep -qi "on"; then
  pass "Remote Login: enabled (sshd running)"
else
  warn_msg "Remote Login: disabled (needed for Mac-to-Mac migration)"
  hint "Enable: System Settings → General → Sharing → Remote Login"
fi

# ── 9. FileVault ─────────────────────────────────────────────────────────────
if fdesetup status 2>/dev/null | grep -qi "on"; then
  pass "FileVault: enabled"
else
  warn_msg "FileVault: not enabled (strongly recommended)"
  hint "Enable: System Settings → Privacy & Security → FileVault"
fi

# ── 10. MDM profile ─────────────────────────────────────────────────────────
MDM_OUTPUT="$(profiles status -type enrollment 2>&1 || true)"
if echo "$MDM_OUTPUT" | grep -qi "MDM enrollment: Yes"; then
  warn_msg "MDM: enrolled (some defaults may be overridden by policy)"
  hint "This is expected on corporate Macs. See README §9 MDM caveat."
elif echo "$MDM_OUTPUT" | grep -qi "not enrolled\|error"; then
  pass "MDM: not enrolled (personal Mac — full control)"
else
  pass "MDM: enrollment status unclear (continuing)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
bold ""
bold "──────────────────────────────────────────────"
printf "  Results: $(green "$PASS_COUNT PASS"), $(yellow "$WARN_COUNT WARN"), $(red "$FAIL_COUNT FAIL")\n"
bold "──────────────────────────────────────────────"

if [ "$FAIL_COUNT" -gt 0 ]; then
  bold ""
  bold "❌ Fix the FAIL items above before running bootstrap.sh"
  exit 1
else
  bold ""
  bold "✅ All clear — ready to bootstrap!"
  exit 0
fi
