##############
#  My Zshrc  #
#   v. 1.0   #
##############

###############
#  Oh My Zsh  #
###############

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Enable extended globbing
setopt extended_glob

# Theme
# ZSH_THEME="dracula"
TERM=xterm-256color
export DEFAULT_USER='randall'
POWERLEVEL9K_MODE='nerdfont-complete'
ZSH_THEME='powerlevel9k/powerlevel9k'
# POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline status)
# POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
# POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_RPROMPT_ON_NEWLINE=true
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_beginning"
POWERLEVEL9K_RVM_BACKGROUND="black"
POWERLEVEL9K_RVM_FOREGROUND="249"
POWERLEVEL9K_RVM_VISUAL_IDENTIFIER_COLOR="red"
POWERLEVEL9K_TIME_BACKGROUND="black"
POWERLEVEL9K_TIME_FOREGROUND="249"
POWERLEVEL9K_TIME_FORMAT="\UF43A %D{%H:%M  \UF133  %d.%m.%y}"
POWERLEVEL9K_RVM_BACKGROUND="black"
POWERLEVEL9K_RVM_FOREGROUND="249"
POWERLEVEL9K_RVM_VISUAL_IDENTIFIER_COLOR="red"
POWERLEVEL9K_STATUS_VERBOSE=false
POWERLEVEL9K_VCS_CLEAN_FOREGROUND='black'
POWERLEVEL9K_VCS_CLEAN_BACKGROUND='green'
POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='black'
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='yellow'
POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='white'
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='black'
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='black'
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='blue'
POWERLEVEL9K_FOLDER_ICON=''
POWERLEVEL9K_STATUS_OK_IN_NON_VERBOSE=true
POWERLEVEL9K_STATUS_VERBOSE=false
POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0
POWERLEVEL9K_VCS_UNTRACKED_ICON='\u25CF'
POWERLEVEL9K_VCS_UNSTAGED_ICON='\u00b1'
POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='\u2193'
POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='\u2191'
POWERLEVEL9K_VCS_COMMIT_ICON="\uf417"
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%F{blue}\u256D\u2500%F{white}"
POWERLEVEL9K_MULTILINE_SECOND_PROMPT_PREFIX="%F{blue}\u2570\uf460%F{white} "
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context os_icon ssh root_indicator dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(command_execution_time status rvm time)

# Auto correction
ENABLE_CORRECTION="true"

# Show waiting for completion dots
COMPLETION_WAITING_DOTS="true"

# Make repo status checking faster
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Plugins
plugins=(brew cask git npm osx perl perlbrew pip python tmux vagrant)
#(brew brew-cask colored-man colorize extract git github go osx perl pip python tmux vagrant web-search)

source $ZSH/oh-my-zsh.sh

#################
#  User Config  #
#################

# You may need to manually set your language environment
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Set local preferred editor
export EDITOR='vim'

## Vi mode, preserve some emacs bindings
#bindkey -v
#bindkey '^P' up-history
#bindkey '^N' down-history
#bindkey '^a' beginning-of-line
#bindkey '^e' end-of-line
#bindkey '^?' backward-delete-char
#bindkey '^h' backward-delete-char
#bindkey '^u' kill-region
#bindkey '^w' backward-kill-word
#bindkey '^r' history-incremental-search-backward
#
#function zle-line-init zle-keymap-select {
#    VIM_PROMPT="%{$fg_bold[yellow]%} [% NORMAL]%  %{$reset_color%}"
#    RPS1="${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/}$EPS1"
#    zle reset-prompt
#}
#
#zle -N zle-line-init
#zle -N zle-keymap-select
#export KEYTIMEOUT=1

# Do following only if not SSH session
fullname=`hostname -f 2>/dev/null || hostname`
case $fullname in
	*dreamhost.com) ;&
	*newdream.net)
	machine_type="$machine_type:ndn"
	;;
esac

if [[ $machine_type != ':ndn' ]]; then
	# source perlbrew
	source ~/perl5/perlbrew/etc/bashrc

	 export NVM_DIR="$HOME/.nvm"
  . "/usr/local/opt/nvm/nvm.sh"

	# local::lib
	# eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
fi

# perl
export PERL5LIB="$HOME/ndn/perl/"

# Aliases
source ~/.aliases

# Paths
export PATH=$HOME/local:$HOME/ndn/dh/bin:$HOME/bin:/usr/local/bin:/usr/local/sbin:$PATH
export PATH="$PATH:$HOME/.rvm/bin" # RVM
export GOPATH=$HOME/go # Golang
export GOROOT=/usr/local/opt/go/libexec # Golang
export PATH=$PATH:$GOPATH/bin # Golang
export PATH=$PATH:$GOROOT/bin # Golang
# export MANPATH="/usr/local/man:$MANPATH"


################
# SSH-y things #
################

SSH_ENV="$HOME/.ssh/environment"

# Add appropriate ssh keys to the agent
function add_personal_keys {
	# Test whether standard identities have been added to the agent already
	if [ -f ~/.ssh/id_rsa ]; then
		ssh-add -l | grep "id_rsa" > /dev/null
		if [ $? -ne 0 ]; then
			ssh-add -t 32400 # Basic ID active for 9 hours
			# $SSH_AUTH_SOCK broken so we start a new proper agent
			if [ $? -eq 2 ];then
				start_agent
			fi
		fi
	fi
}

# Start the ssh-agent
function start_agent {
	echo "Initializing new SSH agent..."
	# Spawn ssh-agent
	ssh-agent | sed 's/^echo/#echo/' > "$SSH_ENV"
	echo succeeded
	chmod 600 "$SSH_ENV"
	. "$SSH_ENV" > /dev/null
	add_personal_keys
}

function reset_ssh_auth {
	if [ -f "$SSH_ENV" ]; then
	. "$SSH_ENV" > /dev/null
	fi
	ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
	if [ $? -eq 0 ]; then
		add_personal_keys
	else
		start_agent
	fi
}

# Check for running ssh-agent with proper $SSH_AGENT_PID
if [ -n "$SSH_AGENT_PID" ]; then
	ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
	if [ $? -eq 0 ]; then
		add_personal_keys
	fi
else
	# If $SSH_AGENT_PID is not properly set, we might be able to load one from
	# $SSH_ENV
	if [ -f "$SSH_ENV" ]; then
		. "$SSH_ENV" > /dev/null
	fi
	ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
	if [ $? -eq 0 ]; then
		add_personal_keys
	else
		start_agent
	fi
fi

source $HOME/ndn/etc/ndnperl.rc
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
