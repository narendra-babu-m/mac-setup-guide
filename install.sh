#!/usr/bin/env bash
# ============================================================================
# install.sh — One-liner bootstrap for a fresh Mac.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/narendra-babu-m/mac-setup-guide/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --profile=sap-work
#
# What it does (all idempotent):
#   1. Verifies macOS + bash
#   2. Installs Xcode CLT if missing (triggers GUI — re-run after install)
#   3. Installs Homebrew if missing
#   4. Clones repo to ~/mac-setup-guide (or pulls if exists)
#   5. Runs scripts/doctor.sh preflight
#   6. Invokes bootstrap.sh with --profile if given
# ============================================================================

set -euo pipefail

bold()    { printf "\033[1m%s\033[0m\n" "$*"; }
section() { printf "\n\033[1;34m── %s ──\033[0m\n" "$*"; }
fail()    { printf "\033[1;31mERROR:\033[0m %s\n" "$*" >&2; exit 1; }

REPO_URL="https://github.com/narendra-babu-m/mac-setup-guide.git"
CLONE_DIR="$HOME/mac-setup-guide"
PROFILE=""

# ── Parse args ───────────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --profile=*) PROFILE="${arg#--profile=}" ;;
    -h|--help)
      echo "Usage: curl -fsSL .../install.sh | bash -s -- [--profile=minimal|sap-work]"
      echo ""
      echo "Profiles:"
      echo "  minimal   (default) — core setup, no SAP/Hermes"
      echo "  sap-work  — adds SAP VS Code extensions, Hermes, LaunchAgents"
      exit 0
      ;;
    *) fail "Unknown argument: $arg" ;;
  esac
done

# ── 1. Verify macOS ─────────────────────────────────────────────────────────
section "Checking environment"

if [ "$(uname)" != "Darwin" ]; then
  fail "This script is macOS-only (detected: $(uname)). Exiting."
fi
echo "  ✓ macOS detected"

ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ]; then
  echo "  ✓ Apple Silicon (arm64)"
else
  echo "  ⚠ Architecture: $ARCH (arm64 recommended but continuing)"
fi

if [ -z "${BASH_VERSION:-}" ]; then
  fail "Bash required. Run with: bash <(curl -fsSL ...)"
fi
echo "  ✓ bash $BASH_VERSION"

# ── 2. Xcode CLT ────────────────────────────────────────────────────────────
section "Xcode Command Line Tools"

if ! xcode-select -p >/dev/null 2>&1; then
  bold "Installing Xcode Command Line Tools (will prompt GUI)..."
  xcode-select --install 2>/dev/null || true
  echo ""
  bold "⏳ Xcode CLT install started. Once it finishes, re-run this command:"
  echo "   curl -fsSL https://raw.githubusercontent.com/narendra-babu-m/mac-setup-guide/main/install.sh | bash${PROFILE:+ -s -- --profile=$PROFILE}"
  exit 0
fi
echo "  ✓ Xcode CLT present at $(xcode-select -p)"

# ── 3. Homebrew ──────────────────────────────────────────────────────────────
section "Homebrew"

if ! command -v brew >/dev/null 2>&1; then
  bold "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon brew lives in /opt/homebrew
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi
echo "  ✓ brew at $(command -v brew) — $(brew --version | head -1)"

# ── 4. Clone or update repo ─────────────────────────────────────────────────
section "Repository"

if [ -d "$CLONE_DIR/.git" ]; then
  bold "Repo exists — pulling latest..."
  git -C "$CLONE_DIR" pull --ff-only || echo "  (pull failed — using existing checkout)"
else
  bold "Cloning mac-setup-guide..."
  git clone "$REPO_URL" "$CLONE_DIR"
fi
echo "  ✓ repo at $CLONE_DIR"

# ── 5. Preflight doctor ─────────────────────────────────────────────────────
section "Preflight checks"

if [ -x "$CLONE_DIR/scripts/doctor.sh" ]; then
  bash "$CLONE_DIR/scripts/doctor.sh" || {
    echo ""
    bold "⚠ Preflight found FAILs. Fix the issues above, then re-run."
    bold "  Or run with --fix: bash $CLONE_DIR/scripts/doctor.sh --fix"
    exit 1
  }
else
  echo "  (doctor.sh not found — skipping preflight)"
fi

# ── 6. Run bootstrap ────────────────────────────────────────────────────────
section "Running bootstrap"

BOOTSTRAP_ARGS=()
[ -n "$PROFILE" ] && BOOTSTRAP_ARGS+=("--profile=$PROFILE")

bold "Invoking: bash $CLONE_DIR/bootstrap.sh ${BOOTSTRAP_ARGS[*]:-}"
exec bash "$CLONE_DIR/bootstrap.sh" "${BOOTSTRAP_ARGS[@]:-}"
