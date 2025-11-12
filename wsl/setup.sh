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

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Check if package is installed (distro-agnostic)
package_installed() {
    local pkg="$1"
    local distro="$2"
    
    case "$distro" in
        arch|manjaro)
            pacman -Q "$pkg" &>/dev/null
            ;;
        ubuntu|debian|pop)
            dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
            ;;
        fedora|rhel|centos)
            rpm -q "$pkg" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Install packages (distro-agnostic)
install_packages() {
    local distro="$1"
    shift
    local packages=("$@")
    
    case "$distro" in
        arch|manjaro)
            log "Installing packages via pacman..."
            sudo pacman -Sy --noconfirm "${packages[@]}"
            ;;
        ubuntu|debian|pop)
            log "Installing packages via apt..."
            sudo apt-get update
            sudo apt-get install -y "${packages[@]}"
            ;;
        fedora|rhel|centos)
            log "Installing packages via dnf/yum..."
            if command_exists dnf; then
                sudo dnf install -y "${packages[@]}"
            else
                sudo yum install -y "${packages[@]}"
            fi
            ;;
        *)
            error "Unsupported distribution: $distro"
            return 1
            ;;
    esac
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
# DISTRIBUTION DETECTION
# ============================================================================

DISTRO=$(detect_distro)
log "Detected distribution: $DISTRO"

case "$DISTRO" in
    arch|manjaro)
        info "Using pacman package manager"
        ;;
    ubuntu|debian|pop)
        info "Using apt package manager"
        ;;
    fedora|rhel|centos)
        info "Using dnf/yum package manager"
        ;;
    *)
        warn "Unknown distribution, will attempt to continue"
        ;;
esac

echo ""

# ============================================================================
# SYSTEM UPGRADE (OPTIONAL)
# ============================================================================

log "Checking for system updates..."

# Check if user has sudo access
if sudo -n true 2>/dev/null; then
    info "Sudo access available (passwordless)"
    PERFORM_UPGRADE=true
else
    warn "Passwordless sudo not available"
    read -rp "Enter sudo password to upgrade system packages? (y/N) " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        # Verify sudo access with password
        if sudo -v; then
            info "Sudo access granted"
            PERFORM_UPGRADE=true
        else
            warn "Sudo authentication failed"
            PERFORM_UPGRADE=false
        fi
    else
        info "Skipping system upgrade"
        PERFORM_UPGRADE=false
    fi
fi

if [ "$PERFORM_UPGRADE" = true ]; then
    case "$DISTRO" in
        arch|manjaro)
            log "Upgrading system packages via pacman..."
            if sudo pacman -Syu --noconfirm >> "$LOG_FILE" 2>&1; then
                success "System packages upgraded"
            else
                warn "System upgrade failed or was partially completed"
            fi
            ;;
        ubuntu|debian|pop)
            log "Upgrading system packages via apt..."
            if sudo apt-get update >> "$LOG_FILE" 2>&1 && sudo apt-get upgrade -y >> "$LOG_FILE" 2>&1; then
                success "System packages upgraded"
            else
                warn "System upgrade failed or was partially completed"
            fi
            ;;
        fedora|rhel|centos)
            log "Upgrading system packages via dnf/yum..."
            if command_exists dnf; then
                if sudo dnf upgrade -y >> "$LOG_FILE" 2>&1; then
                    success "System packages upgraded"
                else
                    warn "System upgrade failed or was partially completed"
                fi
            else
                if sudo yum update -y >> "$LOG_FILE" 2>&1; then
                    success "System packages upgraded"
                else
                    warn "System upgrade failed or was partially completed"
                fi
            fi
            ;;
        *)
            info "Skipping system upgrade for unknown distribution"
            ;;
    esac
else
    info "System upgrade skipped"
fi

echo ""

# ============================================================================
# BASE SYSTEM PACKAGES
# ============================================================================

log "Installing base system dependencies..."

# Define base packages per distribution
case "$DISTRO" in
    arch|manjaro)
        BASE_PACKAGES=(
            "git"
            "base-devel"
            "curl"
            "perl"
            "less"
            "vim"
        )
        info "Packages: ${BASE_PACKAGES[*]}"
        ;;
    ubuntu|debian|pop)
        BASE_PACKAGES=(
            "git"
            "dpkg-dev"
            "build-essential"
            "curl"
            "perl"
    		"less"
        )
        info "Packages: ${BASE_PACKAGES[*]}"
        ;;
    fedora|rhel|centos)
        BASE_PACKAGES=(
            "git"
            "gcc"
            "gcc-c++"
            "make"
            "curl"
            "perl"
    		"less"
        )
        info "Packages: ${BASE_PACKAGES[*]}"
        ;;
    *)
        error "Cannot determine base packages for distribution: $DISTRO"
        exit 1
        ;;
esac

MISSING_BASE=()

for pkg in "${BASE_PACKAGES[@]}"; do
    if ! package_installed "$pkg" "$DISTRO"; then
        MISSING_BASE+=("$pkg")
    fi
done

