#!/usr/bin/env zsh


export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/ripgrep/ripgreprc"

env_dirs=(
  "$ENV_DIRS"
  "$(dirname "$RIPGREP_CONFIG_PATH")"
)

export ENV_DIRS="${(j/:/)env_dirs}"
unset env_dirs

(( $+commands[rg] )) || return 1

if [[ ! -f "$ZSH_CACHE_DIR/completions/_rg" ]]; then
  typeset -g -A _comps
  autoload -Uz _rg
  _comps[rg]=_rg
fi

rg --generate complete-zsh >| "$ZSH_CACHE_DIR/completions/_rg" &|

# -------------------------------------------------------------------------------------------------
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
