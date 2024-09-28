#!/bin/bash

# Define variables
DOTFILES_REPO="https://github.com/Randallsm83/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
STOW_DIR="$HOME/.local/bin"
STOW_INSTALL_DIR="$HOME/.local"
STOW_URL_BASE="https://ftp.gnu.org/gnu/stow"

# Function to get the latest GNU Stow version number
get_latest_stow_version() {
    # Fetch the index page of the FTP directory and find the latest version
    wget -qO- "$STOW_URL_BASE/" | grep -oP 'stow-\K[0-9.]+(?=.tar.gz)' | sort -V | tail -1
}

# Get the latest version of GNU Stow and construct the tarball URL
STOW_VERSION=$(get_latest_stow_version)
STOW_TAR="stow-$STOW_VERSION.tar.gz"
STOW_URL="$STOW_URL_BASE/$STOW_TAR"

# Function to install GNU Stow locally
install_stow() {
    echo "Installing GNU Stow locally..."

    echo "Latest GNU Stow version: $STOW_VERSION"

    # Create directories
    mkdir -p "$STOW_DIR" "$HOME/.local"

    # Download and extract GNU Stow
    echo "Downloading GNU Stow from $STOW_URL..."
    wget "$STOW_URL" -O "$STOW_TAR"
    tar -xf "$STOW_TAR"
    cd "stow-$STOW_VERSION" || exit

    # Install Stow locally in ~/.local
    ./configure --prefix="$HOME/.local"
    make
    make install

    # Clean up
    cd ..
    rm -rf "stow-$STOW_VERSION" "$STOW_TAR"

    echo "GNU Stow installed locally at $STOW_DIR"
}

# Function to clone dotfiles repository
clone_dotfiles() {
    echo "Cloning dotfiles repository..."

    # Clone dotfiles repository
    if [ -d "$DOTFILES_DIR" ]; then
        echo "Dotfiles directory already exists. Pulling latest changes..."
        cd "$DOTFILES_DIR" || exit
        git pull
    else
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi

    echo "Dotfiles cloned to $DOTFILES_DIR"
}

# Function to create symlinks using stow
stow_dotfiles() {
    echo "Creating symlinks with GNU Stow..."

    # Add ~/.local/bin to PATH if it's not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    cd "$DOTFILES_DIR" || exit

    # Use stow to create symlinks for each directory
    for dir in */; do
        stow --override=~ -v -t ~ "$dir"
    done

    echo "Symlinks created successfully."
}

# Check if GNU Stow is installed locally
if ! command -v stow &> /dev/null || [[ "$(stow --version)" != *"$STOW_VERSION"* ]]; then
    install_stow
else
    echo "GNU Stow is already installed."
fi

# Clone dotfiles repository
clone_dotfiles

# Create symlinks using GNU Stow
stow_dotfiles

echo "Dotfiles setup completed!"