if [ ${#MISSING_BASE[@]} -gt 0 ]; then
    warn "Missing base packages: ${MISSING_BASE[*]}"
    if install_packages "$DISTRO" "${MISSING_BASE[@]}"; then
        success "Base system packages installed"
    else
        error "Failed to install base packages"
        exit 1
    fi
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
    info "Installing to user directory: $HOME/.linuxbrew"
    
    # Install Homebrew non-interactively to user's home directory
    if NONINTERACTIVE=1 HOMEBREW_PREFIX="$HOME/.linuxbrew" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        success "Homebrew installed successfully"
        
        # Add to PATH for current session (prioritize user installation)
        if [ -x "$HOME/.linuxbrew/bin/brew" ]; then
            eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
            info "Homebrew location: $HOME/.linuxbrew"
        elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            info "Homebrew location: /home/linuxbrew/.linuxbrew"
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

# Change to dotfiles directory first to ensure glob works correctly
cd "$DOTFILES_DIR"

for dir in */; do
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
# ZSH INSTALLATION
# ============================================================================

log "Installing zsh shell..."

if command_exists zsh; then
    success "zsh already installed"
    info "Version: $(zsh --version)"
else
    log "Installing zsh via pacman..."
    
    case "$DISTRO" in
        arch|manjaro)
            if sudo pacman -S --noconfirm zsh; then
                success "zsh installed successfully"
                info "Version: $(zsh --version)"
            else
                error "Failed to install zsh"
                exit 1
            fi
            ;;
        ubuntu|debian|pop)
            if sudo apt-get install -y zsh; then
                success "zsh installed successfully"
                info "Version: $(zsh --version)"
            else
                error "Failed to install zsh"
                exit 1
            fi
            ;;
        fedora|rhel|centos)
            if command_exists dnf; then
                if sudo dnf install -y zsh; then
                    success "zsh installed successfully"
                    info "Version: $(zsh --version)"
                else
                    error "Failed to install zsh"
                    exit 1
                fi
            else
                if sudo yum install -y zsh; then
                    success "zsh installed successfully"
                    info "Version: $(zsh --version)"
                else
                    error "Failed to install zsh"
                    exit 1
                fi
            fi
            ;;
        *)
            warn "Unknown distribution, attempting to install zsh via pacman..."
            if sudo pacman -S --noconfirm zsh 2>/dev/null || \
               sudo apt-get install -y zsh 2>/dev/null || \
               sudo dnf install -y zsh 2>/dev/null || \
               sudo yum install -y zsh 2>/dev/null; then
                success "zsh installed successfully"
                info "Version: $(zsh --version)"
            else
                error "Failed to install zsh - please install manually"
                exit 1
            fi
            ;;
    esac
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
    info "Note: zsh is already installed via system package manager and will be skipped"
    
    # Run mise install, ignoring zsh errors since it's installed via pacman
    if mise install 2>&1 | grep -v "zsh not found in mise tool registry"; then
        success "Tools installed successfully"
        
        # List installed tools
        info "Installed tools:"
        mise list || true
    else
        warn "Some mise tools may have failed to install"
        warn "You can retry later with: mise install"
        info "Note: zsh errors can be ignored as it's installed via pacman"
    fi
else
    warn "No mise config.toml found at $MISE_CONFIG_DIR"
    info "Tools will need to be installed manually with mise"
fi

echo ""

# ============================================================================
# 1PASSWORD SSH AGENT INTEGRATION (WSL)
# ============================================================================

log "Setting up 1Password SSH agent for WSL..."
info "Using official WSL integration: https://developer.1password.com/docs/ssh/integrations/wsl"

# Check if ssh.exe is available (Windows OpenSSH)
if command -v ssh.exe &>/dev/null; then
    log "Testing 1Password SSH agent via ssh.exe..."
    
    # Test if 1Password SSH agent is accessible from WSL
    if ssh-add.exe -l &>/dev/null; then
        KEY_COUNT=$(ssh-add.exe -l 2>/dev/null | wc -l)
        success "1Password SSH agent is accessible from WSL"
        info "Found $KEY_COUNT SSH key(s) in 1Password"
        
        # Configure Git to use ssh.exe globally
        log "Configuring Git to use ssh.exe for SSH operations..."
        git config --global core.sshCommand "ssh.exe"
        success "Git configured to use Windows SSH (ssh.exe)"
        
        info "SSH requests from WSL will now be handled by Windows ssh.exe"
        info "This allows 1Password SSH agent integration without additional setup"
        info ""
        info "To sign Git commits with SSH:"
        info "  1. Open 1Password on Windows"
        info "  2. Select your SSH key → ⋯ → Configure Commit Signing"
        info "  3. Check 'Configure for WSL' and copy the snippet"
        info "  4. Paste into your ~/.gitconfig"
    else
        warn "1Password SSH agent not accessible from WSL"
        warn "Make sure:"
        warn "  1. 1Password is running on Windows"
        warn "  2. SSH agent is enabled: Settings → Developer → Use the SSH agent"
        warn "  3. You have SSH keys stored in 1Password"
        
        info "You can test with: ssh-add.exe -l"
    fi
else
    warn "ssh.exe not found - Windows OpenSSH may not be installed"
    warn "Install OpenSSH on Windows to use 1Password SSH agent with WSL"
    info "Settings → Apps → Optional Features → Add OpenSSH Client"
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
    warn "zsh should have been installed earlier in this script"
    warn "Please install zsh manually: sudo pacman -S zsh (or equivalent for your distro)"
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
