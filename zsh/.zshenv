#!/bin/zsh

export TERM='xterm-256color'
export EDITOR='nvim'
export VISUAL='nvim'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export DOTFILES="$HOME/.dotfiles"
export LOCALDIR="$HOME/.local"

export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_BIN_HOME="$$LOCALDIR/bin"
export XDG_DATA_HOME="$LOCALDIR/share"
export XDG_STATE_HOME="$LOCALDIR/state"
export XDG_RUNTIME_DIR="${TMPDIR:-/tmp}"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export HISTFILE="$ZDOTDIR/zsh_history"
export HISTSIZE=500000
export SAVEHIST=500000

# Mac is dumb and sources /etc/zprofile after this file so you cannot set paths reliably here. Do it in .zprofile
# instead...


# -------------------------------------------------------------------------------------------------
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
