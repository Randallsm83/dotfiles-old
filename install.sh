#!/usr/bin/env bash

set -euo pipefail

# Minimal bootstrap - just what we need to clone and get the env files
DOTFILES_URL="https://github.com/Randallsm83/dotfiles.git"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

DOTFILES="$XDG_CONFIG_HOME/dotfiles"

BUILD_DIR="$XDG_CACHE_HOME/dotfiles/build"
LOG_DIR="$XDG_STATE_HOME/dotfiles/build/logs"

# Create the directory structure
mkdir -p "$LOG_DIR" || { echo "Failed to create $LOG_DIR"; exit 1; }
mkdir -p "$BUILD_DIR" || { echo "Failed to create $BUILD_DIR"; exit 1; }

# # List the directory structure to verify its existence
# echo "Directory structure after creation attempt:"
# ls -ld "$XDG_STATE_HOME" "$XDG_STATE_HOME/dotfiles" "$XDG_STATE_HOME/dotfiles/build" "$LOG_DIR" || { echo "Failed to list directory structure"; exit 1; }

# Set log file path
LOG_FILE="$LOG_DIR/setup_$(date '+%Y%m%d_%H%M%S').log"
touch "$LOG_FILE" || { echo "Failed to create log file: $LOG_FILE"; exit 1; }

# touch "$LOG_FILE" || {
#   echo "Failed to create log file: $LOG_FILE"
#   exit 1
# }

# # List the log file to verify its existence
# echo "Log file created successfully:"
# ls -l "$LOG_FILE"

# Detect OS for package manager
if [ "$(uname)" == "Darwin" ]; then
  OS="macos"
elif [ "$(uname)" == "Linux" ]; then
  OS="linux"
else
  log "Unsupported operating system"
  exit 1
fi

# Error handling
cleanup() {
  local exit_code="$?"
  log "Cleaning up..."
  cleanup_build_directory
  # Remove partial installs if failed
  if [ $exit_code -ne 0 ]; then
    log "Installation failed. Check logs at $LOG_FILE"
    if [ -d "$DOTFILES" ] && [ ! -d "$DOTFILES/.git" ]; then
      log "Removing partial dotfiles install"
      rm -rf "$DOTFILES"
    fi
  fi
  exit $exit_code
}

trap cleanup EXIT
trap 'trap - EXIT; cleanup' INT TERM

# Logging function
log() {
  echo "$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >>"$LOG_FILE"
}

# Check permissions early
check_permissions() {
  local dirs=("$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_STATE_HOME/dotfiles" "$XDG_STATE_HOME/dotfiles/build" "$XDG_CACHE_HOME" "$LOG_DIR" "$BUILD_DIR")

  for dir in "${dirs[@]}"; do
    echo "Checking directory: $dir" # Debugging line
    if [ ! -d "$dir" ]; then
      echo "Directory $dir does not exist. Creating it..." # Debugging line
      if ! mkdir -p "$dir" 2>/dev/null; then
        echo "Error: Cannot create directory $dir"
        return 1
      fi
    fi
    echo "Directory $dir exists. Testing write permissions..." # Debugging line
    if ! touch "$dir/.write_test" 2>/dev/null; then
      echo "Error: Cannot write to $dir"
      return 1
    fi
    rm -f "$dir/.write_test"
  done
}

setup_build_directory() {
  if [ -d "$BUILD_DIR" ]; then
    log "Cleaning existing build directory..."
    rm -rf "$BUILD_DIR"*
  fi
  mkdir -p "$BUILD_DIR"
}

cleanup_build_directory() {
  if [ -d "$BUILD_DIR" ]; then
    log "Cleaning up build directory..."
    rm -rf "$BUILD_DIR"*
  fi
}

clone_dotfiles() {
  if [ ! -d "$DOTFILES" ]; then
    log "Cloning dotfiles repository..."
    if ! git clone "$DOTFILES_URL" "$DOTFILES"; then
      log "Failed to clone dotfiles repository"
      return 1
    fi
  else
    if [ -d "$DOTFILES/.git" ]; then
      log "Dotfiles repository already exists"
      git -C "$DOTFILES" pull origin main
    else
      log "Error: $DOTFILES exists but is not a git repository"
      return 1
    fi
  fi
}

