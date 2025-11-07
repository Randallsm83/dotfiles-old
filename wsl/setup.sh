#!/usr/bin/env bash

set -euo pipefail

# WSL Setup Script
# Fully self-contained bootstrap for fresh WSL instances
# Installs: Homebrew → stow → dotfiles → mise → tools

# ============================================================================
# INITIALIZATION
# ============================================================================

# XDG Base Directory specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Ensure ~/.local/bin is at the front of PATH
export PATH="$HOME/.local/bin:$PATH"

# Build and log directories
BUILD_DIR="$XDG_CACHE_HOME/wsl-setup/build"
LOG_DIR="$XDG_STATE_HOME/wsl-setup/logs"
LOG_FILE="$LOG_DIR/setup_$(date '+%Y%m%d_%H%M%S').log"

# Create necessary directories
mkdir -p "$BUILD_DIR" "$LOG_DIR" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$HOME/.local/bin"
touch "$LOG_FILE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log() {
    local msg="$1"
    echo -e "${BLUE}[WSL Setup]${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $msg" >> "$LOG_FILE"
}

success() {
    local msg="$1"
    echo -e "${GREEN}✓${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $msg" >> "$LOG_FILE"
}

warn() {
    local msg="$1"
    echo -e "${YELLOW}⚠${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $msg" >> "$LOG_FILE"
}

error() {
    local msg="$1"
    echo -e "${RED}✗${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $msg" >> "$LOG_FILE"
}

info() {
    local msg="$1"
    echo -e "${CYAN}→${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $msg" >> "$LOG_FILE"
}

# ============================================================================
# CLEANUP AND ERROR HANDLING
# ============================================================================

cleanup() {
    local exit_code=$?
    if [ -d "$BUILD_DIR" ]; then
        log "Cleaning up build directory..."
        rm -rf "$BUILD_DIR"
    fi
    
    if [ $exit_code -ne 0 ]; then
        error "Setup failed with exit code $exit_code"
        error "Check log file: $LOG_FILE"
    fi
    
    exit $exit_code
}

trap cleanup EXIT INT TERM ERR

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

command_exists() {
    command -v "$1" &>/dev/null
}

homebrew_installed() {
    command_exists brew
}

stow_version_check() {
    if ! command_exists stow; then
        return 1
    fi
    
    local version
    version=$(stow --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "0.0.0")
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"
    
    # Check if version >= 2.4.0
    if [ "$major" -gt 2 ] || { [ "$major" -eq 2 ] && [ "$minor" -ge 4 ]; }; then
        return 0
    fi
    return 1
}

# ============================================================================
# WSL DETECTION AND ENVIRONMENT SETUP
# ============================================================================

# Detect WSL
log "Checking WSL environment..."
if [[ -z "${WSL_DISTRO_NAME:-}" ]] && ! grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
    error "This script is intended for WSL environments only"
    exit 1
fi

success "Detected WSL environment: ${WSL_DISTRO_NAME:-Unknown}"

# Ensure we're in the dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

info "Dotfiles directory: $DOTFILES_DIR"

