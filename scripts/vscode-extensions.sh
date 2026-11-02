#!/usr/bin/env bash
# ============================================================================
# vscode-extensions.sh — Install curated VS Code extension set.
#
# Pattern: config-as-data at top, apply logic at bottom.
# Idempotent: `code --install-extension` is a no-op if already installed.
#
# Groups:
#   CORE_EXTS: always installed (24 — daily-driver tooling)
#   SAP_EXTS: installed only when user opts in (13 — SAP work tooling)
#
# Prompt behavior: if SAP_INSTALL is unset AND stdin is a TTY, asks interactively.
# Non-interactive runs (bootstrap.sh invoked via nohup/pipe) default to SKIP SAP
# unless SAP_INSTALL=true is pre-set in the environment.
#
# WHY curated list vs `code --list-extensions > file`:
#   The repo is the source of truth. Dropping bloat requires an explicit entry
#   per extension with a WHY comment, same discipline as scripts/<area>-defaults.sh.
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh" 2>/dev/null || true

log()  { printf "  [vscode-ext] %s\n" "$*"; }
warn() { printf "  [vscode-ext] WARN: %s\n" "$*" >&2; }

# ── CORE: always install ─────────────────────────────────────────────────────
# Daily-driver extensions. Dropping bloat (removed: remotehub, azure-repos,
# remote-explorer, remote-repositories, remote-server, remote-extensionpack
# umbrella, ms-azuretools containers, material-product-icons dup, kaosc hyle,
# thunder-client (Bruno covers), claude-dev (anthropic.claude-code covers),
# yeoman-ui (SAP modeler covers)).
CORE_EXTS=(
  # AI
  anthropic.claude-code                        # Claude Code agent

  # Git
  eamodio.gitlens                              # blame, lens, history
  github.vscode-pull-request-github            # PR review in editor

  # Language: Python
  ms-python.python                             # core Python
  ms-python.vscode-pylance                     # intellisense
  ms-python.debugpy                            # debugger
  kevinrose.vsc-python-indent                  # correct indent on newline
  ms-toolsai.jupyter                           # notebooks

  # Language: Web / Markup
  dbaeumer.vscode-eslint                       # JS/TS lint
  esbenp.prettier-vscode                       # formatter
  davidanson.vscode-markdownlint               # markdown lint
  yoavbls.pretty-ts-errors                     # readable TS errors
  redhat.vscode-xml                            # XML LSP
  redhat.vscode-yaml                           # YAML LSP (k8s, actions)

  # Editor utility
  christian-kohler.path-intellisense           # path autocomplete
  editorconfig.editorconfig                    # .editorconfig
  usernamehw.errorlens                         # inline diagnostics
  mechatroner.rainbow-csv                      # CSV colorization
  qwtel.sqlite-viewer                          # .db / .sqlite preview

  # Theme / icons
  pkief.material-icon-theme                    # file icons
  zhuangtongfa.material-theme                  # One Dark Pro

  # Remote dev
  ms-vscode-remote.remote-ssh                  # SSH dev
  ms-vscode-remote.remote-containers           # devcontainers

  # Diagrams
  pomdtr.excalidraw-editor                     # excalidraw native in VS Code
)

# ── SAP: install only when SAP_INSTALL=true (prompted if interactive) ────────
# Work-only. Skip on personal Macs.
SAP_EXTS=(
  saposs.app-studio-remote-access              # BAS remote access
  saposs.app-studio-toolkit                    # BAS toolkit base
  saposs.code-snippet-tool                     # SAP code snippets
  saposs.sap-ux-sap-systems-ext                # register SAP systems
  saposs.vscode-ui5-language-assistant         # UI5 LSP
  sapse.sap-ux-annotation-modeler-extension    # CAP/Fiori annotations
  sapse.sap-ux-application-modeler-extension   # Fiori app modeler
  sapse.sap-ux-fiori-tools-extension-pack      # Fiori tools (meta pack)
  sapse.sap-ux-help-extension                  # SAP help lookup
  sapse.sap-ux-service-modeler-extension       # OData service modeler
  sapse.service-catalog                        # SAP service catalog
  sapse.vscode-cds                             # CAP CDS language
)

# ── BLOAT dropped (keep as audit trail, DO NOT re-add without reason) ────────
#   github.remotehub                           # Microsoft deprecated 2024
#   ms-vscode-remote.vscode-remote-extensionpack # umbrella — install specifics instead
#   ms-vscode.azure-repos                      # Azure DevOps — not used
#   ms-vscode.remote-explorer                  # auto-pulled by remote-ssh
#   ms-vscode.remote-repositories              # tied to remotehub (deprecated)
#   ms-vscode.remote-server                    # internal infra, not needed
#   ms-azuretools.vscode-containers            # old name; superseded + unused
#   pkief.material-product-icons               # dup of material-icon-theme
#   kaosc.hyle                                 # toy; rainbow-csv covers
#   rangav.vscode-thunder-client               # Postman clone; using Bruno
#   saoudrizwan.claude-dev                     # Cline; anthropic.claude-code covers
#   sapos.yeoman-ui                            # SAP modeler covers scaffolding

# ─────────────────────────────────────────────────────────────────────────────
# APPLY
# ─────────────────────────────────────────────────────────────────────────────

if ! command -v code >/dev/null 2>&1; then
  warn "'code' CLI not found. Install VS Code and 'Shell Command: Install code command in PATH'."
  warn "Skipping VS Code extension install."
  exit 0
fi

install_one() {
  local ext="$1"
  if code --list-extensions 2>/dev/null | grep -qx "$ext"; then
    printf "    skip   %-55s (already installed)\n" "$ext"
  else
    if code --install-extension "$ext" --force >/dev/null 2>&1; then
      printf "    install %-54s ✓\n" "$ext"
    else
      printf "    FAIL   %-55s ✗\n" "$ext"
    fi
  fi
}

log "installing CORE extensions (${#CORE_EXTS[@]})..."
for ext in "${CORE_EXTS[@]}"; do
  install_one "$ext"
done

# SAP opt-in gate
if [ -z "${SAP_INSTALL+x}" ]; then
  if [ -t 0 ]; then
    echo ""
    read -r -p "  [vscode-ext] Install ${#SAP_EXTS[@]} SAP extensions? [y/N] " SAP_INSTALL_REPLY
    case "${SAP_INSTALL_REPLY:-N}" in
      [yY]|[yY][eE][sS]) SAP_INSTALL=true ;;
      *) SAP_INSTALL=false ;;
    esac
  else
    log "SAP_INSTALL unset and no TTY — skipping SAP extensions."
    log "  Re-run with: SAP_INSTALL=true bash scripts/vscode-extensions.sh"
    SAP_INSTALL=false
  fi
fi

if [ "$SAP_INSTALL" = "true" ]; then
  log "installing SAP extensions (${#SAP_EXTS[@]})..."
  for ext in "${SAP_EXTS[@]}"; do
    install_one "$ext"
  done
else
  log "SAP extensions SKIPPED (set SAP_INSTALL=true to include)."
fi

log "done. Current extension count: $(code --list-extensions 2>/dev/null | wc -l | tr -d ' ')"
