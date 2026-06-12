# ============================================================================
# zellij.zsh — Zellij aliases (sourced from ~/.zshrc)
#   Source of truth: ~/mac-setup-guide/dotfiles/zsh/zellij.zsh (symlinked)
# ============================================================================
# fleet         → 4-pane Hermes agent grid (~/.config/zellij/layouts/fleet.kdl)
# zj            → bare zellij (default layout)
# zja <name>    → attach to a session by name
# zjl           → list active sessions
# zjk <name>    → kill a session by name

alias fleet='zellij --layout fleet'
alias zj='zellij'
alias zja='zellij attach'
alias zjl='zellij list-sessions'
alias zjk='zellij kill-session'
