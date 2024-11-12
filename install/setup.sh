#!/usr/bin/env bash

source_env() {
  if [[ $(uname) == 'Darwin' ]]; then
    cores="$(sysctl -n hw.logicalcpu)"
  elif [[ $(uname) == 'Linux' ]]; then
    cores="$(nproc)"
  fi
  export MACHINE_CORES=$cores

  for env_file in "$HOME/.dotfiles/env/dot-config/env.d"/*.conf; do
    echo "$env_file"
    [ -r "$env_file" ] && source "$env_file"
  done
  # [[ -r "$HOME/.dotfiles/homebrew/dot-config/env.d/50-homebrew.conf" ]] && source "$HOME/.dotfiles/homebrew/dot-config/env.d/50-homebrew.conf"
  # [[ -r "$HOME/.dotfiles/env/dot-config/env.d/10-dirs.conf" ]] && source "$HOME/.dotfiles/env/dot-config/env.d/10-dirs.conf"
  # [[ -r "$DOTFILES/env/dot-config/env.d/paths.sh" ]] && source "$DOTFILES/env/dot-config/env.d/paths.sh"
  # [[ -r "$DOTFILES/env/dot-config/env.d/homebrew.sh" ]] && source "$DOTFILES/env/dot-config/env.d/homebrew.sh"
}

install_homebrew() {
  git clone https://github.com/Homebrew/brew "$HOMEBREW_PREFIX"
  brew update --force --quiet
  chmod -R go-w "$(brew --prefix)/share/zsh"
}

install_stow() {
  # Define the custom installation prefix (update this path as needed)
  PREFIX_DIR="$HOME/.local"

  # Create the installation directory if it doesn't exist
  mkdir -p "$PREFIX_DIR"

  # Clone the latest GNU Stow source code from the Git repository
  echo "Cloning GNU Stow repository..."
  git clone https://git.savannah.gnu.org/git/stow.git

  # Move into the stow directory
  cd stow || exit 1

  # Bootstrap, configure, compile, and install Stow to the custom prefix
  echo "Bootstrapping and configuring Stow with custom prefix..."
  ./configure --prefix="$PREFIX_DIR"

  echo "Building Stow..."
  make

  echo "Installing Stow to $PREFIX_DIR..."
  make install

  # Clean up the cloned repository
  cd ..
  rm -rf stow

  echo "GNU Stow installed to $PREFIX_DIR/bin. Add this directory to your PATH if needed."
}

# Clone your dotfiles repository
git clone https://github.com/Randallsm83/dotfiles.git "$HOME/.dotfiles"

install_stow
echo "Stow installed."

#source_env
#echo "ENV files sourced."

#install_homebrew
#echo "Homebrew installed."

echo "Temporary environment setup complete. Dotfiles repo has been cloned."
echo "Now go install stow and stow the packages!"

# -------------------------------------------------------------------------------------------------
# -*- mode: bash; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=bash sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
