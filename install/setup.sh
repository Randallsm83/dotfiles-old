#!/usr/bin/env bash

source_env() {
  [[ -r "$HOME/.dotfiles/env/dot-config/env.d/dirs.sh" ]] && source "$HOME/.dotfiles/env/dot-config/env.d/dirs.sh"
  [[ -r "$DOTFILES/env/dot-config/env.d/paths.sh" ]] && source "$DOTFILES/env/dot-config/env.d/paths.sh"
  [[ -r "$DOTFILES/env/dot-config/env.d/homebrew.sh" ]] && source "$DOTFILES/env/dot-config/env.d/homebrew.sh"
}

install_homebrew() {
  git clone https://github.com/Homebrew/brew "$HOMEBREW_PREFIX"
  brew update --force --quiet
  chmod -R go-w "$(brew --prefix)/share/zsh"
}

# Clone your dotfiles repository
git clone https://github.com/Randallsm83/dotfiles.git "$HOME/.dotfiles"

source_env
echo "ENV files sourced."

install_homebrew
echo "Homebrew installed."

# brew install stow
# echo "Stow installed."

echo "Temporary environment setup complete. Dotfiles repo has been cloned."
echo "Now go install stow and stow the packages!"

# -------------------------------------------------------------------------------------------------
# -*- mode: bash; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=bash sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
