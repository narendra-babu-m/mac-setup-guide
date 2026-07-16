#!/usr/bin/env bash
# ============================================================================
# bootstrap.sh — Fresh-Mac one-day setup orchestrator.
#
# Goal: from a brand-new Mac to "ready to work" in a single session.
#
# Idempotent: every step can be re-run safely. Run it once, run it again
# after macOS upgrades, run it on a personal Mac you buy in three years.
#
# Usage:
#   bash bootstrap.sh                    # run all phases
#   bash bootstrap.sh --skip-brew        # skip brew install (already done)
#   bash bootstrap.sh --skip-defaults    # only install software
#   bash bootstrap.sh --only-defaults    # only apply defaults scripts
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$REPO_ROOT/scripts"

SKIP_BREW=false
SKIP_DEFAULTS=false
ONLY_DEFAULTS=false

for arg in "$@"; do
  case "$arg" in
    --skip-brew)     SKIP_BREW=true ;;
    --skip-defaults) SKIP_DEFAULTS=true ;;
    --only-defaults) ONLY_DEFAULTS=true; SKIP_BREW=true ;;
    -h|--help)
      sed -n '1,30p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $arg"; exit 2 ;;
  esac
done

bold()    { printf "\033[1m%s\033[0m\n" "$*"; }
section() { printf "\n\033[1;34m── %s ──\033[0m\n" "$*"; }

# ── Phase 0: prereqs ────────────────────────────────────────────────────────
section "Phase 0: prerequisites"

if ! xcode-select -p >/dev/null 2>&1; then
  bold "Installing Xcode Command Line Tools (will prompt GUI)..."
  xcode-select --install || true
  echo "Re-run bootstrap.sh once the install finishes."
  exit 0
fi
echo "  ✓ xcode CLI tools present"

if ! command -v brew >/dev/null 2>&1; then
  bold "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon brew lives in /opt/homebrew
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi
echo "  ✓ brew present at $(command -v brew)"

# ── Phase 1: install software via Brewfile ──────────────────────────────────
if [ "$SKIP_BREW" = "false" ]; then
  section "Phase 1: brew bundle"
  brew update
  brew bundle --file="$REPO_ROOT/Brewfile"
else
  echo "  (skipping brew per flag)"
fi

# ── Phase 2: macOS defaults ─────────────────────────────────────────────────
if [ "$SKIP_DEFAULTS" = "false" ]; then
  section "Phase 2: macOS defaults"
  for script in \
    finder-defaults.sh \
    dock-defaults.sh \
    screenshot-defaults.sh \
    keyboard-defaults.sh \
    trackpad-defaults.sh \
    general-ui-defaults.sh \
    security-defaults.sh \
    git-defaults.sh \
    default-apps.sh
  do
    if [ -x "$SCRIPTS/$script" ]; then
      bold "→ $script"
      bash "$SCRIPTS/$script" || echo "  (continuing despite error in $script)"
    else
      echo "  skip: $script not found or not executable"
    fi
  done
else
  echo "  (skipping defaults per flag)"
fi

# ── Phase 2.5: dotfile symlinks ─────────────────────────────────────────────
if [ "$SKIP_DEFAULTS" = "false" ]; then
  section "Phase 2.5: dotfile symlinks"
  if [ -x "$SCRIPTS/dotfiles-link.sh" ]; then
    bash "$SCRIPTS/dotfiles-link.sh" || echo "  (continuing despite error in dotfiles-link.sh)"
  else
    echo "  skip: dotfiles-link.sh not found"
  fi
fi

# ── Phase 3: manual reminders ───────────────────────────────────────────────
section "Phase 3: things you must do manually"
cat <<EOF

The following CANNOT be scripted (Apple security model, Login Items, etc.).
See MANUAL_STEPS.md for the full checklist with click paths.

  Critical (do today):
    1. Sign in to iCloud + Apple ID
    2. Enable FileVault (System Settings → Privacy & Security)
    3. Enable Firewall (System Settings → Network → Firewall)
    4. Enable Touch ID for sudo (sudo sed in /etc/pam.d/sudo)
    5. Sign in to Bitwarden / 1Password / your secrets manager
    6. GitHub auth: gh auth login + SSH key
    7. Restore Hermes config (~/.hermes/) from backup or fresh init
    8. Restore SSH keys, gpg keys from your secure backup

  Important (this week):
    - Configure Raycast (settings, hotkey ⌘Space, extensions)
    - Sign in to all browsers, restore extensions
    - Sign in to Obsidian / Vault git remotes
    - Restore your dotfiles repo

EOF

bold "Bootstrap complete. Open MANUAL_STEPS.md for the rest."
