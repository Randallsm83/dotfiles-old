#!/usr/bin/env bash

set -euoa pipefail

# Minimal bootstrap - just what we need to clone and get the env files
DOTFILES_URL="https://github.com/Randallsm83/dotfiles.git"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

DOTFILES="$XDG_CONFIG_HOME/dotfiles"

DOTS_BUILD_DIR="$XDG_CACHE_HOME/build/dotfiles"
LOG_DIR="$XDG_STATE_HOME/build/dotfiles/logs"

# Create the directory structure
mkdir -p "$LOG_DIR" || { echo "Failed to create $LOG_DIR"; exit 1; }
mkdir -p "$DOTS_BUILD_DIR" || { echo "Failed to create $DOTS_BUILD_DIR"; exit 1; }

# Set log file path
LOG_FILE="$LOG_DIR/setup_$(date '+%Y%m%d_%H%M%S').log"
touch "$LOG_FILE" || { echo "Failed to create log file: $LOG_FILE"; exit 1; }

# Logging function
log() {
  echo "$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >>"$LOG_FILE"
}

# Detect OS for package manager
if [ "$(uname)" == "Darwin" ]; then
  OS="macos"
elif [ "$(uname)" == "Linux" ]; then
  OS="linux"
else
  log "Unsupported operating system"
  exit 1
fi

cleanup_build_directory() {
  if [ -d "$DOTS_BUILD_DIR" ]; then
    log "Cleaning up build directory..."
    rm -rf "$DOTS_BUILD_DIR"*
  fi
}

# Error handling
# cleanup() {
#   local exit_code="$?"
#   log "Cleaning up..."
#   cleanup_build_directory
#   # Remove partial installs if failed
#   if [ $exit_code -ne 0 ]; then
#     log "Installation failed. Check logs at $LOG_FILE"
#     if [ -d "$DOTFILES" ] && [ ! -d "$DOTFILES/.git" ]; then
#       log "Removing partial dotfiles install"
#       rm -rf "$DOTFILES"
#     fi
#   fi
#   exit $exit_code
# }
#
# trap cleanup EXIT
# trap 'trap - EXIT; cleanup' INT TERM
#

# Check permissions
check_permissions() {
  local dirs=(
    "$XDG_DATA_HOME"
    "$XDG_CONFIG_HOME"
    "$XDG_CACHE_HOME"
    "$XDG_STATE_HOME"
    "$XDG_STATE_HOME/dotfiles"
    "$XDG_STATE_HOME/dotfiles/build"
    "$LOG_DIR"
    "$DOTS_BUILD_DIR"
  )

  for dir in "${dirs[@]}"; do
    echo "Checking directory: $dir"
    if [ ! -d "$dir" ]; then
      echo "Directory $dir does not exist. Creating it..."
      if ! mkdir -p "$dir" 2>/dev/null; then
        log "Error: Cannot create directory $dir"
        return 1
      fi
    fi
    echo "Directory $dir exists. Testing write permissions..."
    if ! touch "$dir/.write_test" 2>/dev/null; then
      log "Error: Cannot write to $dir"
      return 1
    fi
    rm -f "$dir/.write_test"
  done
}

# Clone dotfiles
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

source_env_vars() {
  ENV_DIR="$HOME/.config/env.d"
  IGNORE_DIRS=("env" "asdf" "homebrew")

  # Source each base .conf file in env.d directory
  if [ -d "$ENV_DIR" ]; then
    for conf in "$ENV_DIR"/*.conf; do
      if [ -f "$conf" ]; then
        echo "Sourcing base environment file: $conf"
        source "$conf"
      fi
    done
  else
    echo "Base environment directory $ENV_DIR not found."
  fi

  # Source each package-specific .conf file if it exists
  for package_dir in "${PACKAGE_DIRS[@]}"; do
    env_conf_file="$package_dir/env.conf"
    if [ -f "$env_conf_file" ]; then
      echo "Sourcing package-specific environment file: $env_conf_file"
      source "$env_conf_file"
    else
      echo "Package-specific environment file not found: $env_conf_file"
    fi
  done
}

stow_dotfiles() {
  log "Stowing dotfiles..."
  cd "$DOTFILES"

  # TODO if linux, add homebrew to ignore file
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

install_stow() {
  if ! command -v stow >/dev/null 2>&1; then
    log "Installing GNU stow from source..."

    mkdir -p "$DOTS_BUILD_DIR/stow"
    cd "$DOTS_BUILD_DIR/stow"

    log "Downloading stow source..."
    if ! stdbuf -oL curl -L https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz | tar xz >>"$LOG_FILE" 2>&1; then
      log "Failed to download or extract stow source. Check log at: $LOG_FILE"
      return 1
    fi

    cd stow-*/

    # Configure stow with XDG compliance
    export PERL_HOMEDIR=1
    export PERL_MM_OPT="INSTALL_BASE=$XDG_DATA_HOME/perl5"
    export PERL_MB_OPT="--install_base $XDG_DATA_HOME/perl5"

    log "Configuring stow..."
    stdbuf -oL ./configure --prefix="$HOME/.local" \
      --datarootdir="$XDG_DATA_HOME" \
      --sysconfdir="$XDG_CONFIG_HOME" >>"$LOG_FILE" 2>&1

    log "Building stow..."
    if ! stdbuf -oL make >>"$LOG_FILE" 2>&1; then
      log "Build failed. Check log at: $LOG_FILE"
      return 1
    fi

    log "Installing stow..."
    if ! stdbuf -oL make install >>"$LOG_FILE" 2>&1; then
      log "Installation failed. Check log at: $LOG_FILE"
      return 1
    fi

  fi
}

