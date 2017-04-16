##############
#  My Zshrc  #
#   v. 1.0   #
##############

###############
#  Oh My Zsh  #
###############

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Theme
ZSH_THEME="dracula"

# Auto correction
ENABLE_CORRECTION="true"

# Show waiting for completion dots
COMPLETION_WAITING_DOTS="true"

# Make repo status checking faster
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Plugins
plugins=(git)
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

	# local::lib
	# eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

	# virtualenvwrapper
	export WORKON_HOME=$HOME/.virtualenvs
	source /usr/local/bin/virtualenvwrapper.sh

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
