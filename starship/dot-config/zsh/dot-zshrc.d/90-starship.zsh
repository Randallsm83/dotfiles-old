#!/usr/bin/env zsh

(( $+commands[starship] )) || return 1

export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml"
export STARSHIP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/starship"

eval "$(starship init zsh)"

# -------------------------------------------------------------------------------------------------
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
