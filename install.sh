#!/bin/bash

# Enable error handling, but allow the script to continue on errors for stow
set -euo pipefail

# Set to 1 for debugging
DEBUG=1

# Define a function for conditional debug printing
function debug_print() {
    if [ "$DEBUG" -eq 1 ]; then
        echo "$1"
    fi
}

# Define local and brew directories
export LOCALDIR="$HOME/.local"
LOCALBIN="$LOCALDIR/bin"
TEMPDIR="$LOCALDIR/src_temp"
BREWDIR="/opt/homebrew/opt"

# Update PATH to prioritize local and Homebrew binaries
export PATH="$LOCALDIR/bin:$HOME/bin:$HOME/projects/ndn/dh/bin:$HOME/perl5/bin:$HOME/.cargo/bin:/usr/local/bin:/usr/local/sbin:$PATH"
export PATH="$BREWDIR/findutils/libexec/gnubin:$PATH"
export PATH="$BREWDIR/make/libexec/gnubin:$PATH"
export PATH="$BREWDIR/coreutils/libexec/gnubin:$PATH"
export PATH="$BREWDIR/gnu-sed/libexec/gnubin:$PATH"
export PATH="$BREWDIR/grep/libexec/gnubin:$PATH"
export PATH="$BREWDIR/gnu-tar/libexec/gnubin:$PATH"
export PATH="$BREWDIR/ncurses/bin:$PATH"

# Update LD_LIBRARY_PATH for shared libraries
export LD_LIBRARY_PATH="$LOCALDIR/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$BREWDIR/ncurses/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$BREWDIR/readline/lib:$LD_LIBRARY_PATH"

# Update PKG_CONFIG_PATH for pkg-config files
export PKG_CONFIG_PATH="$LOCALDIR/lib/pkgconfig:$LOCALDIR/share/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="$BREWDIR/ncurses/lib/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="$BREWDIR/readline/lib/pkgconfig:$PKG_CONFIG_PATH"

# DOTFILES_DIR="$HOME/dotfiles"
# DOTFILES_REPO="https://github.com/Randallsm83/dotfiles.git"
#
# # Available with git
# VIM_URL="https://github.com/vim/vim.git"
# NEOVIM_URL="https://github.com/neovim/neovim.git"
# STOW_URL="https://git.savannah.gnu.org/git/stow.git"
#
# # Available with wget
# TAR_URL="https://ftp.gnu.org/gnu/tar/tar-latest.tar.gz"
# WGET_URL="https://ftp.gnu.org/gnu/wget/wget-latest.tar.gz"
# NCURSES_URL="https://invisible-island.net/datafiles/current/ncurses.tar.gz"
#
# # Available with wget but need to determine latest version ourselves
# LUA_URL="https://www.lua.org/download.html"

# Function to get the latest GNU Stow version number
# get_latest_stow_version() {
  # wget -qO- "$STOW_URL/" | grep -Eo 'stow-[0-9]+\.[0-9]+(\.[0-9]+)?' | sed 's/stow-//' | sort -V | tail -1
# }


# Function to check if a package is already installed in .local
# Function to check if a package is already installed in .local
function is_installed() {
    local name=$1
    local binary_path="$LOCALDIR/bin/"
    local lib_files=("$LOCALDIR/lib/lib${name}.so" "$LOCALDIR/lib/lib${name}w.so")
    local header_file="$LOCALDIR/include/${name}.h"

    if [ "$name" == "coreutils" ]; then
      local coreutils_binaries=("ls" "cat" "mkdir" "cp" "mv" "rm")
      local found_count=0
      for binary in "${coreutils_binaries[@]}"; do
          if [ -x "$binary_path/$binary" ]; then
              found_count=$((found_count + 1))
          fi
      done

      # Check if we found enough binaries to consider coreutils installed
      if [ "$found_count" -ge 4 ]; then
          debug_print "$name is already installed (found $found_count core binaries)."
          return 0
      fi
    fi

    # Check if the binary exists in .local/bin
    if [ -x "$binary_path/$name" ]; then
        debug_print "$name is already installed (binary found at $binary_path)."
        return 0
    fi

    # Check for shared libraries in .local/lib
    for lib_file in "${lib_files[@]}"; do
        if [ -f "$lib_file" ]; then
            debug_print "$name is already installed (library found at $lib_file)."
            return 0
        fi
    done

    # Use pkg-config to detect the package if available
    # if command -v pkg-config >/dev/null && pkg-config --exists "$name"; then
        # debug_print "$name is already installed (detected by pkg-config)."
        # return 0
    # fi

    # Check for header files in .local/include
    if [ -f "$header_file" ]; then
        debug_print "$name is already installed (header found at $header_file)."
        return 0
    fi

    return 1  # Package not found
}

