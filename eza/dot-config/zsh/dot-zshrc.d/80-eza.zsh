#!/usr/bin/env zsh

export EZA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/eza"

[[ $TERM == 'dumb' ]] && return 1

if (( $+commands[eza] )); then
  typeset -ag eza_params

  eza_params=(
    '--git' '--icons' '--group' '--group-directories-first'
    '--time-style=long-iso' '--color-scale=all'
  )

  [[ ! -z $_EZA_PARAMS ]] && eza_params=($_EZA_PARAMS)

  alias ls='eza $eza_params'
  alias l='eza --git-ignore $eza_params'
  alias ll='eza --all --header --long $eza_params'
  alias llm='eza --all --header --long --sort=modified $eza_params'
  alias la='eza -lbhHigUmuSa'
  alias lx='eza -lbhHigUmuSa@'
  alias lt='eza --tree $eza_params'
  alias tree='eza --tree $eza_params'

else
  print "Please install eza before using this plugin." >&2
  return 1
fi

return 0

# -------------------------------------------------------------------------------------------------
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