# Check if we're under /mnt (Windows filesystem)
if [[ "$DOTFILES_DIR" == /mnt/* ]]; then
    warn "Dotfiles are on Windows filesystem (/mnt)"
    warn "This can cause permission and symlink issues"
    warn "Consider cloning to your WSL home directory: ~/.config/dotfiles"
    read -rp "Continue anyway? (y/N) " choice
    [[ "$choice" =~ ^[Yy]$ ]] || exit 1
fi

log "XDG directories already created during initialization"
success "Environment setup complete"

echo ""

# ============================================================================
# BASE SYSTEM PACKAGES (APT)
# ============================================================================

log "Installing base system dependencies via apt..."
info "This includes: git, build-essential, curl, perl, dpkg-dev"

# Only install essential build tools via apt
BASE_PACKAGES=(
    "git"
    "build-essential"
    "curl"
    "perl"
    "dpkg-dev"
)

MISSING_BASE=()

for pkg in "${BASE_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg"; then
        MISSING_BASE+=("$pkg")
    fi
done

if [ ${#MISSING_BASE[@]} -gt 0 ]; then
    warn "Missing base packages: ${MISSING_BASE[*]}"
    log "Running apt update and installing packages..."
    sudo apt-get update
    sudo apt-get install -y "${MISSING_BASE[@]}"
    success "Base system packages installed"
else
    success "All base system packages already installed"
fi

echo ""

# ============================================================================
# HOMEBREW INSTALLATION (FOR STOW AND POTENTIAL OTHER TOOLS)
# ============================================================================

log "Checking for Homebrew..."

if homebrew_installed; then
    success "Homebrew already installed"
    info "Location: $(command -v brew)"
    # Ensure Homebrew is in PATH for this script
    eval "$(brew shellenv)"
else
    log "Installing Homebrew for Linux..."
    info "This may take several minutes..."
    
    # Install Homebrew non-interactively
    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        success "Homebrew installed successfully"
        
        # Add to PATH for current session
        if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            info "Homebrew location: /home/linuxbrew/.linuxbrew"
        elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
            eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
            info "Homebrew location: $HOME/.linuxbrew"
        fi
        
        # Verify installation
        if homebrew_installed; then
            success "Homebrew is now available in PATH"
            info "Version: $(brew --version | head -n1)"
        else
            error "Homebrew installed but not found in PATH"
            exit 1
        fi
    else
        error "Failed to install Homebrew"
        error "You may need to install it manually: https://brew.sh"
        exit 1
    fi
fi

echo ""

# ============================================================================
# GNU STOW INSTALLATION
# ============================================================================

log "Checking for GNU Stow..."

if stow_version_check; then
    success "GNU Stow already installed with compatible version"
    info "Version: $(stow --version | head -n1)"
else
    if command_exists stow; then
        warn "Stow is installed but version is too old (need >= 2.4.0)"
        warn "Current version: $(stow --version | head -n1 || echo 'unknown')"
    else
        info "Stow not found"
    fi
    
    # Try Homebrew first
    log "Attempting to install stow via Homebrew..."
    if homebrew_installed && brew install stow; then
        success "Stow installed via Homebrew"
        
        if stow_version_check; then
            success "Stow version check passed"
            info "Version: $(stow --version | head -n1)"
        else
            warn "Homebrew stow version may be outdated, will build from source"
            brew unlink stow 2>/dev/null || true
        fi
    else
        warn "Failed to install stow via Homebrew"
    fi
    
    # Fallback: Build from source if Homebrew failed or version still wrong
    if ! stow_version_check; then
        log "Building GNU Stow from source..."
        info "This ensures XDG compliance and latest features"
        
        # Set up Perl environment for XDG compliance
        export PERL_HOMEDIR="${XDG_DATA_HOME}/perl5"
        export PERL_MM_OPT="INSTALL_BASE=$PERL_HOMEDIR"
        export PERL_MB_OPT="--install_base $PERL_HOMEDIR"
        export PERL5LIB="$PERL_HOMEDIR/lib/perl5"
        
        mkdir -p "$PERL_HOMEDIR" "$BUILD_DIR/stow"
        cd "$BUILD_DIR/stow"
        
        log "Downloading stow source..."
        if curl -L https://ftp.gnu.org/gnu/stow/stow-2.4.2.tar.gz | tar xz; then
            cd stow-2.4.2
            
            log "Configuring stow..."
            ./configure --prefix="$HOME/.local" \
                --datarootdir="$XDG_DATA_HOME" \
                --sysconfdir="$XDG_CONFIG_HOME" >> "$LOG_FILE" 2>&1
            
            log "Building stow..."
            if make >> "$LOG_FILE" 2>&1; then
                log "Installing stow..."
                if make install >> "$LOG_FILE" 2>&1; then
                    success "Stow built and installed from source"
                    
                    # Verify installation
                    export PATH="$HOME/.local/bin:$PATH"
                    if stow_version_check; then
                        success "Stow is now available and meets version requirements"
                        info "Version: $(stow --version | head -n1)"
                    else
                        error "Stow built but version check failed"
                        exit 1
                    fi
                else
                    error "Failed to install stow"
                    error "Check log: $LOG_FILE"
                    exit 1
                fi
            else
                error "Failed to build stow"
                error "Check log: $LOG_FILE"
                exit 1
            fi
        else
            error "Failed to download stow source"
            exit 1
        fi
        
        cd "$DOTFILES_DIR"
    fi
fi

echo ""

# ============================================================================
# DOTFILES STOWING
# ============================================================================

log "Stowing dotfiles with GNU Stow..."

# Windows/PowerShell packages to exclude on WSL/Linux
BLACKLIST=(
    "windows"
    "powershell"
)

# Build list of packages to stow (exclude blacklisted ones)
STOWABLE_PACKAGES=()
SKIPPED_PACKAGES=()

for dir in "$DOTFILES_DIR"*/; do
    if [ -d "$dir" ]; then
        pkg=$(basename "$dir")
        
        # Check if package is blacklisted
        skip_package=false
        for blacklisted in "${BLACKLIST[@]}"; do
            if [[ "$pkg" == *"$blacklisted"* ]]; then
                skip_package=true
                break
            fi
        done
        
        if [ "$skip_package" = true ]; then
            SKIPPED_PACKAGES+=("$pkg")
        else
            STOWABLE_PACKAGES+=("$pkg")
        fi
    fi
done

info "Packages to stow: ${STOWABLE_PACKAGES[*]}"
if [ ${#SKIPPED_PACKAGES[@]} -gt 0 ]; then
    info "Skipped (blacklisted): ${SKIPPED_PACKAGES[*]}"
fi

# Perform dry run to check for conflicts
log "Running stow dry-run to check for conflicts..."
CONFLICT_OUTPUT=$(stow -n -v --dotfiles --no-folding -d "$DOTFILES_DIR" -t "$HOME" "${STOWABLE_PACKAGES[@]}" 2>&1 || true)

if echo "$CONFLICT_OUTPUT" | grep -q "existing target is neither a link nor a directory"; then
    warn "Found conflicting files that would be overwritten:"
    echo "$CONFLICT_OUTPUT" | grep "existing target is neither a link nor a directory" || true
    echo ""
    echo "Options:"
    echo "  1) Adopt existing files into the dotfiles repo (recommended)"
    echo "  2) Skip stowing and resolve conflicts manually"
    echo "  3) Abort setup"
    echo ""
    read -rp "Choose option [1/2/3]: " choice
    
    case "$choice" in
        1)
            log "Adopting conflicting files with --adopt flag..."
            if stow --adopt --dotfiles --no-folding -d "$DOTFILES_DIR" -t "$HOME" "${STOWABLE_PACKAGES[@]}"; then
                success "Files adopted into dotfiles repository"
                warn "Please review changes with 'git status' and 'git diff' in $DOTFILES_DIR"
                warn "Commit the changes if you're happy with them"
            else
                error "Failed to adopt files"
                exit 1
            fi
            ;;
        2)
            warn "Skipping stow operation"
            warn "Please resolve conflicts manually and re-run this script"
            exit 1
            ;;
        3|*)
            error "Setup aborted by user"
            exit 1
            ;;
    esac
else
    # No conflicts, proceed with normal stowing
    log "No conflicts detected, proceeding with stow..."
    if stow --dotfiles --no-folding -d "$DOTFILES_DIR" -t "$HOME" "${STOWABLE_PACKAGES[@]}"; then
        success "Dotfiles stowed successfully"
    else
        error "Failed to stow dotfiles"
        exit 1
    fi
fi

echo ""

# ============================================================================
# MISE VERSION MANAGER INSTALLATION
# ============================================================================

log "Setting up mise version manager..."

# Set up mise XDG directories
export MISE_DATA_DIR="${XDG_DATA_HOME}/mise"
export MISE_CONFIG_DIR="${XDG_CONFIG_HOME}/mise"
export MISE_CACHE_DIR="${XDG_CACHE_HOME}/mise"
export MISE_STATE_DIR="${XDG_STATE_HOME}/mise"

if command_exists mise; then
    success "mise already installed"
    info "Version: $(mise --version)"
    
    # Update mise
    log "Updating mise..."
    mise self-update || warn "Could not auto-update mise"
else
    log "Installing mise..."
    info "This will download and install mise to ~/.local/bin"
    
    mkdir -p "$MISE_DATA_DIR" "$MISE_CONFIG_DIR" "$MISE_CACHE_DIR" "$MISE_STATE_DIR"
    
    if curl https://mise.run | sh; then
        success "mise installed successfully"
        
        # Ensure mise is in PATH
        export PATH="$HOME/.local/bin:$PATH"
        
        if command_exists mise; then
            success "mise is now available"
            info "Version: $(mise --version)"
        else
            error "mise installed but not found in PATH"
            exit 1
        fi
    else
        error "Failed to install mise"
        exit 1
    fi
fi

# Trust the dotfiles mise config (now that configs are stowed)
if [ -f "$MISE_CONFIG_DIR/config.toml" ]; then
    log "Trusting mise config..."
    mise trust "$MISE_CONFIG_DIR/config.toml" 2>/dev/null || true
    
    # Install tools from config
    log "Installing tools from mise config.toml..."
    info "This may take several minutes depending on which tools need to be installed"
    
    if mise install; then
        success "Tools installed successfully"
        
        # List installed tools
        info "Installed tools:"
        mise list || true
    else
        warn "Some mise tools may have failed to install"
        warn "You can retry later with: mise install"
    fi
else
    warn "No mise config.toml found at $MISE_CONFIG_DIR"
    info "Tools will need to be installed manually with mise"
fi

echo ""

# ============================================================================
# 1PASSWORD SSH AGENT INTEGRATION
# ============================================================================

log "Setting up 1Password SSH agent for WSL..."

SSH_AGENT_SOCK="/mnt/wsl/1password/agent.sock"
if [ -S "$SSH_AGENT_SOCK" ]; then
    success "1Password SSH agent socket found at $SSH_AGENT_SOCK"
    
    # Check if already configured
    if grep -q "SSH_AUTH_SOCK.*1password" "$HOME/.zshenv" 2>/dev/null; then
        info "SSH_AUTH_SOCK already configured in .zshenv"
    else
        echo "export SSH_AUTH_SOCK='$SSH_AGENT_SOCK'" >> "$HOME/.zshenv"
        success "SSH_AUTH_SOCK configured in .zshenv"
    fi
else
    warn "1Password SSH agent socket not found at $SSH_AGENT_SOCK"
    warn "Make sure 1Password desktop app is running on Windows with SSH agent enabled"
    info "Settings → Developer → SSH Agent → Enable"
fi

echo ""

# ============================================================================
# ZSH DIRECTORY PERMISSIONS FIX
# ============================================================================

log "Checking zsh directory permissions..."

if command_exists zsh; then
    # Get list of insecure directories
    INSECURE_DIRS=$(zsh -c 'autoload -U compinit && compaudit 2>/dev/null' || true)
    
    if [ -n "$INSECURE_DIRS" ]; then
        warn "Found insecure directories:"
        echo "$INSECURE_DIRS"
        
        read -rp "Fix permissions automatically? (Y/n) " choice
        if [[ ! "$choice" =~ ^[Nn]$ ]]; then
            echo "$INSECURE_DIRS" | while read -r dir; do
                if [ -d "$dir" ]; then
                    info "Fixing: $dir"
                    if chmod go-w "$dir" 2>/dev/null && chown "$USER:$USER" "$dir" 2>/dev/null; then
                        success "Fixed: $dir"
                    elif sudo chown "$USER:$USER" "$dir" 2>/dev/null && sudo chmod go-w "$dir" 2>/dev/null; then
                        success "Fixed: $dir (with sudo)"
                    else
                        warn "Could not fix: $dir"
                    fi
                fi
            done
        fi
    else
        success "No insecure directories found"
    fi
else
    info "zsh not yet installed (will be handled by mise)"
fi

echo ""

# ============================================================================
# INSTALLATION SUMMARY
# ============================================================================

echo "="
echo "="
log "Setup Complete!"
echo "="
echo "="
echo ""

info "Installation Summary:"
echo ""

# Base system
echo "  ${GREEN}✓${NC} Base system packages (apt)"
for pkg in git build-essential curl perl dpkg-dev; do
    echo "    - $pkg"
done
echo ""

# Homebrew
if homebrew_installed; then
    echo "  ${GREEN}✓${NC} Homebrew for Linux"
    echo "    - Location: $(command -v brew)"
    echo "    - Version: $(brew --version | head -n1)"
    echo ""
fi

# Stow
if command_exists stow; then
    echo "  ${GREEN}✓${NC} GNU Stow"
    echo "    - Version: $(stow --version | head -n1)"
    if brew list stow &>/dev/null 2>&1; then
        echo "    - Installed via: Homebrew"
    else
        echo "    - Installed via: Built from source"
    fi
    echo ""
fi

# Mise
if command_exists mise; then
    echo "  ${GREEN}✓${NC} mise version manager"
    echo "    - Version: $(mise --version)"
    if [ -f "$MISE_CONFIG_DIR/config.toml" ]; then
        echo "    - Tools: $(mise list 2>/dev/null | wc -l) installed"
    fi
    echo ""
fi

# Dotfiles
echo "  ${GREEN}✓${NC} Dotfiles stowed"
echo "    - Location: $DOTFILES_DIR"
echo "    - Packages: ${#STOWABLE_PACKAGES[@]} stowed"
if [ ${#SKIPPED_PACKAGES[@]} -gt 0 ]; then
    echo "    - Skipped: ${SKIPPED_PACKAGES[*]}"
fi
echo ""

# PATH
info "PATH components:"
echo "  - ~/.local/bin (for stow, mise, tools)"
if homebrew_installed; then
    echo "  - Homebrew bin directory"
fi
echo ""

# Logs
info "Log file saved to:"
echo "  $LOG_FILE"
echo ""

# ============================================================================
# NEXT STEPS
# ============================================================================

echo "="
log "Next Steps:"
echo "="
echo ""
echo "  1. ${CYAN}Restart your shell${NC}"
echo "     $ exec zsh"
echo ""
echo "  2. ${CYAN}Test SSH agent (if using 1Password)${NC}"
echo "     $ ssh -T git@github.com"
echo ""
echo "  3. ${CYAN}Verify installation${NC}"
if [ -f "$DOTFILES_DIR/verify.sh" ]; then
    echo "     $ cd $DOTFILES_DIR && ./verify.sh"
else
    echo "     $ mise doctor"
    echo "     $ stow --version"
fi
echo ""
echo "  4. ${CYAN}Configure Windows Terminal${NC}"
echo "     - Install a Nerd Font on Windows"
echo "     - Set it in Windows Terminal settings"
echo ""
echo "  5. ${CYAN}Review and commit any adopted dotfiles${NC}"
if git -C "$DOTFILES_DIR" status --porcelain 2>/dev/null | grep -q '^'; then
    warn "You have uncommitted changes in dotfiles:"
    echo "     $ cd $DOTFILES_DIR"
    echo "     $ git status"
    echo "     $ git diff"
    echo "     $ git add . && git commit -m 'Adopt local configs'"
    echo ""
fi

info "For more information:"
echo "  - README: $DOTFILES_DIR/README.md"
echo "  - mise docs: https://mise.jdx.dev"
echo "  - stow docs: https://www.gnu.org/software/stow/"
echo ""

success "WSL setup completed successfully!"
echo ""
