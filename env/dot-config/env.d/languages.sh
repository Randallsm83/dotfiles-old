#!/usr/bin/env bash

# PLENV
export PLENV_ROOT="$HOME/.plenv"
export PATH="$PLENV_ROOT/bin:$PATH"
if command -v plenv &>/dev/null; then
  eval "$(plenv init -)"
fi

# PYENV
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv &>/dev/null; then
  eval "$(pyenv init --path)"
fi

# RBENV
export RBENV_ROOT="$HOME/.rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
if command -v rbenv &>/dev/null; then
  eval "$(rbenv init -)"
fi

# NVM
export NVM_DIR="$HOME/.nvm"
export NVM_COMPLETION=true
export NVM_LAZY_LOAD=true

# LUAVER
export LUAVER_HOME="$HOME/.luaver"
export PATH="$LUAVER_HOME/bin:$PATH"

# GO
export GOPATH="$HOME/.local/go"
export PATH="$GOPATH/bin:$PATH"

# -------------------------------------------------------------------------------------------------
# -*- mode: bash; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=bash sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