stow_dotfiles() {
  log "Stowing dotfiles..."
  cd "$DOTFILES"

  for dir in */; do
    if [ -d "$dir" ]; then
      dir="${dir%/}"
      log "Processing $dir..."

      # Get conflicts that are regular files (not symlinks)
      regular_file_conflicts=$("$HOME/.local/bin/stow" -nv "$dir" 2>&1 | grep "existing target is neither a link nor a directory" || true)

      # Handle regular file conflicts with --adopt
      if [ -n "$regular_file_conflicts" ]; then
        log "Found regular file conflicts in $dir:"
        echo "$regular_file_conflicts"
        read -rp "Adopt these files into the repo? [y/N] " choice
        if [[ $choice =~ ^[Yy]$ ]]; then
          "$HOME/.local/bin/stow" --adopt "$dir"
          log "Adopted files. Please review changes with 'git diff' and commit if happy"
        else
          log "Skipping $dir"
          continue
        fi
      fi

      # Now we can safely use -R as any remaining conflicts would be symlinks
      "$HOME/.local/bin/stow" -R "$dir"
    fi
  done
}

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
}

install_stow_from_source() {
  log "Installing GNU stow from source..."

  setup_build_directory
  cd "$BUILD_DIR"

  log "Downloading stow source..."
  if ! curl -L https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz | tar xz >>"$LOG_FILE" 2>&1; then
    log "Failed to download or extract stow source"
    cat "$LOG_FILE"
    cleanup_build_directory
    return 1
  fi

  cd stow-*/

  # Configure stow with XDG compliance
  export PERL_HOMEDIR=1
  export PERL_MM_OPT="INSTALL_BASE=$XDG_DATA_HOME/perl5"
  export PERL_MB_OPT="--install_base $XDG_DATA_HOME/perl5"

  log "Configuring stow..."
  ./configure --prefix="$HOME/.local" \
    --datarootdir="$XDG_DATA_HOME" \
    --sysconfdir="$XDG_CONFIG_HOME" >>"$LOG_FILE" 2>&1

  log "Building stow..."
  if ! make >>"$LOG_FILE" 2>&1; then
    log "Build failed. Check log at: $LOG_FILE"
    cleanup_build_directory
    return 1
  fi

  log "Installing stow..."
  if ! make install >>"$LOG_FILE" 2>&1; then
    log "Installation failed. Check log at: $LOG_FILE"
    cleanup_build_directory
    return 1
  fi

  cleanup_build_directory
}

