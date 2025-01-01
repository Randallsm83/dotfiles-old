## History wrapper
function omz_history {
  # parse arguments and remove from $@
  local clear list stamp REPLY
  zparseopts -E -D c=clear l=list f=stamp E=stamp i=stamp t:=stamp

  if [[ -n "$clear" ]]; then
    # if -c provided, clobber the history file

    # confirm action before deleting history
    print -nu2 "This action will irreversibly delete your command history. Are you sure? [y/N] "
    builtin read -E
    [[ "$REPLY" = [yY] ]] || return 0

    print -nu2 >| "$HISTFILE"
    fc -p "$HISTFILE"

    print -u2 History file deleted.
  elif [[ $# -eq 0 ]]; then
    # if no arguments provided, show full history starting from 1
    builtin fc $stamp -l 1
  else
    # otherwise, run `fc -l` with a custom format
    builtin fc $stamp -l "$@"
  fi
}

# Timestamp format
case ${HIST_STAMPS-} in
  "mm/dd/yyyy") alias history='omz_history -f' ;;
  "dd.mm.yyyy") alias history='omz_history -E' ;;
  "yyyy-mm-dd") alias history='omz_history -i' ;;
  "") alias history='omz_history' ;;
  *) alias history="omz_history -t '$HIST_STAMPS'" ;;
esac

## History file configuration
ZSTATE="$XDG_STATE_HOME/zsh"
if [[ ! -d $ZSTATE ]]; then
    echo "Creating directory: $ZSTATE"
    mkdir -p "$ZSTATE" || { echo "Failed to create history dir: $ZSTATE" >&2; return 1; }
fi

HISTFILE="$ZSTATE/zsh_history"
HISTSIZE=1000000
SAVEHIST="$HISTSIZE"

## History command configuration
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_find_no_dups      # Do not display old duplicates in history search
setopt hist_save_no_dups      # Do not save duplicate commands in history
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_all_dups   # Delete old recorded entry if new entry is a duplicate.
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_reduce_blanks     # Remove unnecessary blanks
