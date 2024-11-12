#!/usr/bin/env bash

export CACHEDIR="$HOME/.cache"
export CONFIGDIR="$HOME/.config"
export LOCALDIR="$HOME/.local"
export ENVDIR="$CONFIGDIR/env.d"
export DATADIR="$LOCALDIR/share"
export STATEDIR="$LOCALDIR/state"
export TMPDIR="${TMPDIR:-/tmp}"
export BIN_DIR="$LOCALDIR/bin"
export BINDIR=$BIN_DIR

export XDG_CACHE_HOME="$CACHEDIR"
export XDG_CONFIG_HOME="$CONFIGDIR"
export XDG_BIN_HOME="$BINDIR"
export XDG_DATA_HOME="$DATADIR"
export XDG_STATE_HOME="$STATEDIR"
export XDG_RUNTIME_DIR="$TMPDIR"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"

export DOTFILES="$HOME/.dotfiles"
export DHSPACE="$HOME/projects/"
export MYSPACE="$HOME/Dev"

export SESSION_LOG="$XDG_CACHE_HOME/session.log"

# -------------------------------------------------------------------------------------------------
# -*- mode: bash; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=bash sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