# Function to get the latest versioned URL for a GNU package
function get_latest_url() {
    local package_name=$1
    local base_url=$2

    # Fetch the directory listing and extract the latest version tar.gz link
    latest_url=$(curl -s "$base_url" | grep -oE "href=\"$package_name-[0-9]+\.[0-9]+(\.[0-9]+)?\.tar\.gz\"" | tail -1 | cut -d '"' -f 2)

    # Check if the URL was found
    if [ -n "$latest_url" ]; then
        echo "$base_url$latest_url"
    else
        echo "Error: Could not find latest version for $package_name" >&2
        return 1
    fi
}

# Function to check and switch to zsh if it's not the current shell
function check_zsh() {
  if [[ "$SHELL" != *zsh* ]]; then
    echo "Switching to zsh..."
    chsh -s "$(command -v zsh)"
    echo "Please restart the terminal or log back in for zsh to take effect."
    exit 0
  else
    echo "Already using zsh."
  fi
}

# Function to download, extract, configure, and install from source
function install_source_package() {
    local name=$1
    local url=$2
    local extra_configure_options=$3
    local preconfigure_command=$4

    # Check if the package is already installed
    # if is_installed "$name"; then
    #     echo "$name is already installed; skipping installation."
    #     return
    # fi

    echo "Starting installation for: $name"
    debug_print "URL: $url"
    debug_print "Extra configure options: $extra_configure_options"
    debug_print "Preconfigure command: $preconfigure_command"


    # Download
    if [[ "$url" == *\.git ]]; then
      debug_print "Downloading $name with git..."

      cd "$TEMPDIR" || exit
      rm -rf $name

      git clone "$url"

      dir_name=$name
    else
      tarball=$(basename "$url")
      cd "$TEMPDIR" || exit
      rm -f "$tarball"

      if command -v wget &> /dev/null; then
        debug_print "Downloading $tarball with wget..."
        wget -O "$tarball" "$url"
      else
        debug_print "Downloading $tarball with curl..."
        curl -O "$url"
      fi

      # Extract the tarball
      debug_print "Extracting $tarball..."
      tar -xf "$tarball"
      if [ $? -ne 0 ]; then
        echo "Error: Extraction failed for $tarball."
        exit 1
      fi

      # Find extracted directory
      dir_name=$(find "$TEMPDIR" -mindepth 1 -maxdepth 1 -type d -name "${name}-*" -print | head -n 1)
      debug_print "Extracted directory: $dir_name"
    fi

    if [ $? -ne 0 ]; then
        echo "Error downloading $name."
        exit 1
    fi


    # Check if the extracted directory exists
    if [ -d "$dir_name" ]; then
      debug_print "Entering directory $dir_name..."
      cd "$dir_name" || exit
    else
      echo "Error: Extracted directory $dir_name not found"
      ls -l "$TEMPDIR"  # List contents for debugging
      exit 1
    fi

    # Run a preconfigure command if provided (e.g., autogen.sh)
    if [ -n "$preconfigure_command" ]; then
      debug_print "Running preconfigure command: $preconfigure_command"
      $preconfigure_command
    fi

    debug_print "Configuring $name with prefix=$LOCALDIR and options: $extra_configure_options"
    # if [ "$name" == 'pkg-config' ]; then
    #   ./configure --prefix="$LOCALDIR" "$extra_configure_options"
    #   make
    #   make install
    if [ "$name" == 'glib' ]; then
      pyenv pip3 install --user meson
      meson setup _build --prefix="$LOCALDIR"                     # configure the build
      meson compile -C _build                 # build GLib
      meson install -C _build                 # install GLib
    elif [ "$name" == 'CMake' ]; then
      ./bootstrap --prefix="$LOCALDIR"
      make
      make install
    elif [ "$name" == 'neovim' ]; then
      cmake "$extra_configure_options"
      make install
    elif [ "$name" == 'xz' ]; then
      cmake  "$extra_configure_options"
      make install
    else
      ./configure --prefix="$LOCALDIR" "$extra_configure_options"
      make
      make install
    fi

    cd "$TEMPDIR" || exit
    echo "Finished installation for: $name"
}