install_asdf() {
  log "Setting up ASDF version manager..."

  # Clone ASDF
  if [ ! -d "$ASDF_DATA_DIR" ]; then
    log "Cloning ASDF..."
    if ! git clone https://github.com/asdf-vm/asdf.git "$ASDF_DATA_DIR"; then
      log "Failed to clone ASDF"
      return 1
    fi
  else
    log "ASDF already installed, updating..."
    if ! (git -C "$ASDF_DATA_DIR" pull origin master); then
      log "Failed to update ASDF"
      return 1
    fi
  fi

  # Source ASDF
  . "$ASDF_DATA_DIR/asdf.sh"

  # Install plugins and versions from your tool-versions file
  local failed_plugins=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ $line =~ ^[^#] ]]; then
      plugin=$(echo "$line" | cut -d' ' -f1)
      if ! asdf plugin list | grep -q "^$plugin$"; then
        log "Installing ASDF plugin: $plugin"
        if ! asdf plugin add "$plugin"; then
          failed_plugins+=("$plugin")
          log "Failed to install plugin: $plugin"
          continue
        fi
      fi
    fi
  done <"$XDG_CONFIG_HOME/asdf/tool-versions"

  if [ ${#failed_plugins[@]} -gt 0 ]; then
    log "Warning: Failed to install plugins: ${failed_plugins[*]}"
    log "You may need to install them manually"
  fi

  log "Installing tool versions..."
  asdf install

  # Install shell completions
  local shell
  shell=$(basename "$SHELL")
  local completion_dir="$XDG_DATA_HOME/completions"
  mkdir -p "$completion_dir"

  case "$shell" in
  bash)
    cp "$ASDF_DATA_DIR/completions/asdf.bash" "$completion_dir/"
    ;;
  zsh)
    cp "$ASDF_DATA_DIR/completions/asdf.zsh" "$completion_dir/"
    ;;
  esac
}

check_glibc_headers() {
  log "Checking and installing glibc development headers..."

  # Check if limits.h is already present
  GLIBC_INCLUDE_PATH="$HOME/.local/include/limits.h"
  if [ -f "$GLIBC_INCLUDE_PATH" ]; then
    log "glibc development headers are already installed at $GLIBC_INCLUDE_PATH"
    return 0
  fi

  # Set up build directory
  setup_build_directory
  cd "$BUILD_DIR"

  # Set version and URLs
  GLIBC_VERSION="2.4"
  GLIBC_TARBALL_URL="https://ftp.gnu.org/gnu/libc/glibc-$GLIBC_VERSION.tar.gz"
  GLIBC_TARBALL="$BUILD_DIR/glibc-$GLIBC_VERSION.tar.gz"
  GLIBC_SOURCE_DIR="$BUILD_DIR/glibc-$GLIBC_VERSION"

  # Download glibc source
  log "Downloading glibc version $GLIBC_VERSION source..."
  if ! curl -L "$GLIBC_TARBALL_URL" -o "$GLIBC_TARBALL" >>"$LOG_FILE" 2>&1; then
    log "Failed to download glibc source tarball"
    cat "$LOG_FILE"
    cleanup_build_directory
    return 1
  fi

  # Extract glibc tarball
  log "Extracting glibc source..."
  if ! tar -xzf "$GLIBC_TARBALL" >>"$LOG_FILE" 2>&1; then
    log "Failed to extract glibc source tarball"
    cat "$LOG_FILE"
    cleanup_build_directory
    return 1
  fi

  # Configure and install headers
  log "Configuring glibc headers..."
  cd "$GLIBC_SOURCE_DIR"
  if ! ./configure --prefix="$HOME/.local" >>"$LOG_FILE" 2>&1; then
    log "Failed to configure glibc headers"
    cat "$LOG_FILE"
    cleanup_build_directory
    return 1
  fi

  log "Building glibc headers..."
  if ! make -j"$(nproc)" >>"$LOG_FILE" 2>&1; then
    log "Failed to build glibc headers"
    cat "$LOG_FILE"
    cleanup_build_directory
    return 1
  fi

  log "Installing glibc headers..."
  if ! make install-headers >>"$LOG_FILE" 2>&1; then
    log "Failed to install glibc headers"
    cat "$LOG_FILE"
    cleanup_build_directory
    return 1
  fi

  # Cleanup build directory after success
  cleanup_build_directory

  log "glibc development headers installed successfully."
}

check_macos_build_tools() {
  log "Checking build tools..."

  if xcode-select -p &>/dev/null; then
    log "Xcode Command Line Tools are installed"
    return 0
  fi

  local missing_tools=()
  local build_tools=(
    "gcc:gcc"
    "make:make"
    "automake:automake"
    "perl:perl"
    "curl:curl"
  )

  for tool in "${build_tools[@]}"; do
    local package_name="${tool%%:*}"
    local command_name="${tool#*:}"

    if ! command -v "$command_name" >/dev/null 2>&1; then
      missing_tools+=("$package_name")
    fi
  done

  if [ ${#missing_tools[@]} -eq 0 ]; then
    log "All required build tools are already installed"
    return 0
  fi

  log "Missing build tools: ${missing_tools[*]}"

  if ! command -v brew >/dev/null 2>&1; then
    install_homebrew
  fi

  for tool in "${missing_tools[@]}"; do
    log "Installing $tool..."
    brew install "$tool" >>"$LOG_FILE" 2>&1
  done
}

ensure_build_tools() {
  if [ "$OS" == "macos" ]; then
    check_macos_build_tools
  else
    local missing_tools=()
    local build_tools=(
      "gcc"
      "ldd"
      "make"
      "automake"
      "perl"
      "curl"
    )

    for tool in "${build_tools[@]}"; do
      if ! command -v "$tool" >/dev/null 2>&1; then
        missing_tools+=("$tool")
      fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
      log "The following build tools are required but not installed: ${missing_tools[*]}"
      log "Please install them through your distribution's package manager"
      exit 1
    fi

    check_glibc_headers
  fi
}

main() {
  log "Starting dotfiles setup..."

  # Check permissions first
  if ! check_permissions; then
    log "Permission check failed. Please check directory permissions."
    exit 1
  fi

  ensure_build_tools

  # Get dotfiles and initial env setup
  if ! clone_dotfiles; then
    log "Failed to setup dotfiles"
    exit 1
  fi

  # Install stow first since we need it
  if ! command -v stow >/dev/null 2>&1; then
    if ! install_stow_from_source; then
      log "Failed to install stow"
      exit 1
    fi
  fi

  # First stow to get env files
  if ! stow_dotfiles; then
    log "Failed to stow dotfiles"
    exit 1
  fi

  # Now source your env files which handle all the rest
  for env_file in "$XDG_CONFIG_HOME/env.d"/*.conf; do
    if [[ -r "$env_file" ]]; then
      source "$env_file"
    else
      log "Warning: Cannot read env file: $env_file"
    fi
  done

  # Now that we have proper env, do the rest
  if ! install_asdf; then
    log "Failed to setup ASDF"
    exit 1
  fi

  if git -C "$DOTFILES" status --porcelain | grep -q '^'; then
    log "There are uncommitted changes in your dotfiles repo. Please review with 'git diff' and commit if happy."
  fi

  log "Setup complete! Please restart your shell session."
}

main
