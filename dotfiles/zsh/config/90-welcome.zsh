# ~/.config/zsh/90-welcome.zsh — welcome screen on interactive shells.

# fastfetch on new terminal — works in iTerm2, Ghostty, Warp, Terminal.app, etc.
# Skip inside tmux (would print on every new pane), and skip non-interactive shells.
if command -v fastfetch &>/dev/null && [[ -z "$TMUX" ]] && [[ -o interactive ]]; then
  case "$TERM_PROGRAM" in
    iTerm.app|ghostty|WarpTerminal|Apple_Terminal|tmux|vscode)
      fastfetch --logo-type small 2>/dev/null
      ;;
  esac
fi
