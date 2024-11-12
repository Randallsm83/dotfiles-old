#!/usr/bin/env bash

# Define custom installation paths
HOMEBREW_PREFIX="$HOME/.local/share/homebrew"
PERLBREW_ROOT="$HOME/.local/share/perlbrew"
DOTFILES_DIR="$HOME/.dotfiles"
PATH="$HOMEBREW_PREFIX/bin:$PERLBREW_ROOT/bin:$PATH"

# Step 1: Clone dotfiles repository
echo "Cloning dotfiles repository..."
git clone https://github.com/Randallsm83/dotfiles.git "$DOTFILES_DIR"

# Step 2: Install Homebrew from source
echo "Installing Homebrew locally..."
git clone https://github.com/Homebrew/brew "$HOMEBREW_PREFIX"

# Set up Homebrew environment variables
eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"

# Step 3: Install Perlbrew locally to .local/perlbrew
echo "Installing Perlbrew locally to $PERLBREW_ROOT..."
curl -L https://install.perlbrew.pl | bash

# Ensure Perlbrew environment variables are set
source "$PERLBREW_ROOT/etc/bashrc"

# Step 4: Install the latest Perl with Perlbrew
echo "Installing the latest Perl with Perlbrew..."
perlbrew install-cpanm
perlbrew install perl --notest # installs the latest stable Perl without testing
perlbrew switch perl           # switch to the latest installed Perl

# Step 5: Set up `local::lib` using Perlbrew’s built-in support
echo "Configuring local::lib with Perlbrew..."
perlbrew lib create perl@local # creates a lib named "local"
perlbrew switch perl@local

# Step 6: Install required Perl modules (Test::More and Test::Output)
echo "Installing Test::More and Test::Output..."
cpanm Test::More Test::Output

# Step 7: Use Homebrew to install GNU Stow
echo "Installing GNU Stow with Homebrew..."
brew install stow

# Step 8: Stow dotfiles
echo "Stowing dotfiles..."
cd "$DOTFILES_DIR" || exit
for dir_to_stow in ./*; do
  if [ -d "$dir_to_stow" ]; then
    stow --no-folding --dotfiles --verbose=2 -R -t ~ "$dir_to_stow"
  fi
done

echo "Setup complete. Homebrew, Perlbrew, Perl, cpanm, GNU Stow, and dotfiles are installed and configured."

# Reminder: To keep Homebrew and Perlbrew commands available, add the following to your shell profile:
echo "export PATH=\"$HOMEBREW_PREFIX/bin:$PERLBREW_ROOT/bin:$PATH\"" >>"$HOME/.bashrc"
echo "source \"$PERLBREW_ROOT/etc/bashrc\"" >>"$HOME/.bashrc"

# -------------------------------------------------------------------------------------------------
# -*- mode: bash; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=bash sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
