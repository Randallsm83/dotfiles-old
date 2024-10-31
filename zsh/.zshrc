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
[[ -f ~/.config/zsh/zsh-syntax-theme ]] && source ~/.config/zsh/zsh-syntax-theme

# ---- Language Plugins ----
zplug "lukechilds/zsh-nvm"
zplug "mattberther/zsh-pyenv"
zplug "DhavalKapil/luaver"

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
zplug "zsh-users/zsh-syntax-highlighting", defer:3
zplug "zsh-users/zsh-history-substring-search", defer:2

# ---- Supercrab Tree ---------
zplug "supercrabtree/k"

# ---- Powerlevel10k Theme ----
zplug "romkatv/powerlevel10k", as:theme, depth:1

# ---- FZF Setup ----
zplug "junegunn/fzf", use:"shell/*.zsh", hook-build:"./install --all"

# ---- Diff So Fancy ----
zplug "so-fancy/diff-so-fancy", as:command, use:"diff-so-fancy"

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
setopt appendhistory      # Append to history file, do not overwrite
setopt INC_APPEND_HISTORY # Write to history file immediately
setopt SHARE_HISTORY      # Share history across all sessions
setopt HIST_IGNORE_SPACE  # Ignore commands with leading spaces
setopt HIST_REDUCE_BLANKS # Remove unnecessary blanks
setopt HIST_IGNORE_DUPS   # Ignore duplicate commands
setopt HIST_FIND_NO_DUPS  # Do not display old duplicates in history search
setopt HIST_SAVE_NO_DUPS  # Do not save duplicate commands in history
setopt HIST_VERIFY        # Don't execute immediately upon history expansion
setopt EXTENDED_HISTORY   # Record command execution time
HISTSIZE=500000           # Number of lines kept in memory
SAVEHIST=500000           # Number of lines to save in history file
HISTFILE=~/.config/zsh/zsh_history   # Where to save the command history

# Environment variables
export EDITOR='nvim'
export VISUAL='nvim'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Path and flag modifications
LOCALDIR="$HOME/.local"
BREWDIR="/opt/homebrew/opt"

export PATH="$LOCALDIR/bin:$HOME/bin:$HOME/projects/ndn/dh/bin:$HOME/perl5/bin:$HOME/.cargo/bin:/usr/local/bin:/usr/local/sbin:$PATH"
export PATH="$BREWDIR/findutils/libexec/gnubin:$PATH"
export PATH="$BREWDIR/make/libexec/gnubin:$PATH"
export PATH="$BREWDIR/coreutils/libexec/gnubin:$PATH"
export PATH="$BREWDIR/gnu-sed/libexec/gnubin:$PATH"
export PATH="$BREWDIR/grep/libexec/gnubin:$PATH"
export PATH="$BREWDIR/gnu-tar/libexec/gnubin:$PATH"
export PATH="$BREWDIR/ncurses/bin:$PATH"

export LD_LIBRARY_PATH="$LOCALDIR/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$BREWDIR/ncurses/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$BREWDIR/readline/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$LOCALDIR/lib/pkgconfig:$LOCALDIR/share/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="$BREWDIR/ncurses/lib/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="$BREWDIR/readline/lib/pkgconfig:$PKG_CONFIG_PATH"

# ========================= Key Bindings ======================================
# History substring search bindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ========================= Visual Settings ===================================
eval "$(dircolors --sh ~/.config/zsh/gruvbox.default.dircolors)"
IFS=: read -rA ls_colors_array <<< "$LS_COLORS"
zstyle ':completion:*' list-colors "${ls_colors_array[@]}"

# ========================= Source Configurations =============================
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
[[ -f ~/.config/wezterm/wezterm.sh ]] && source ~/.config/wezterm/wezterm.sh
# [[ -f ~/.config/iterm2/iterm2_shell_integration.zsh ]] && source ~/.config/iterm2/iterm2_shell_integration.zsh