# Function to execute a custom command
function install_command_package() {
    local command=$1
    echo "Executing custom installation command..."
    eval "$command"
}

# Function to download and install a cargo-based package
function install_cargo_package() {
    local package=$1
    echo "Installing $package via cargo..."
    cargo install "$package" --root "$LOCALDIR"
}

# Install the things
function install_from_conf() {
  while IFS='|' read -r name url version method extra_configure_options command || [ -n "$name" ]; do
      # Skip comment lines and empty lines
      [[ "$name" =~ ^#.*$ ]] && continue
      [[ -z "$name" ]] && continue

      # If the version is 'latest', dynamically retrieve the latest version URL
      if [[ "$version" == "latest" ]]; then
        debug_print "Getting latest url"
          url=$(get_latest_url "$name" "$url")
          if [ $? -ne 0 ]; then
              echo "Error: Failed to retrieve latest version for $name"
              return 1
          fi
      fi

      echo "Installing $name using method: $method"

      #TODO rustup requires env vars for location
      case "$method" in
          source)
              install_source_package "$name" "$url" "$extra_configure_options" "$command"
              ;;
          cargo)
              install_cargo_package "$name"
              ;;
          command)
              install_command_package "$command"
              ;;
          *)
              echo "Unknown installation method: $method"
              ;;
      esac
  done < packages.conf
}

# Create local directories before anything
mkdir -p "$LOCALDIR"

# Create temporary directory for downloads and builds
mkdir -p "$TEMPDIR"

# Create .config dir so we dont link the whole folder with stow
mkdir -p "$HOME/.config"

# Prep
check_zsh

# Install pacakages from conf file
install_from_conf

# Cleanup build temp dir
rm -rf "TEMPDIR"

# Final message
echo "Installation complete. Ensure the following paths are set:"
echo "export PATH=\"$LOCALDIR/bin:\$PATH\""
echo "export PKG_CONFIG_PATH=\"$PKG_CONFIG_PATH\""
echo "export LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH\""

# Reload the terminal to apply all changes
# exec zsh

# # Function to install Homebrew on macOS or run brew update/upgrade if it exists
# install_or_update_homebrew() {
  # if [[ "$(uname -s)" == "Darwin" ]]; then
    # if ! command -v brew &>/dev/null; then
      # echo "Homebrew not found. Installing Homebrew..."
      # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # else
      # echo "Updating and upgrading Homebrew..."
      # brew update && brew upgrade
    # fi
  # fi
# }
#
# # Function to install or upgrade package from brew
# handle_brew_package() {
  # local package=$1
  # if brew list "$package" &>/dev/null; then
    # echo "$package is already installed. Checking for upgrades..."
    # if brew outdated "$package" &>/dev/null; then
      # echo "A newer version of $package is available. Upgrading..."
      # brew upgrade "$package"
    # else
      # echo "$package is up-to-date."
    # fi
  # else
    # echo "Installing $package..."
    # brew install "$package"
  # fi
# }

