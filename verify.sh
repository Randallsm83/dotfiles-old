#!/usr/bin/env bash
#
# Verify Linux/macOS dotfiles installation
#
# Checks that all dotfiles are properly installed:
# - Symlinks exist and point to correct targets
# - Package managers are available
# - Core and optional tools are present
# - Config files have correct content
# - Shell configuration is working
# - mise/environment variables are set

set -euo pipefail

# ================================================================================================
# Script Variables
# ================================================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$SCRIPT_DIR"

# XDG Base Directories
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Counters
PASSED=0
FAILED=0
WARNINGS=0
SKIPPED=0

# Options
DETAILED=false
INCLUDE_OPTIONAL=false

# ================================================================================================
# Color/Symbol Setup
# ================================================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    GRAY='\033[0;90m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    GRAY=''
    NC=''
fi

# ================================================================================================
# Helper Functions
# ================================================================================================

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Verify dotfiles installation

OPTIONS:
    -d, --detailed          Show detailed information for each check
    -o, --optional          Check optional tools
    -h, --help             Show this help message

EXAMPLES:
    $(basename "$0")                Run basic verification
    $(basename "$0") -d -o          Verify with detailed output including optional tools
EOF
}

write_status() {
    local message="$1"
    local type="${2:-info}"
    
    local symbol color
    case "$type" in
        pass)
            symbol="✓"
            color="$GREEN"
            ((PASSED++))
            ;;
        fail)
            symbol="✗"
            color="$RED"
            ((FAILED++))
            ;;
        warning)
            symbol="⚠"
            color="$YELLOW"
            ((WARNINGS++))
            ;;
        skip)
            symbol="○"
            color="$GRAY"
            ((SKIPPED++))
            ;;
        info)
            symbol="ℹ"
            color="$CYAN"
            ;;
    esac
    
    echo -e "${color}${symbol}${NC} ${message}"
}

detail() {
    if [[ "$DETAILED" == true ]]; then
        echo -e "    ${GRAY}$1${NC}"
    fi
}

test_symlink() {
    local path="$1"
    local expected_target="$2"
    local description="${3:-$(basename "$path")}"
    
    if [[ ! -e "$path" ]] && [[ ! -L "$path" ]]; then
        write_status "$description - Link does not exist" fail
        detail "Expected: $path"
        return 1
    fi
    
    if [[ ! -L "$path" ]]; then
        write_status "$description - Not a symlink (regular file/directory)" warning
        detail "Path: $path"
        return 1
    fi
    
    local actual_target
    actual_target="$(readlink "$path")"
    
    # Normalize paths for comparison
    local expected_norm actual_norm
    expected_norm="$(cd "$(dirname "$expected_target")" 2>/dev/null && pwd)/$(basename "$expected_target")" || expected_norm="$expected_target"
    actual_norm="$(cd "$(dirname "$actual_target")" 2>/dev/null && pwd)/$(basename "$actual_target")" || actual_norm="$actual_target"
    
    if [[ "$actual_norm" != "$expected_norm" ]]; then
        write_status "$description - Points to wrong target" fail
        detail "Expected: $expected_norm"
        detail "Actual:   $actual_norm"
        return 1
    fi
    
    write_status "$description" pass
    detail "Target: $actual_target"
    return 0
}

test_command() {
    local command="$1"
    local description="${2:-$command}"
    local optional="${3:-false}"
    
    if command -v "$command" &>/dev/null; then
        local version=""
        if version=$(${command} --version 2>/dev/null | head -n1); then
            write_status "$description" pass
            detail "Version: $version"
        else
            write_status "$description" pass
        fi
        return 0
    fi
    
    if [[ "$optional" == true ]]; then
        write_status "$description - Not installed (optional)" skip
    else
        write_status "$description - Not installed" fail
    fi
    return 1
}

test_file_content() {
    local path="$1"
    local pattern="$2"
    local description="${3:-$(basename "$path")}"
    
    if [[ ! -f "$path" ]]; then
        write_status "$description - File does not exist" fail
        return 1
    fi
    
    if grep -q "$pattern" "$path" 2>/dev/null; then
        write_status "$description - Contains expected content" pass
        detail "Pattern: $pattern"
        return 0
    fi
    
    write_status "$description - Missing expected content" fail
    detail "Pattern: $pattern"
    detail "File: $path"
    return 1
}

