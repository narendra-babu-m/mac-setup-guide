# ~/.config/zsh/20-completion.zsh — zsh completion behaviour.

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*' rehash true                       # auto-find new commands
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'

# fzf-tab integrations
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always $realpath 2>/dev/null | head -50'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --tree --color=always $realpath 2>/dev/null | head -50'
zstyle ':fzf-tab:complete:git-(add|diff|restore|checkout):*' fzf-preview \
  'git diff --color=always $realpath 2>/dev/null | head -200'
zstyle ':fzf-tab:complete:git-(checkout|branch|merge|rebase):*' fzf-preview \
  'git log --color=always --oneline --graph -20 $word 2>/dev/null'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview \
  'ps -p $word -o cmd --no-headers -w -w 2>/dev/null'
zstyle ':fzf-tab:*' fzf-flags --height=60% --layout=reverse --border=rounded
zstyle ':fzf-tab:*' switch-group ',' '.'