# Function to install GNU Stow locally
# install_stow() {
  # #TODO upgrade if exists in brew, check if exists and up to date from source
  # echo "Installing GNU Stow locally..."
#
  # cd "$LOCALDIR"
  # git clone "$STOW_URL"
  # cd stow || exit
#
  # # Install Stow locally in ~/.local
  # ./configure --prefix="$LOCALDIR"
  # make -j"$(nproc)"
  # make install
#
  # # Clean up
  # cd ..
  # rm -rf "stow-$STOW_VERSION" "$STOW_TAR"
#
  # echo "GNU Stow installed locally at $LOCALBIN"
# }
#
# # Function to check if GNU Stow is installed
# check_stow_installation() {
  # #TODO install with brew if mac like coreutils
  # if ! command -v stow &>/dev/null; then
    # echo "GNU Stow is not installed. Installing now..."
    # install_stow
  # else
    # echo "GNU Stow is already installed."
  # fi
# }

# Function to clone dotfiles repository
# clone_dotfiles() {
  # echo "Cloning dotfiles repository..."
  # if [ -d "$DOTFILES_DIR" ]; then
    # echo "Dotfiles directory already exists."
    # cd "$DOTFILES_DIR" || exit
#
    # # Check for local changes
    # if [ -n "$(git status --porcelain)" ]; then
      # echo "Local changes detected in dotfiles repository."
#
      # # Prompt user to stash or reset
      # read -r -p "Would you like to (s)tash, (r)eset, or (a)bort? [s/r/a]: " choice
      # case $choice in
      # s | S)
        # echo "Stashing local changes..."
        # git stash --include-untracked
        # ;;
      # r | R)
        # echo "Resetting local changes..."
        # git reset --hard
        # git clean -fd
        # ;;
      # a | A)
        # echo "Aborting..."
        # exit 1
        # ;;
      # *)
        # echo "Invalid choice. Aborting..."
        # exit 1
        # ;;
      # esac
    # fi
#
    # # Pull latest changes from the main branch
    # echo "Pulling latest changes from repository..."
    # git pull --rebase origin main
  # else
    # git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  # fi
  # echo "Dotfiles cloned to $DOTFILES_DIR"
# }
#
# # Function to back up conflicting files during stow operation
# backup_conflicting_files() {
  # local conflicting_dir="$1"
  # local backup_dir="$HOME/dotfiles_backup/$conflicting_dir"
  # mkdir -p "$backup_dir"
  # echo "Backing up existing dotfiles from $HOME to $backup_dir"
#
  # # Check for conflicts in the home directory and back them up
  # for file in "$DOTFILES_DIR/$conflicting_dir"/*; do
    # filename="$(basename "$file")"
    # home_file="$HOME/$filename"
#
    # # If the file exists in home and is not a symlink, back it up
    # if [ -e "$home_file" ] && [ ! -L "$home_file" ]; then
      # echo "Backing up $home_file to $backup_dir"
      # mv "$home_file" "$backup_dir"
    # fi
  # done
  # echo "Backup completed for $conflicting_dir."
# }
#
# # Function to create symlinks using stow, based on hostname
# stow_dotfiles() {
  # echo "Creating symlinks with GNU Stow..."
#
  # # Get the current hostname
  # FULL_HOSTNAME=$(hostname -f)
#
  # # Add ~/.local/bin to PATH if it's not already there
  # if [[ ":$PATH:" != *":$LOCALBIN:"* ]]; then
    # export PATH="$LOCALBIN:$PATH"
  # fi
#
  # cd "$DOTFILES_DIR" || exit
#
  # # Base list of directories to stow
  # STOW_DIRS=("bin" "git" "iterm2" "vim" "zsh") # General directories
#
  # # Add specific directories if hostname contains "dreamhost"
  # if [[ "$FULL_HOSTNAME" == *"dreamhost"* ]]; then
    # STOW_DIRS+=("ndnhost")
  # else
    # STOW_DIRS+=("localhost")
  # fi
#
  # # Use stow to create symlinks for each selected directory
  # for dir in "${STOW_DIRS[@]}"; do
    # stow_exit_code=0
