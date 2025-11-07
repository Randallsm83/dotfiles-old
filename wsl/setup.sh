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

# Install mise version manager
if ! command -v mise &>/dev/null; then
    read -rp "Install mise version manager? (Y/n) " choice
    
    if [[ ! "$choice" =~ ^[Nn]$ ]]; then
        log "Installing mise..."
        
        # Set up XDG directories for mise
        export MISE_DATA_DIR="$XDG_DATA_HOME/mise"
        export MISE_CONFIG_DIR="$XDG_CONFIG_HOME/mise"
        export MISE_CACHE_DIR="$XDG_CACHE_HOME/mise"
        export MISE_STATE_DIR="$XDG_STATE_HOME/mise"
        
        mkdir -p "$MISE_DATA_DIR" "$MISE_CONFIG_DIR" "$MISE_CACHE_DIR" "$MISE_STATE_DIR"
        
        curl https://mise.run | sh
        
        # Add to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
        
        if command -v mise &>/dev/null; then
            success "mise installed"
            log "mise version: $(mise --version)"
            
            # Trust the dotfiles config
            if [ -f "$XDG_CONFIG_HOME/mise/config.toml" ]; then
                log "Trusting mise config..."
                mise trust "$XDG_CONFIG_HOME/mise/config.toml" 2>/dev/null || true
            fi
            
            # Install tools from config if it exists
            if [ -f "$XDG_CONFIG_HOME/mise/config.toml" ]; then
                log "Installing tools from mise config..."
                mise install || warn "Some mise tools failed to install"
            fi
        else
            warn "mise installation may have failed"
        fi
    fi
else
    success "mise already installed"
    log "mise version: $(mise --version)"
fi

# Install thefuck command correction tool
if ! command -v thefuck &>/dev/null; then
    read -rp "Install thefuck command correction? (Y/n) " choice
    
    if [[ ! "$choice" =~ ^[Nn]$ ]]; then
        log "Installing thefuck..."
        
        # Try mise first if available
        if command -v mise &>/dev/null; then
            if mise use -g thefuck 2>/dev/null; then
                success "thefuck installed via mise"
            else
                # Fallback to pip
                log "thefuck not available via mise, trying pip..."
                if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
                    pip3 install --user thefuck 2>/dev/null || pip install --user thefuck
                    success "thefuck installed via pip"
                else
                    warn "pip not available, skipping thefuck installation"
                fi
            fi
        else
            # Try pip if mise not available
            if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
                pip3 install --user thefuck 2>/dev/null || pip install --user thefuck
                success "thefuck installed via pip"
            else
                warn "Neither mise nor pip available, skipping thefuck"
            fi
        fi
    fi
else
    success "thefuck already installed"
fi

# GNU Stow the dotfiles
log "Stowing dotfiles..."

cd "$DOTFILES_DIR"

# List of packages to stow (skip Windows-specific ones)
PACKAGES=(
    "zsh"
    "git"
    "ssh"
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

# Setup 1Password SSH agent socket for WSL
log "Setting up 1Password SSH agent for WSL..."

SSH_AGENT_SOCK="/mnt/wsl/1password/agent.sock"
if [ -S "$SSH_AGENT_SOCK" ]; then
    success "1Password SSH agent socket found at $SSH_AGENT_SOCK"
    echo "export SSH_AUTH_SOCK='$SSH_AGENT_SOCK'" >> "$HOME/.zshenv"
    success "SSH_AUTH_SOCK configured in .zshenv"
else
    warn "1Password SSH agent socket not found at $SSH_AGENT_SOCK"
    warn "Make sure 1Password desktop app is running on Windows with SSH agent enabled"
    echo "  Settings → Developer → SSH Agent → Enable"
fi

# Fix zsh compaudit insecure directories
log "Fixing zsh directory permissions..."

if command -v zsh &>/dev/null; then
    # Get list of insecure directories
    INSECURE_DIRS=$(zsh -c 'autoload -U compinit && compaudit 2>/dev/null' || true)
    
    if [ -n "$INSECURE_DIRS" ]; then
        warn "Found insecure directories:"
        echo "$INSECURE_DIRS"
        
        read -rp "Fix permissions? (Y/n) " choice
        if [[ ! "$choice" =~ ^[Nn]$ ]]; then
            echo "$INSECURE_DIRS" | while read -r dir; do
                if [ -d "$dir" ]; then
                    log "Fixing: $dir"
                    chmod go-w "$dir" 2>/dev/null && \
                    chown "$USER:$USER" "$dir" 2>/dev/null || \
                    sudo chown "$USER:$USER" "$dir" 2>/dev/null || \
                    warn "Could not fix $dir"
                fi
            done
            success "Directory permissions fixed"
        fi
    else
        success "No insecure directories found"
    fi
fi

# Verification
echo ""
log "Verifying installation..."
echo ""

VERIFY_SUCCESS=0
VERIFY_FAILED=0

# Check mise
if command -v mise &>/dev/null; then
    success "mise: $(mise --version)"
    ((VERIFY_SUCCESS++))
else
    error "mise not found"
    ((VERIFY_FAILED++))
fi

# Check thefuck
if command -v thefuck &>/dev/null; then
    success "thefuck: installed"
    ((VERIFY_SUCCESS++))
else
    warn "thefuck not found (optional)"
fi

# Check helper functions
if [ -f "$HOME/.config/zsh/.zshrc.d/00-helpers.zsh" ]; then
    success "Helper functions: present"
    ((VERIFY_SUCCESS++))
else
    error "Helper functions file missing"
    ((VERIFY_FAILED++))
fi

# Check dircolors
if [ -f "$HOME/.config/zsh/colors/onedarkpro.dircolors" ]; then
    success "onedarkpro.dircolors: present"
    ((VERIFY_SUCCESS++))
else
    warn "onedarkpro.dircolors missing (will be fixed after stow)"
fi

# Check for any remaining insecure directories
if command -v zsh &>/dev/null; then
    INSECURE_CHECK=$(zsh -c 'autoload -U compinit && compaudit 2>/dev/null' || true)
    if [ -z "$INSECURE_CHECK" ]; then
        success "No insecure directories"
        ((VERIFY_SUCCESS++))
    else
        warn "Some insecure directories remain"
    fi
fi

# Check sample stowed files
if [ -L "$HOME/.config/zsh/.zshrc" ] || [ -f "$HOME/.config/zsh/.zshrc" ]; then
    success "Symlinks: working"
    ((VERIFY_SUCCESS++))
else
    error "Symlinks not working properly"
    ((VERIFY_FAILED++))
fi

echo ""
if [ $VERIFY_FAILED -eq 0 ]; then
    success "All critical checks passed! ($VERIFY_SUCCESS successes)"
else
    warn "Setup complete with $VERIFY_FAILED failed checks and $VERIFY_SUCCESS successes"
fi

echo ""
success "Dotfiles setup complete!"
echo ""
log "Next steps:"
echo "  1. Restart your shell or run: exec zsh"
echo "  2. Test SSH agent: ssh -T git@github.com"
echo "  3. If SSH fails, ensure 1Password SSH agent is enabled in Windows"
echo "  4. Configure Windows Terminal to use a Nerd Font"
echo ""
log "To manually stow additional packages:"
echo "  cd $DOTFILES_DIR && stow --dotfiles <package-name>"
