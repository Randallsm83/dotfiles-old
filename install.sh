#!/bin/bash

# Enable error handling
set -euo pipefail

# Define variables
DOTFILES_REPO="https://github.com/Randallsm83/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_DIR="$HOME/.local"
STOW_URL_BASE="https://ftp.gnu.org/gnu/stow"
DEPENDENCIES=("wget" "tar" "git" "make" "gcc")

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

# Function to get the latest GNU Stow version number
get_latest_stow_version() {
    wget -qO- "$STOW_URL_BASE/" | grep -oP 'stow-\K[0-9.]+(?=.tar.gz)' | sort -V | tail -1
}

# Function to install GNU Stow locally
install_stow() {
    STOW_VERSION=$(get_latest_stow_version)
    STOW_TAR="stow-$STOW_VERSION.tar.gz"
    STOW_URL="$STOW_URL_BASE/$STOW_TAR"

    echo "Installing GNU Stow locally..."
    echo "Latest GNU Stow version: $STOW_VERSION"

    # Create local directories
    mkdir -p "$LOCAL_BIN"

    # Download and extract GNU Stow
    wget "$STOW_URL" -O "$STOW_TAR"
    tar -xf "$STOW_TAR"
    cd "stow-$STOW_VERSION" || exit

    # Install Stow locally in ~/.local
    ./configure --prefix="$LOCAL_DIR"
    make -j$(nproc)
    make install

    # Clean up
    cd ..
    rm -rf "stow-$STOW_VERSION" "$STOW_TAR"

    echo "GNU Stow installed locally at $LOCAL_BIN"
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
            read -p "Would you like to (s)tash, (r)eset, or (a)bort? [s/r/a]: " choice
            case $choice in
                s|S)
                    echo "Stashing local changes..."
                    git stash --include-untracked
                    ;;
                r|R)
                    echo "Resetting local changes..."
                    git reset --hard
                    git clean -fd
                    ;;
                a|A)
                    echo "Aborting..."
                    exit 1
                    ;;
                *)
                    echo "Invalid choice. Aborting..."
                    exit 1
                    ;;
            esac
        fi

        # Pull latest changes
        echo "Pulling latest changes from repository..."
        git pull --rebase origin main
    else
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
    echo "Dotfiles cloned to $DOTFILES_DIR"
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

# Function to back up existing files before stowing
backup_existing_files() {
    local backup_dir="$HOME/dotfiles_backup"
    mkdir -p "$backup_dir"
    echo "Backing up existing dotfiles to $backup_dir"

    # Backup existing files that are not symlinks
    cd "$DOTFILES_DIR" || exit
    for dir in */; do
        for file in "$HOME/${dir%/}"/*; do
            if [ -e "$file" ] && [ ! -L "$file" ]; then
                echo "Backing up $file to $backup_dir"
                mv "$file" "$backup_dir"
            fi
        done
    done
}

# Function to create symlinks using stow
stow_dotfiles() {
    echo "Creating symlinks with GNU Stow..."

    # Add ~/.local/bin to PATH if it's not already there
    if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
        export PATH="$LOCAL_BIN:$PATH"
    fi

    cd "$DOTFILES_DIR" || exit

    # Use stow to create symlinks for each directory
    for dir in */; do
        echo "Stowing $dir"
        stow --override=~ -v -t ~ "$dir"
    done

    echo "Symlinks created successfully."
}

# Function to check if GNU Stow is installed
check_stow_installation() {
    if ! command -v stow &> /dev/null; then
        echo "GNU Stow is not installed. Installing now..."
        install_stow
    else
        echo "GNU Stow is already installed."
    fi
}

# Check and install dependencies
check_dependencies

# Check if GNU Stow is installed and install it if not
check_stow_installation

# Clone dotfiles repository and handle any local changes
clone_dotfiles

# Back up existing files if needed
backup_existing_files

# Create symlinks using GNU Stow
stow_dotfiles

# Restore stashed changes, if any
restore_stashed_changes

echo "Dotfiles setup completed!"

