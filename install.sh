#!/bin/bash

# Define variables
DOTFILES_REPO="https://github.com/Randallsm83/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
STOW_VERSION="2.4.1"
STOW_DIR="$HOME/.local/bin"
STOW_TAR="stow-$STOW_VERSION.tar.gz"
STOW_URL="https://ftp.gnu.org/gnu/stow/$STOW_TAR"

# Function to install GNU Stow locally
install_stow() {
    echo "Installing GNU Stow locally..."

    # Create directories
    mkdir -p "$STOW_DIR" "$HOME/.local"

    # Download and extract GNU Stow
    wget "$STOW_URL" -O "$STOW_TAR"
    tar -xf "$STOW_TAR"
    cd "stow-$STOW_VERSION" || exit

    # Install Stow locally in ~/.local
    perl Makefile.PL --prefix="$HOME/.local" && make && make install

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

    # Change to dotfiles directory
    cd "$DOTFILES_DIR" || exit

    # Use stow to create symlinks for each directory (adjust as needed)
    for dir in */; do
        stow -v -t ~ "$dir"
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
