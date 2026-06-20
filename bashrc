[[ $- != *i* ]] && return

# Colors
RS="\033[0m"
RED="\033[0;31m"
GRN="\033[0;32m"
YLW="\033[0;33m"
BLU="\033[0;34m"
MAG="\033[0;35m"
CYN="\033[0;36m"
WHT="\033[0;37m"

# Default Editor
#export EDITOR="vim"
export EDITOR="nvim"

# History
HISTSIZE=5000
HISTFILESIZE=10000

# aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Settings
bind "set completion-ignore-case on"    # Case-insensitive tab completion
# up and down arrows to search through history
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# extract bash function
function extract () {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjvf $1    ;;
      *.tar.gz)    tar xzvf $1    ;;
      *.tar.xz)    tar xvf $1    ;;
      *.bz2)       bzip2 -d $1    ;;
      *.rar)       unrar2dir $1    ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1    ;;
      *.tgz)       tar xzf $1    ;;
      *.zip)       unzip2dir $1     ;;
      *.Z)         uncompress $1    ;;
      *.7z)        7z x $1    ;;
      *.ace)       unace x $1    ;;
      *)           echo "'$1' cannot be extracted via extract()"   ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Git status
parse_git_bg() {
  local branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  if [ -n "$branch" ]; then
    local status=$(git status --porcelain 2> /dev/null)
    if [ -n "$status" ]; then
      echo -e " ${RED}(git:${branch}*)$RS"
    else
      echo -e " ${GRN}(git:${branch})$RS"
    fi
  fi
}

# Bash prompt
export PS1="\[$CYN\]\u\[$RS\]\[$BLU\]@\[$RS\]\[$GRN\]\h\[$RS\]\[$YLW\] \w\[$RS\] \$(parse_git_bg) \n\[$CYN\]\\$ \[$RS\]"
