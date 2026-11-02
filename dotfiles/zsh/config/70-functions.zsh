# ~/.config/zsh/70-functions.zsh — shell functions.

# Suppress harmless macOS DBus warnings from KDE Connect CLI output.
_kdc() { "$KDECONNECT_CLI" "$@" 2>&1 | grep -v "DBus.Error.ServiceUnknown" | grep -v "error activating kdeconnectd"; }

# mkcd: make dir and cd into it
mkcd() { mkdir -p "$1" && cd "$1" }

# extract: universal archive extractor
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)  tar xvjf "$1"   ;;
      *.tar.gz)   tar xvzf "$1"   ;;
      *.tar.xz)   tar xvJf "$1"   ;;
      *.bz2)      bunzip2 "$1"    ;;
      *.gz)       gunzip "$1"     ;;
      *.zip)      unzip "$1"      ;;
      *.7z)       7z x "$1"       ;;
      *)          echo "Cannot extract '$1'" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# fcd: fuzzy cd with preview
fcd() {
  local dir
  dir=$(fd --type d --hidden --follow --exclude .git 2>/dev/null | fzf --preview 'eza --tree --color=always {} | head -50') && cd "$dir"
}

# fh: fuzzy command history (atuin handles Ctrl-R; this stays for explicit calls)
fh() {
  eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -r 's/ *[0-9]*\*? *//' | sed -r 's/\\/\\\\/g')
}

# gitlog: pretty git log with fzf preview
gitlog() {
  git log --oneline --color=always | fzf --ansi --preview 'git show {1} --color=always | head -100'
}

# yazi cwd-on-exit wrapper
if command -v yazi &>/dev/null; then
  yy() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
fi

# Display image inline (iTerm2)
show() { imgcat "$1" }

# Smart VS Code open: e (no arg → cwd) or e <path>
e() {
  if [ -z "$1" ]; then
    code .
  else
    code "$1"
  fi
}

# killport <port>: kill whoever's holding a TCP port
killport() { lsof -ti tcp:"$1" | xargs kill -9; }

# pf: process picker → prints PID
pf() { ps aux | fzf --header "Select process" | awk '{print $2}'; }
