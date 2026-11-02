# ~/.config/zsh/30-tools.zsh — modern CLI tool integrations.
# Each block guarded by `command -v` so missing tools just no-op.

# --- bat (better cat) ---
if command -v bat &>/dev/null; then
  alias cat='bat --paging=never'
  alias catt='/bin/cat'
fi

# --- eza (better ls) ---
if command -v eza &>/dev/null; then
  alias ls='eza --color=always --group-directories-first --icons'
  alias ll='eza -la --color=always --group-directories-first --icons --git'
  alias la='eza -a --color=always --group-directories-first --icons'
  alias lt='eza --tree --color=always --icons --level=2'
  alias l.='eza -a | grep -E "^\."'
fi

# --- fzf (fuzzy finder) ---
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
  export FZF_DEFAULT_OPTS="
    --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
    --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
    --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
    --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
    --height=60% --border=rounded --layout=reverse --info=inline
    --preview-window=right:50%:wrap"
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :200 {}'"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --icons --level=2 {} 2>/dev/null | head -50'"
fi

# --- zoxide (smarter cd) ---
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias cd='z'
  alias cdi='zi'
fi

# --- atuin (better ctrl-r — Sqlite-backed history search) ---
if command -v atuin &>/dev/null; then
  # --disable-up-arrow keeps your existing up-arrow history-search-backward binding,
  # so atuin only takes over Ctrl-R. Remove the flag if you want atuin on Up too.
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# --- direnv ---
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# --- thefuck ---
if command -v thefuck &>/dev/null; then
  eval "$(thefuck --alias fuck)"
fi

# --- iTerm2 / Ghostty shell integration ---
# iTerm2 ships its own; Ghostty auto-injects via XDG_DATA_DIRS. Only load iTerm2 file
# when actually running in iTerm2, otherwise Ghostty's integration handles it.
if [[ "$TERM_PROGRAM" == "iTerm.app" && -e "${HOME}/.iterm2_shell_integration.zsh" ]]; then
  source "${HOME}/.iterm2_shell_integration.zsh"
fi

# --- delta (git pager) ---
# git config moved to ~/.gitconfig — running it from .zshrc on every shell start
# was wasted IO. See `git config --global --list | grep delta` to verify.
