# ~/.config/zsh/60-aliases.zsh — aliases organised by domain.

# ============================================================
# Git
# ============================================================
alias gs='git status'
alias gp='git pull'
alias gc='git commit -m'
alias gps='git push'
alias gl='git log --oneline --graph --decorate -10'
alias gd='git diff'
alias gds='git diff --staged'
alias gdw='git diff --word-diff'
command -v lazygit &>/dev/null && alias lg='lazygit'

# ============================================================
# Modern tool upgrades (color)
# ============================================================
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias df='df -h'
alias disk='df -h | grep -v tmpfs'

# ============================================================
# JSON / YAML
# ============================================================
alias json='python3 -m json.tool'
alias jsonf='jq .'

# ============================================================
# Quick HTTP servers
# ============================================================
alias serve='python3 -m http.server 8080'
alias serve3000='python3 -m http.server 3000'

# ============================================================
# Network
# ============================================================
alias myip='curl -s https://ifconfig.me && echo'
alias localip='ipconfig getifaddr en0'
alias ports='lsof -i -P -n | grep LISTEN'
alias flush-dns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder && echo DNS flushed'

# ============================================================
# Quick directory operations
# ============================================================
alias ..='z ..'
alias ...='z ../..'
alias ....='z ../../..'
alias ~='z ~'

# ============================================================
# Project navigation
# ============================================================
alias proj='cd ~/Projects'
alias sap-proj='cd ~/Projects/SAP'
alias ai-proj='cd ~/Projects/AI'
alias mcp-proj='cd ~/Projects/MCP'

# ============================================================
# Docker
# ============================================================
alias dk='docker'
alias dkps='docker ps'
alias dkpsa='docker ps -a'
alias dki='docker images'
alias dkrm='docker rm'
alias dkrmi='docker rmi'
alias dkexec='docker exec -it'
alias dklogs='docker logs -f'
alias dkstop='docker stop $(docker ps -q)'
alias dkclean='docker system prune -f'
alias dkc='docker compose'
alias dkcu='docker compose up -d'
alias dkcd='docker compose down'

# ============================================================
# Kubernetes (kubectx/kubens shortcuts — installed via brew)
# ============================================================
alias kx='kubectx'    # switch context interactively
alias kn='kubens'     # switch namespace interactively

# ============================================================
# tmux
# ============================================================
if command -v tmux &>/dev/null; then
  alias t='tmux'
  alias tn='tmux new -s'
  alias ta='tmux attach -t'
  alias tl='tmux ls'
  alias tk='tmux kill-session -t'
  alias td='tmux detach'
  # iTerm2 native tmux integration
  alias tcc='tmux -CC new -s main 2>/dev/null || tmux -CC attach -t main'
  alias tca='tmux -CC attach -t'
fi

# ============================================================
# Modern TUI tools
# ============================================================
command -v btop &>/dev/null && alias top='btop' && alias cpu='btop'
command -v glow &>/dev/null && alias mdcat='glow' && alias readme='glow README.md'
command -v ncdu &>/dev/null && alias du='ncdu --color dark' && alias duh='ncdu --color dark -x .'
command -v procs &>/dev/null && alias ps='procs' && alias psg='procs --sortd cpu'
command -v fastfetch &>/dev/null && alias sysinfo='fastfetch'
command -v http &>/dev/null && alias GET='http GET' && alias POST='http POST' && alias PUT='http PUT' && alias DELETE='http DELETE'

# ============================================================
# AI Workstation
# ============================================================
alias asus='ssh asus-rog'
alias asus-code='code --remote ssh-remote+asus-rog /mnt/d/Projects'
alias chat='open http://localhost:3000'
alias n8n-open='open http://localhost:5678'
alias models='ollama list'
alias ollama-start='brew services start ollama'
alias ollama-stop='brew services stop ollama'
alias ai="source ~/Projects/AI/.venv-ai/bin/activate"
alias deai='conda deactivate'
alias jup='jupyter notebook'
alias ipy='ipython'
alias ai-code='claude'
alias claude-auth='claude login'
alias ask='ollama run phi3:mini'

# ============================================================
# SAP CAP / UI5 / Cloud Foundry
# ============================================================
alias cap-new='cds init'
alias cap-watch='cds watch'
alias cap-build='cds build'
alias cap-deploy='cds deploy'
alias cap-run='cds run'
alias ui5-new='ui5 init'
alias ui5-serve='ui5 serve'
alias ui5-build='ui5 build'
alias ui5-lint='ui5 lint'
alias cf-login='cf login -a https://api.cf.us10.hana.ondemand.com'
alias cf-apps='cf apps'
alias cf-push='cf push'
alias cf-services='cf services'

# ============================================================
# iTerm2 utilities
# ============================================================
alias icat='imgcat'
alias it2tip='~/.iterm2/it2tip'
alias copy-here='~/.iterm2/it2copy'
alias download='~/.iterm2/it2dl'
alias upload='~/.iterm2/it2ul'
alias it2attention='~/.iterm2/it2attention'

# ============================================================
# yazi (file manager)
# ============================================================
if command -v yazi &>/dev/null; then
  alias fm='yazi'
fi

# ============================================================
# KDE Connect (phone bridge — Samsung S24 Ultra)
# ============================================================
alias phone-ping='_kdc --device $PHONE_ID --ping-msg'
alias phone-send='_kdc --device $PHONE_ID --share'
alias phone-find='_kdc --device $PHONE_ID --ring'
alias phone-list='_kdc -a'
alias phone-status='_kdc -l'
