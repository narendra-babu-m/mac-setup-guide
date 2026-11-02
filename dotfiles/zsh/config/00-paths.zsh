# ~/.config/zsh/00-paths.zsh — PATH and environment variables.
# Loaded first because everything else needs PATH set up.

# --- VS Code ---
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# --- Java (OpenJDK 17) ---
export PATH="/usr/local/opt/openjdk@17/bin:$PATH"

# --- Local user bin ---
export PATH="$HOME/.local/bin:$PATH"

# --- Antigravity IDE ---
export PATH="$HOME/.antigravity-ide/antigravity-ide/bin:$PATH"

# --- pyenv (init eval moved to plugins.zsh — only the path bit lives here) ---
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# --- Editor ---
export EDITOR='code -w'
export VISUAL='code -w'

# --- Locale ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- ripgrep config ---
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgreprc"

# --- bat theme ---
export BAT_THEME="Dracula"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# --- MII (legacy creds — kept for compat) ---
export MII_PASS="REPLACE_FROM_BITWARDEN"
export MII_USER="mnarendra"

# --- KDE Connect (phone bridge — Samsung S24 Ultra) ---
export KDECONNECT_CLI="/Applications/KDE Connect.app/Contents/MacOS/kdeconnect-cli"
export PHONE_ID="0e8e1f3159e04b7bbec69acb5b9782a0"
