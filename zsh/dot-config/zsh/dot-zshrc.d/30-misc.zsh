#!/usr/bin/env zsh

if [[ -n "$OSTYPE" && "${(L)OSTYPE}" == *darwin* ]]; then
  export MACOSX_DEPLOYMENT_TARGET=$(sw_vers -productVersion)
fi

export DOCKER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/docker"

export GNUPGHOME="${XDG_DATA_HOME:-$HOME/.local/share}/gnupg"

export LESSHISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/less/history"

export MYSQL_HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/mysql/history"

export TLDR_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tldr"

env_dirs=(
  "$ENV_DIRS"
  "$DOCKER_CONFIG"
  "$TLDR_CACHE_DIR"
  "$GNUPGHOME"
  "$(dirname "$LESSHISTFILE")"
  "$(dirname "$MYSQL_HISTFILE")"
)

export ENV_DIRS="${(j/:/)env_dirs}"
unset env_dirs

# -------------------------------------------------------------------------------------------------
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