test_env_var() {
    local var_name="$1"
    local expected_value="$2"
    local description="${3:-$var_name}"
    
    local actual_value="${!var_name:-}"
    
    if [[ "$actual_value" == "$expected_value" ]]; then
        write_status "$description" pass
        detail "Value: $actual_value"
        return 0
    fi
    
    write_status "$description - Not set or incorrect" warning
    detail "Expected: $expected_value"
    detail "Actual:   $actual_value"
    return 1
}

# ================================================================================================
# Verification Checks
# ================================================================================================

test_environment() {
    echo -e "\n${CYAN}=== Environment ===${NC}"
    
    # XDG directories - check both env var and directory existence
    test_env_var "XDG_CONFIG_HOME" "$HOME/.config" "XDG_CONFIG_HOME" || true
    [[ -d "$XDG_CONFIG_HOME" ]] && write_status "  Directory exists: ~/.config" pass || write_status "  Directory missing: ~/.config" warning
    
    test_env_var "XDG_DATA_HOME" "$HOME/.local/share" "XDG_DATA_HOME" || true
    [[ -d "$XDG_DATA_HOME" ]] && write_status "  Directory exists: ~/.local/share" pass || write_status "  Directory missing: ~/.local/share" warning
    
    test_env_var "XDG_STATE_HOME" "$HOME/.local/state" "XDG_STATE_HOME" || true
    [[ -d "$XDG_STATE_HOME" ]] && write_status "  Directory exists: ~/.local/state" pass || write_status "  Directory missing: ~/.local/state" warning
    
    test_env_var "XDG_CACHE_HOME" "$HOME/.cache" "XDG_CACHE_HOME" || true
    [[ -d "$XDG_CACHE_HOME" ]] && write_status "  Directory exists: ~/.cache" pass || write_status "  Directory missing: ~/.cache" warning
    
    # Check ~/bin or ~/.local/bin in PATH
    if [[ ":$PATH:" == *":$HOME/bin:"* ]] || [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
        write_status "~/bin or ~/.local/bin in PATH" pass
    else
        write_status "~/bin or ~/.local/bin not in PATH" warning
    fi
    
    # Check SHELL
    if [[ -n "${SHELL:-}" ]]; then
        write_status "SHELL set to: $SHELL" pass
        detail "Shell: $(basename "$SHELL")"
    else
        write_status "SHELL not set" warning
    fi
}

test_package_managers() {
    echo -e "\n${CYAN}=== Package Managers ===${NC}"
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        test_command "brew" "Homebrew" false
    else
        # On Linux, package managers are more varied
        if command -v apt-get &>/dev/null; then
            write_status "apt (system package manager)" pass
        elif command -v dnf &>/dev/null; then
            write_status "dnf (system package manager)" pass
        elif command -v pacman &>/dev/null; then
            write_status "pacman (system package manager)" pass
        else
            write_status "No recognized system package manager" warning
        fi
    fi
    
    # mise for version management
    test_command "mise" "mise (version manager)" true
}

test_core_tools() {
    echo -e "\n${CYAN}=== Core Tools ===${NC}"
    
    test_command "git" "Git" false
    test_command "stow" "GNU Stow" false
    test_command "zsh" "Zsh" true
    test_command "bash" "Bash" false
    test_command "nvim" "Neovim" true
    test_command "starship" "Starship Prompt" true
}

test_optional_tools() {
    if [[ "$INCLUDE_OPTIONAL" != true ]]; then
        return
    fi
    
    echo -e "\n${CYAN}=== Optional Tools ===${NC}"
    
    test_command "rg" "ripgrep" true
    test_command "fd" "fd" true
    test_command "fzf" "fzf" true
    test_command "bat" "bat" true
    test_command "eza" "eza" true
    test_command "delta" "delta (git diff)" true
    test_command "lazygit" "lazygit" true
    test_command "btop" "btop" true
    test_command "node" "Node.js" true
    test_command "npm" "npm" true
    test_command "python3" "Python 3" true
}

test_config_links() {
    echo -e "\n${CYAN}=== Configuration Links ===${NC}"
    
    # Git config
    if [[ -f "$DOTFILES_ROOT/git/dot-config/git/config" ]]; then
        test_symlink "$XDG_CONFIG_HOME/git/config" \
                     "$DOTFILES_ROOT/git/dot-config/git/config" \
                     "Git config"
    fi
    
    # Zsh
    if [[ -f "$DOTFILES_ROOT/zsh/dot-config/zsh/.zshrc" ]]; then
        test_symlink "$XDG_CONFIG_HOME/zsh/.zshrc" \
                     "$DOTFILES_ROOT/zsh/dot-config/zsh/.zshrc" \
                     "Zsh config"
    fi
    
    # Neovim
    if [[ -f "$DOTFILES_ROOT/nvim/dot-config/nvim/init.lua" ]]; then
        test_symlink "$XDG_CONFIG_HOME/nvim/init.lua" \
                     "$DOTFILES_ROOT/nvim/dot-config/nvim/init.lua" \
                     "Neovim init.lua"
    fi
    
    # Starship
    if [[ -f "$DOTFILES_ROOT/starship/dot-config/starship.toml" ]]; then
        test_symlink "$XDG_CONFIG_HOME/starship.toml" \
                     "$DOTFILES_ROOT/starship/dot-config/starship.toml" \
                     "Starship config"
    fi
    
    # WezTerm
    if [[ -f "$DOTFILES_ROOT/wezterm/dot-config/wezterm/wezterm.lua" ]]; then
        test_symlink "$XDG_CONFIG_HOME/wezterm/wezterm.lua" \
                     "$DOTFILES_ROOT/wezterm/dot-config/wezterm/wezterm.lua" \
                     "WezTerm config"
    fi
    
    # Bat
    if [[ -f "$DOTFILES_ROOT/bat/dot-config/bat/config" ]]; then
        test_symlink "$XDG_CONFIG_HOME/bat/config" \
                     "$DOTFILES_ROOT/bat/dot-config/bat/config" \
                     "Bat config"
    fi
    
    # mise
    if [[ -f "$DOTFILES_ROOT/mise/dot-config/mise/config.toml" ]]; then
        test_symlink "$XDG_CONFIG_HOME/mise/config.toml" \
                     "$DOTFILES_ROOT/mise/dot-config/mise/config.toml" \
                     "mise config"
    fi
}

test_config_content() {
    echo -e "\n${CYAN}=== Configuration Content ===${NC}"
    
    # Check if git is available
    if ! command -v git &>/dev/null; then
        write_status "Git not installed - skipping config checks" skip
        return
    fi
    
    # Verify git user is set
    if git config user.name &>/dev/null && git config user.email &>/dev/null; then
        write_status "Git user configured ($(git config user.name))" pass
        detail "Email: $(git config user.email)"
    else
        write_status "Git user not configured" warning
    fi
    
    # Check starship in shell config
    if [[ -f "$HOME/.zshrc" ]]; then
        test_file_content "$HOME/.zshrc" "starship" "Zsh loads Starship"
    elif [[ -f "$XDG_CONFIG_HOME/zsh/.zshrc" ]]; then
        test_file_content "$XDG_CONFIG_HOME/zsh/.zshrc" "starship" "Zsh loads Starship"
    fi
    
    # Check mise activation in shell
    if [[ -f "$HOME/.zshrc" ]] || [[ -f "$XDG_CONFIG_HOME/zsh/.zshrc" ]]; then
        local zshrc_file="${HOME}/.zshrc"
        [[ -f "$XDG_CONFIG_HOME/zsh/.zshrc" ]] && zshrc_file="$XDG_CONFIG_HOME/zsh/.zshrc"
        
        if grep -q "mise activate" "$zshrc_file" 2>/dev/null || \
           grep -q 'eval "$(mise activate' "$zshrc_file" 2>/dev/null; then
            write_status "Zsh activates mise" pass
        else
            write_status "Zsh doesn't activate mise" warning
        fi
    fi
}

test_shell_integration() {
    echo -e "\n${CYAN}=== Shell Integration ===${NC}"
    
    # Check if running in zsh
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        write_status "Running in Zsh" pass
        detail "Version: $ZSH_VERSION"
        
        # Check for insecure directories
        if command -v compaudit &>/dev/null; then
            local insecure
            insecure="$(compaudit 2>/dev/null || true)"
            if [[ -z "$insecure" ]]; then
                write_status "No insecure completion directories" pass
            else
                write_status "Insecure completion directories found" warning
                if [[ "$DETAILED" == true ]]; then
                    echo "$insecure" | while read -r dir; do
                        detail "Insecure: $dir"
                    done
                fi
            fi
        fi
    else
        write_status "Not running in Zsh (current: $SHELL)" info
    fi
    
    # Check fzf integration
    if command -v fzf &>/dev/null; then
        write_status "fzf available" pass
        
        # Check for fzf key bindings
        if [[ -f "$HOME/.fzf.zsh" ]] || [[ -f "$XDG_CONFIG_HOME/fzf/fzf.zsh" ]]; then
            write_status "  fzf key bindings configured" pass
        fi
    fi
}

test_fonts() {
    echo -e "\n${CYAN}=== Fonts ===${NC}"
    
    # On Linux, checking fonts is more complex and system-dependent
    if command -v fc-list &>/dev/null; then
        # Check for common Nerd Fonts
        local fonts=("FiraCode" "CascadiaCode" "JetBrainsMono" "Meslo" "Hack")
        local found=0
        
        for font in "${fonts[@]}"; do
            if fc-list | grep -qi "$font"; then
                write_status "$font Nerd Font" pass
                ((found++))
            fi
        done
        
        if [[ $found -eq 0 ]]; then
            write_status "No Nerd Fonts detected (optional)" warning
            detail "Install via: https://www.nerdfonts.com/"
        fi
    else
        write_status "fontconfig not available - skipping font checks" skip
    fi
}

test_mise_setup() {
    echo -e "\n${CYAN}=== mise Setup ===${NC}"
    
    if ! command -v mise &>/dev/null; then
        write_status "mise not installed" skip
        return
    fi
    
    write_status "mise installed: $(mise --version)" pass
    
    # Check mise env vars
    if [[ -n "${MISE_DATA_DIR:-}" ]]; then
        test_env_var "MISE_DATA_DIR" "$XDG_DATA_HOME/mise" "MISE_DATA_DIR"
    fi
    
    # Check mise tools from config
    if [[ -f "$XDG_CONFIG_HOME/mise/config.toml" ]]; then
        write_status "mise config.toml exists" pass
        
        # Try to list installed tools
        if mise list &>/dev/null; then
            local tool_count
            tool_count=$(mise list 2>/dev/null | wc -l)
            write_status "  Installed tools: $tool_count" pass
            if [[ "$DETAILED" == true ]]; then
                mise list 2>/dev/null | while read -r line; do
                    detail "$line"
                done
            fi
        fi
    else
        write_status "mise config.toml not found" warning
    fi
}

# ================================================================================================
# Main Execution
# ================================================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--detailed)
                DETAILED=true
                shift
                ;;
            -o|--optional)
                INCLUDE_OPTIONAL=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    echo -e "\n${CYAN}========================================${NC}"
    echo -e " ${NC}Dotfiles Verification${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    echo -e "${GRAY}Dotfiles: $DOTFILES_ROOT${NC}"
    echo -e "${GRAY}OS: $OSTYPE${NC}"
    echo ""
    
    # Run all checks
    test_environment
    test_package_managers
    test_core_tools
    test_optional_tools
    test_config_links
    test_config_content
    test_shell_integration
    test_mise_setup
    test_fonts
    
    # Summary
    echo -e "\n${CYAN}========================================${NC}"
    echo -e " ${NC}Summary${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    local total=$((PASSED + FAILED + WARNINGS + SKIPPED))
    
    echo -e "Passed:   ${GREEN}$PASSED${NC}"
    echo -e "Failed:   ${RED}$FAILED${NC}"
    echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
    echo -e "Skipped:  ${GRAY}$SKIPPED${NC}"
    echo -e "Total:    $total\n"
    
    if [[ $FAILED -gt 0 ]]; then
        echo -e "${RED}Some checks failed. Review the output above.${NC}"
        echo -e "${YELLOW}Run with --detailed for more information.${NC}\n"
        exit 1
    elif [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}All critical checks passed, but there are warnings.${NC}"
        echo -e "${YELLOW}Run with --detailed for more information.${NC}\n"
        exit 0
    else
        echo -e "${GREEN}All checks passed! Your dotfiles are properly configured.${NC}"
        exit 0
    fi
}

main "$@"
