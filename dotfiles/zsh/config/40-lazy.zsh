# ~/.config/zsh/40-lazy.zsh — lazy-load slow init scripts.
# nvm: ~585ms.  conda: ~312ms.  pyenv init: ~50ms.
# Each shell pays the cost only when you actually USE the tool, not at startup.

# ---------------------------------------------------------------------------
# nvm — defer until first use of nvm/node/npm/npx/yarn/pnpm
# ---------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"

# Wrappers that load nvm on first call, then exec the real binary.
nvm() {
  unset -f nvm node npm npx yarn pnpm 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}

# Only set node-related stubs if there isn't already a node on PATH outside ~/.nvm.
# (Homebrew node is on PATH already at /opt/homebrew/bin/node — we keep that.)
if [[ ! -x /opt/homebrew/bin/node ]]; then
  node() { unset -f nvm node npm npx yarn pnpm 2>/dev/null; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node "$@"; }
  npm()  { unset -f nvm node npm npx yarn pnpm 2>/dev/null; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npm  "$@"; }
  npx()  { unset -f nvm node npm npx yarn pnpm 2>/dev/null; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npx  "$@"; }
fi

# ---------------------------------------------------------------------------
# conda / miniforge — defer until first call to conda/mamba
# ---------------------------------------------------------------------------
_load_conda() {
  unset -f _load_conda conda mamba 2>/dev/null
  __conda_setup="$('/opt/homebrew/Caskroom/miniforge/base/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  elif [ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
    . "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"
  else
    export PATH="/opt/homebrew/Caskroom/miniforge/base/bin:$PATH"
  fi
  unset __conda_setup
}
conda() { _load_conda; conda "$@"; }
mamba() { _load_conda; mamba "$@"; }

# ---------------------------------------------------------------------------
# pyenv — defer init eval (the PATH bit is already set in 00-paths.zsh)
# ---------------------------------------------------------------------------
pyenv() {
  unset -f pyenv 2>/dev/null
  eval "$(command pyenv init - --no-rehash)"
  pyenv "$@"
}
