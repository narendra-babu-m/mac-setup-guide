# ~/.config/zsh/10-history.zsh — zsh history settings.

HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

setopt HIST_EXPIRE_DUPS_FIRST   # drop oldest duplicate first when trimming
setopt HIST_IGNORE_DUPS         # don't record consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS     # remove all earlier duplicates of a command
setopt HIST_IGNORE_SPACE        # don't record commands starting with space
setopt HIST_FIND_NO_DUPS        # don't show dupes in interactive search
setopt HIST_VERIFY              # show command before executing from history expansion
setopt SHARE_HISTORY            # share history between all sessions
setopt EXTENDED_HISTORY         # write timestamps + duration
setopt HIST_REDUCE_BLANKS       # trim superfluous whitespace in stored commands
