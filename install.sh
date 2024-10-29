#!/bin/bash

# Enable error handling, but allow the script to continue on errors for stow
set -euo pipefail

# Define variables
LOCAL_DIR="$HOME/.local"
LOCAL_BIN="$HOME/.local/bin"

DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_REPO="https://github.com/Randallsm83/dotfiles.git"

# Available with git
VIM_URL="https://github.com/vim/vim.git"
NEOVIM_URL="https://github.com/neovim/neovim.git"
STOW_URL="https://git.savannah.gnu.org/git/stow.git"

# Available with wget
TAR_URL="https://ftp.gnu.org/gnu/tar/tar-latest.tar.gz"
WGET_URL="https://ftp.gnu.org/gnu/wget/wget-latest.tar.gz"
NCURSES_URL="https://invisible-island.net/datafiles/current/ncurses.tar.gz"

# Available with wget but need to determine latest version ourselves
LUA_URL="https://www.lua.org/download.html"

DEPENDENCIES=("wget" "git" "tar" "make" "gcc" "pkg-config")

# Let's add these now in case things exist here but we just dont have our dotfiles with the correct paths yet
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/opt/grep/libexec/gnubin:$HOME/.local/bin:$HOME/.local:$HOME/bin:$HOME/projects/ndn/dh/bin:$HOME/perl5/bin:/usr/local/bin:/usr/local/sbin:$PATH"
export LDFLAGS="-L$HOME/.local/lib $LDFLAGS"
export CPPFLAGS="-I$HOME/.local/include $CPPFLAGS"
export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"

# Function to get the latest GNU Stow version number
get_latest_stow_version() {
  wget -qO- "$STOW_URL/" | grep -Eo 'stow-[0-9]+\.[0-9]+(\.[0-9]+)?' | sed 's/stow-//' | sort -V | tail -1
}

# Function to check and switch to zsh if it's not the current shell
check_zsh() {
  if [[ "$SHELL" != *zsh* ]]; then
    echo "Switching to zsh..."
    chsh -s "$(command -v zsh)"
    echo "Please restart the terminal or log back in for zsh to take effect."
    exit 0
  else
    echo "Already using zsh."
  fi
}

# Function to check dependencies
check_dependencies() {
  echo "Checking dependencies..."
  for dep in "${DEPENDENCIES[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      echo "Error: $dep is not installed. Please install it first."
      exit 1
    fi
  done
  echo "All dependencies are installed."
}

# Function to install Homebrew on macOS or run brew update/upgrade if it exists
install_or_update_homebrew() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
      echo "Homebrew not found. Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      echo "Updating and upgrading Homebrew..."
      brew update && brew upgrade
    fi
  fi
}

# Function to install or upgrade package from brew
handle_brew_package() {
  local package=$1
  if brew list "$package" &>/dev/null; then
    echo "$package is already installed. Checking for upgrades..."
    if brew outdated "$package" &>/dev/null; then
      echo "A newer version of $package is available. Upgrading..."
      brew upgrade "$package"
    else
      echo "$package is up-to-date."
    fi
  else
    echo "Installing $package..."
    brew install "$package"
  fi
}

# Function to install GNU Stow locally
install_stow() {
  #TODO upgrade if exists in brew, check if exists and up to date from source
  echo "Installing GNU Stow locally..."

  cd "$LOCAL_DIR"
  git clone "$STOW_URL"
  cd stow || exit

  # Install Stow locally in ~/.local
  ./configure --prefix="$LOCAL_DIR"
  make -j"$(nproc)"
  make install

  # Clean up
  cd ..
  rm -rf "stow-$STOW_VERSION" "$STOW_TAR"

  echo "GNU Stow installed locally at $LOCAL_BIN"
}

# Function to check if GNU Stow is installed
check_stow_installation() {
  #TODO install with brew if mac like coreutils
  if ! command -v stow &>/dev/null; then
    echo "GNU Stow is not installed. Installing now..."
    install_stow
  else
    echo "GNU Stow is already installed."
  fi
}

# Function to clone dotfiles repository
clone_dotfiles() {
  echo "Cloning dotfiles repository..."
  if [ -d "$DOTFILES_DIR" ]; then
    echo "Dotfiles directory already exists."
    cd "$DOTFILES_DIR" || exit

    # Check for local changes
    if [ -n "$(git status --porcelain)" ]; then
      echo "Local changes detected in dotfiles repository."

      # Prompt user to stash or reset
      read -r -p "Would you like to (s)tash, (r)eset, or (a)bort? [s/r/a]: " choice
      case $choice in
      s | S)
        echo "Stashing local changes..."
        git stash --include-untracked
        ;;
      r | R)
        echo "Resetting local changes..."
        git reset --hard
        git clean -fd
        ;;
      a | A)
        echo "Aborting..."
        exit 1
        ;;
      *)
        echo "Invalid choice. Aborting..."
        exit 1
        ;;
      esac
    fi

    # Pull latest changes from the main branch
    echo "Pulling latest changes from repository..."
    git pull --rebase origin main
  else
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  echo "Dotfiles cloned to $DOTFILES_DIR"
}