install_mise() {
  log "Setting up mise version manager..."

  export MISE_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mise"
  export MISE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
  export MISE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mise"
  export MISE_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/mise"

  # Install mise using the official installer
  if ! command -v mise >/dev/null 2>&1; then
    log "Installing mise..."
    if ! curl https://mise.run | sh; then
      log "Failed to install mise, trying alternative method..."
      # Try cargo install as fallback
      if command -v cargo >/dev/null 2>&1; then
        if ! cargo install mise; then
          log "Failed to install mise via cargo"
          return 1
        fi
      else
        log "Failed to install mise. Please install manually: https://mise.jdx.dev"
        return 1
      fi
    fi

    # Add mise to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
  else
    log "mise already installed, updating..."
    mise self-update || log "Could not auto-update mise"
  fi

  # Verify mise is available
  if ! command -v mise >/dev/null 2>&1; then
    log "mise installation failed or not in PATH"
    return 1
  fi

  log "mise version: $(mise --version)"

  # Install tools from config
  if [ -f "$MISE_CONFIG_DIR/config.toml" ]; then
    log "Installing tools from config.toml..."
    if ! mise install; then
      log "Some tools failed to install, continuing..."
    fi
  else
    log "No mise config.toml found, skipping tool installation"
  fi

  # Trust the dotfiles config if it exists
  if [ -f "$DOTFILES/.mise.toml" ] || [ -f "$DOTFILES/mise.toml" ]; then
    log "Trusting dotfiles mise config..."
    mise trust
  fi
}

check_glibc_headers() {
  log "Extracting glibc development headers..."

  # Set URL for the deb package with glibc headers
  GLIBC_DEV_DEB_URL="http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6-dev_2.40-1ubuntu3_amd64.deb"
  GLIBC_DEV_DEB="$DOTS_BUILD_DIR/libc6-dev.deb"
  GLIBC_DEV_DIR="$DOTS_BUILD_DIR/glibc-dev"

  cd "$DOTS_BUILD_DIR"
  mkdir -p "$GLIBC_DEV_DIR"

  # Download glibc dev package
  log "Downloading glibc dev package..."
  if ! stdbuf -oL curl -L "$GLIBC_DEV_DEB_URL" -o "$GLIBC_DEV_DEB" >>"$LOG_FILE" 2>&1; then
    log "Failed to download glibc dev package"
    return 1
  fi

  # Extract glibc dev package
  log "Extracting glibc dev package..."
  if ! stdbuf -oL dpkg-deb -x "$GLIBC_DEV_DEB" "$GLIBC_DEV_DIR" >>"$LOG_FILE" 2>&1; then
    log "Failed to extract glibc dev package"
    return 1
  fi

  # Update include paths
  log "Updating environment variables with extracted glibc headers"
  export C_INCLUDE_PATH="$GLIBC_DEV_DIR/usr/include:/usr/include:${C_INCLUDE_PATH:-}"
  export LIBRARY_PATH="$GLIBC_DEV_DIR/usr/lib:/usr/lib:${LIBRARY_PATH:-}"
  export CFLAGS="-I$GLIBC_DEV_DIR/usr/include -I/usr/include ${CFLAGS:-}"
  export CPPFLAGS="-I$GLIBC_DEV_DIR/usr/include -I/usr/include ${CPPFLAGS:-}"
  export LDFLAGS="-L$GLIBC_DEV_DIR/usr/lib -L/usr/lib ${LDFLAGS:-}"

  log "glibc development headers extracted successfully."
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
    stdbuf -oL brew install "$tool" >>"$LOG_FILE" 2>&1
  done
}

ensure_build_tools() {
  if [ "$OS" == "macos" ]; then
    check_macos_build_tools
  else
    local missing_tools=()
    local build_tools=(
      "gcc"
      "cpp"
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
  check_permissions

  # Get dotfiles
  clone_dotfiles

  # Source env vars
  source_env_vars

  # Check build deps
  ensure_build_tools

  # Install stow
  install_stow

  # Stow files
  stow_dotfiles

  # Now source your env files which handle all the rest
  # for env_file in "$XDG_CONFIG_HOME/env.d"/*.conf; do
  #   if [[ -r "$env_file" ]]; then
  #     source "$env_file"
  #   else
  #     log "Warning: Cannot read env file: $env_file"
  #   fi
  # done

  # Install mise and other tools
  install_mise

  if git -C "$DOTFILES" status --porcelain | grep -q '^'; then
    log "There are uncommitted changes in your dotfiles repo. Please review with 'git diff' and commit if happy."
  fi

  # We made it
  cleanup_build_directory

  log "Setup complete! Please restart your shell session."
}

main
