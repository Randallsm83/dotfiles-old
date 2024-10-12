# ======================= Powerlevel10k ==============================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ========================= Zplug Setup =================================
# Check if zplug is installed
if [[ ! -d ~/.zplug ]]; then
  git clone https://github.com/zplug/zplug ~/.zplug
  source ~/.zplug/init.zsh && zplug update --self
fi

# Zplug initialization
source ~/.zplug/init.zsh

# Install zplug itself if needed
zplug 'zplug/zplug', hook-build:'zplug --self-manage'

# ------------------------- Plugin Configuration -------------------------

# ---- Before Plugins -------
[[ -f ~/.zsh-syntax-theme ]] && source ~/.zsh-syntax-theme

# ---- Language Plugins ----
zplug "mattberther/zsh-pyenv"

# ---- Oh-My-Zsh Plugins ----
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/npm", from:oh-my-zsh
zplug "plugins/nvm", from:oh-my-zsh
zplug "plugins/sudo", from:oh-my-zsh
zplug "plugins/ssh-agent", from:oh-my-zsh
zplug "plugins/common-aliases", from:oh-my-zsh

# ---- Zsh Users Plugins ----
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-history-substring-search", defer:2

# ---- Supercrab Tree ---------
zplug "supercrabtree/k"

# ---- Powerlevel10k Theme ----
zplug "romkatv/powerlevel10k", as:theme, depth:1

# ---- FZF Setup ----
zplug "junegunn/fzf", use:"shell/*.zsh", hook-build:"./install --all"

# ---- My Stuff ----
 # zplug "$HOME/.aliases", from:local, use:".aliases"
 # zplug "local/.aliases.ndn", from:local, use:.aliases.ndn

# Check if plugins are installed, install if not
if ! zplug check --verbose; then
  echo; zplug install
fi

# ------------------------- Zplug Load -------------------------------
zplug load

# ========================= General Settings =========================
# History settings
HISTFILE=~/.zsh_history              # Where to save the command history
HISTSIZE=500000                      # Number of lines kept in memory
SAVEHIST=500000                      # Number of lines to save in history file
setopt appendhistory                 # Append to history file, do not overwrite
setopt INC_APPEND_HISTORY            # Write to history file immediately
setopt SHARE_HISTORY                 # Share history across all sessions
setopt HIST_IGNORE_SPACE             # Ignore commands with leading spaces
setopt HIST_REDUCE_BLANKS            # Remove unnecessary blanks
setopt HIST_IGNORE_DUPS              # Ignore duplicate commands
setopt HIST_FIND_NO_DUPS             # Do not display old duplicates in history search
setopt HIST_SAVE_NO_DUPS             # Do not save duplicate commands in history
setopt HIST_VERIFY                   # Don't execute immediately upon history expansion
setopt EXTENDED_HISTORY              # Record command execution time

# Environment variables
export EDITOR='vim'
export VISUAL='vim'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Path modifications
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:/Users/randallm/.rd/bin:$HOME/bin:$HOME/local/bin:$HOME/local:$HOME/projects/ndn/dh/bin:$HOME/perl5/bin:/usr/local/bin:/usr/local/sbin:$PATH"

# TODO
# Oh-My-Zsh settings
# export HYPHEN_INSENSITIVE="true"
# export ENABLE_CORRECTION="true"
# export COMPLETION_WAITING_DOTS="true"

# ========================= Key Bindings ==========================
# History substring search bindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ========================= Source Configurations ==================
# to customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# TODO
# .aliases
[[ -f ~/.aliases ]] && source ~/.aliases
[[ -f ~/.aliases.ndn ]] && source ~/.aliases.ndn

# Fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Perlbrew
[ -f ~/perl5/perlbrew/etc/bashrc ] && source ~/perl5/perlbrew/etc/bashrc

# Shell Integration
[[ -f ~/.iterm2_shell_integration.zsh ]] && source ~/.iterm2_shell_integration.zsh