# Function to back up conflicting files during stow operation
backup_conflicting_files() {
  local conflicting_dir="$1"
  local backup_dir="$HOME/dotfiles_backup/$conflicting_dir"
  mkdir -p "$backup_dir"
  echo "Backing up existing dotfiles from $HOME to $backup_dir"

  # Check for conflicts in the home directory and back them up
  for file in "$DOTFILES_DIR/$conflicting_dir"/*; do
    filename="$(basename "$file")"
    home_file="$HOME/$filename"

    # If the file exists in home and is not a symlink, back it up
    if [ -e "$home_file" ] && [ ! -L "$home_file" ]; then
      echo "Backing up $home_file to $backup_dir"
      mv "$home_file" "$backup_dir"
    fi
  done
  echo "Backup completed for $conflicting_dir."
}

# Function to create symlinks using stow, based on hostname
stow_dotfiles() {
  echo "Creating symlinks with GNU Stow..."

  # Get the current hostname
  FULL_HOSTNAME=$(hostname -f)

  # Add ~/.local/bin to PATH if it's not already there
  if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    export PATH="$LOCAL_BIN:$PATH"
  fi

  cd "$DOTFILES_DIR" || exit

  # Base list of directories to stow
  STOW_DIRS=("bin" "git" "iterm2" "vim" "zsh") # General directories

  # Add specific directories if hostname contains "dreamhost"
  if [[ "$FULL_HOSTNAME" == *"dreamhost"* ]]; then
    STOW_DIRS+=("ndnhost")
  else
    STOW_DIRS+=("localhost")
  fi

  # Use stow to create symlinks for each selected directory
  for dir in "${STOW_DIRS[@]}"; do
    stow_exit_code=0

    # Special case for the 'bin' directory to stow to ~/.local/bin
    if [[ "$dir" == "bin" ]]; then
      echo "Stowing $dir to ~/.local/bin"
      stow_output=$(stow --override=~ -n -v -t ~/.local/bin "$dir" 2>&1) || stow_exit_code=$?
    else
      echo "Stowing $dir"
      stow_output=$(stow --override=~ -n -v -t ~ "$dir" 2>&1) || stow_exit_code=$?
    fi

    # Handle conflicts
    if [[ $stow_output == *"conflicts"* || $stow_exit_code -ne 0 ]]; then
      echo "Conflicts detected for $dir:"
      echo "$stow_output"

      # Print options for resolving conflicts
      echo "Options:"
      echo "  (s)kip: Do not stow $dir."
      echo "  (b)ackup: Move conflicting files in $HOME to $HOME/dotfiles_backup/$dir and then stow $dir."
      echo "  (a)dopt: Make stow take control of existing conflicting files."
      echo "  (o)verwrite: Forcefully replace conflicting files with symlinks from $dir."
      read -r -p "Choose an option: [s/b/a/o]: " choice

      case $choice in
      s | S)
        echo "Skipping $dir..."
        ;;
      b | B)
        echo "Backing up conflicting files for $dir..."
        backup_conflicting_files "$dir"
        if [[ "$dir" == "bin/" ]]; then
          stow --override=~ -v -t ~/.local/bin "$dir"
        else
          stow --override=~ -v -t ~ "$dir"
        fi
        ;;
      a | A)
        echo "Adopting existing files for $dir..."
        if [[ "$dir" == "bin/" ]]; then
          stow --override=~ --adopt -v -t ~/.local/bin "$dir"
        else
          stow --override=~ --adopt -v -t ~ "$dir"
        fi
        ;;
      o | O)
        echo "Overwriting existing files for $dir..."
        if [[ "$dir" == "bin/" ]]; then
          stow --override=~ --force -v -t ~/.local/bin "$dir"
        else
          stow --override=~ --force -v -t ~ "$dir"
        fi
        ;;
      *)
        echo "Invalid choice. Skipping $dir..."
        ;;
      esac
    else
      if [[ "$dir" == "bin" ]]; then
        stow --override=~ -v -t ~/.local/bin "$dir"
      else
        stow --override=~ -v -t ~ "$dir"
      fi
    fi
  done

  echo "Symlinks created successfully."
}

# Function to restore stashed changes
restore_stashed_changes() {
  cd "$DOTFILES_DIR" || exit
  if git stash list | grep -q 'stash@{0}'; then
    echo "Restoring stashed changes..."
    git stash pop
  else
    echo "No stashed changes to restore."
  fi
}

# Function to update and install zplug plugins
update_zplug() {
  if command -v zplug &>/dev/null; then
    echo "Updating and installing zplug plugins..."
    zplug update && zplug install
  else
    echo "zplug is not installed or not in PATH."
  fi
}

# Create local directories before anything
mkdir -p "$LOCAL_BIN"

# Check if zsh is the default shell and activate it if necessary
check_zsh

# Check and install dependencies
check_dependencies

# Install or update Homebrew on macOS
install_or_update_homebrew

# Install Vim from source or via Homebrew
install_vim

# Install the latest version of GNU Coreutils if needed
check_coreutils_installation

# Check if GNU Stow is installed and install it if not
check_stow_installation

# Clone dotfiles repository and handle any local changes
clone_dotfiles

# Create symlinks using GNU Stow and handle conflicts dynamically
stow_dotfiles

# Restore stashed changes, if any
restore_stashed_changes

# Update and install zplug plugins
update_zplug

# Install Vim plugins using vim-plug
install_vim_plugins

echo "Dotfiles setup completed!"

# Reload the terminal to apply all changes
exec zsh