#
    # # Special case for the 'bin' directory to stow to ~/.local/bin
    # if [[ "$dir" == "bin" ]]; then
      # echo "Stowing $dir to ~/.local/bin"
      # stow_output=$(stow --override=~ -n -v -t ~/.local/bin "$dir" 2>&1) || stow_exit_code=$?
    # else
      # echo "Stowing $dir"
      # stow_output=$(stow --override=~ -n -v -t ~ "$dir" 2>&1) || stow_exit_code=$?
    # fi
#
    # # Handle conflicts
    # if [[ $stow_output == *"conflicts"* || $stow_exit_code -ne 0 ]]; then
      # echo "Conflicts detected for $dir:"
      # echo "$stow_output"
#
      # # Print options for resolving conflicts
      # echo "Options:"
      # echo "  (s)kip: Do not stow $dir."
      # echo "  (b)ackup: Move conflicting files in $HOME to $HOME/dotfiles_backup/$dir and then stow $dir."
      # echo "  (a)dopt: Make stow take control of existing conflicting files."
      # echo "  (o)verwrite: Forcefully replace conflicting files with symlinks from $dir."
      # read -r -p "Choose an option: [s/b/a/o]: " choice
#
      # case $choice in
      # s | S)
        # echo "Skipping $dir..."
        # ;;
      # b | B)
        # echo "Backing up conflicting files for $dir..."
        # backup_conflicting_files "$dir"
        # if [[ "$dir" == "bin/" ]]; then
          # stow --override=~ -v -t ~/.local/bin "$dir"
        # else
          # stow --override=~ -v -t ~ "$dir"
        # fi
        # ;;
      # a | A)
        # echo "Adopting existing files for $dir..."
        # if [[ "$dir" == "bin/" ]]; then
          # stow --override=~ --adopt -v -t ~/.local/bin "$dir"
        # else
          # stow --override=~ --adopt -v -t ~ "$dir"
        # fi
        # ;;
      # o | O)
        # echo "Overwriting existing files for $dir..."
        # if [[ "$dir" == "bin/" ]]; then
          # stow --override=~ --force -v -t ~/.local/bin "$dir"
        # else
          # stow --override=~ --force -v -t ~ "$dir"
        # fi
        # ;;
      # *)
        # echo "Invalid choice. Skipping $dir..."
        # ;;
      # esac
    # else
      # if [[ "$dir" == "bin" ]]; then
        # stow --override=~ -v -t ~/.local/bin "$dir"
      # else
        # stow --override=~ -v -t ~ "$dir"
      # fi
    # fi
  # done
#
  # echo "Symlinks created successfully."
# }
#
# # Function to restore stashed changes
# restore_stashed_changes() {
  # cd "$DOTFILES_DIR" || exit
  # if git stash list | grep -q 'stash@{0}'; then
    # echo "Restoring stashed changes..."
    # git stash pop
  # else
    # echo "No stashed changes to restore."
  # fi
# }
#
# # Function to update and install zplug plugins
# update_zplug() {
  # if command -v zplug &>/dev/null; then
    # echo "Updating and installing zplug plugins..."
    # zplug update && zplug install
  # else
    # echo "zplug is not installed or not in PATH."
  # fi
# }

# Check if zsh is the default shell and activate it if necessary
# check_zsh

# Check and install dependencies
# check_dependencies

# Install or update Homebrew on macOS
# install_or_update_homebrew

# Install Vim from source or via Homebrew
# install_vim

# Install the latest version of GNU Coreutils if needed
# check_coreutils_installation

# Check if GNU Stow is installed and install it if not
# check_stow_installation

# Clone dotfiles repository and handle any local changes
# clone_dotfiles

# Create symlinks using GNU Stow and handle conflicts dynamically
# stow_dotfiles

# Restore stashed changes, if any
# restore_stashed_changes

# Update and install zplug plugins
#update_zplug

# echo "Dotfiles setup completed!"
