#!/bin/bash

export CACHEDIR="$HOME/.cache"
export CONFIGDIR="$HOME/.config"
export LOCALDIR="$HOME/.local"
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

export DOTFILES="$HOME/.dotfiles"

export HOMEBREW_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/Homebrew"
export HOMEBREW_BUNDLE_USER_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/Homebrew"
export HOMEBREW_LOGS="${XDG_CACHE_HOME:-$HOME/.cache}/Homebrew/Logs"
export HOMEBREW_TEMP="${XDG_RUNTIME_DIR:-/tmp}/Homebrew"

cores="$(sysctl -n hw.ncpu)"
export HOMEBREW_MAKE_JOBS="$cores"
export HOMEBREW_DISPLAY_INSTALL_TIMES=1
export HOMEBREW_COLOR=1

export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CURL_RETRIES=3

export HOMEBREW_NO_ANALYTICS=1

install_homebrew() {
  if [[ "$(uname)" == "Darwin" ]]; then

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"

  elif [[ "$(uname)" == "Linux" ]]; then

    git clone https://github.com/Homebrew/brew "$HOME/homebrew"
    eval "$("$HOME/homebrew/bin/brew" shellenv)"

    brew update --force --quiet
    chmod -R go-w "$(brew --prefix)/share/zsh"

  else
    echo "Unsupported operating system. Exiting."
    exit 1
  fi
}

install_homebrew
echo "Homebrew installed."

# brew install stow
# echo "Stow installed."

# Clone your dotfiles repository
git clone https://github.com/Randallsm83/dotfiles.git "$DOTFILES"

echo "Temporary environment setup complete. Dotfiles repo has been cloned."
echo "Now go install stow and stow the packages!"

# -------------------------------------------------------------------------------------------------
# -*- mode: bash; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=bash sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
