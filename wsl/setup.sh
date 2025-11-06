#!/usr/bin/env bash

set -euo pipefail

# WSL Setup Script
# Sets up dotfiles in WSL using GNU Stow (same as Linux workflow)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[WSL Setup]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Detect WSL
if [[ -z "${WSL_DISTRO_NAME:-}" ]] && ! grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
    error "This script is intended for WSL environments only"
    exit 1
fi

success "Detected WSL environment: ${WSL_DISTRO_NAME:-Unknown}"

# Ensure we're in the dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

log "Dotfiles directory: $DOTFILES_DIR"

# Check if we're under /mnt (Windows filesystem)
if [[ "$DOTFILES_DIR" == /mnt/* ]]; then
    warn "Dotfiles are on Windows filesystem (/mnt)"
    warn "This can cause permission and symlink issues"
    warn "Consider cloning to your WSL home directory: ~/. config/dotfiles"
    read -rp "Continue anyway? (y/N) " choice
    [[ "$choice" =~ ^[Yy]$ ]] || exit 1
fi

# XDG Base Directory setup
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

log "Creating XDG directories..."
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
mkdir -p "$HOME/.local/bin"
success "XDG directories created"

# Check for required tools
log "Checking for required tools..."

MISSING_TOOLS=()

if ! command -v stow &>/dev/null; then
    MISSING_TOOLS+=("stow")
fi

if ! command -v git &>/dev/null; then
    MISSING_TOOLS+=("git")
fi

# Install missing packages
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    warn "Missing tools: ${MISSING_TOOLS[*]}"
    log "Installing via apt..."
    
    sudo apt-get update
    
    for tool in "${MISSING_TOOLS[@]}"; do
        sudo apt-get install -y "$tool"
    done
    
    success "Required tools installed"
else
    success "All required tools present"
fi

# Optional but recommended packages
log "Checking optional packages..."

OPTIONAL_PACKAGES=(
    "neovim:nvim"
    "ripgrep:rg"
    "fd-find:fdfind"
    "fzf:fzf"
    "bat:batcat"
    "btop:btop"
    "zsh:zsh"
)

MISSING_OPTIONAL=()

for pkg_cmd in "${OPTIONAL_PACKAGES[@]}"; do
    pkg="${pkg_cmd%%:*}"
    cmd="${pkg_cmd##*:}"
    
    if ! command -v "$cmd" &>/dev/null; then
        MISSING_OPTIONAL+=("$pkg")
    fi
done

if [ ${#MISSING_OPTIONAL[@]} -gt 0 ]; then
    warn "Optional packages not installed: ${MISSING_OPTIONAL[*]}"
    read -rp "Install optional packages? (Y/n) " choice
    
    if [[ ! "$choice" =~ ^[Nn]$ ]]; then
        log "Installing optional packages..."
        sudo apt-get install -y "${MISSING_OPTIONAL[@]}"
        success "Optional packages installed"
    fi
else
    success "All optional packages present"
fi

# Starship prompt (optional)
if ! command -v starship &>/dev/null; then
    read -rp "Install Starship prompt? (Y/n) " choice
    
    if [[ ! "$choice" =~ ^[Nn]$ ]]; then
        log "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        success "Starship installed"
    fi
fi

# GNU Stow the dotfiles
log "Stowing dotfiles..."

cd "$DOTFILES_DIR"

# List of packages to stow (skip Windows-specific ones)
PACKAGES=(
    "zsh"
    "git"
    "nvim"
    "starship"
    "wezterm"
    "bat"
    "ripgrep"
    "fzf"
    "eza"
    "editorconfig"
)

STOWED=()
SKIPPED=()

for pkg in "${PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        log "Stowing $pkg..."
        if stow --dir "$DOTFILES_DIR" --target "$HOME" --dotfiles --no-folding -R "$pkg" 2>&1; then
            STOWED+=("$pkg")
        else
            warn "Failed to stow $pkg"
            SKIPPED+=("$pkg")
        fi
    else
        SKIPPED+=("$pkg (not found)")
    fi
done

echo ""
success "Dotfiles setup complete!"
echo ""
log "Stowed packages (${#STOWED[@]}): ${STOWED[*]}"

if [ ${#SKIPPED[@]} -gt 0 ]; then
    warn "Skipped (${#SKIPPED[@]}): ${SKIPPED[*]}"
fi

echo ""
log "Next steps:"
echo "  1. Restart your shell or run: source ~/.zshrc (or ~/.bashrc)"
echo "  2. If using zsh, it should be detected from your dotfiles"
echo "  3. Starship prompt will activate automatically if installed"
echo "  4. Configure Windows Terminal to use a Nerd Font"
echo ""
log "To manually stow additional packages:"
echo "  cd $DOTFILES_DIR && stow <package-name>"
