# ~/.config/zsh/50-keybindings.zsh — key bindings.

bindkey '^[[A' history-search-backward     # Up arrow: prefix search backward
bindkey '^[[B' history-search-forward      # Down arrow: prefix search forward
bindkey '^[^[[C' forward-word              # Alt+Right: forward word
bindkey '^[^[[D' backward-word             # Alt+Left: backward word

# zsh-autosuggestions
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6272a4,bold'
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
bindkey '^ ' autosuggest-accept            # Ctrl+Space: accept suggestion

# Edit current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line           # Ctrl+X Ctrl+E
