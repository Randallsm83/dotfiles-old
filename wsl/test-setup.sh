#!/usr/bin/env bash

# Test script for wsl/setup.sh
# Validates logic and functions without making changes

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++))
}

info() {
    echo -e "${BLUE}→${NC} $1"
}

section() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Change to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_SCRIPT="$SCRIPT_DIR/setup.sh"

section "Setup Script Validation Tests"

# Test 1: Script exists
info "Checking if setup.sh exists..."
if [ -f "$SETUP_SCRIPT" ]; then
    pass "setup.sh found at $SETUP_SCRIPT"
else
    fail "setup.sh not found at $SETUP_SCRIPT"
    exit 1
fi

# Test 2: Script is executable
info "Checking if setup.sh is executable..."
if [ -x "$SETUP_SCRIPT" ]; then
    pass "setup.sh is executable"
else
    fail "setup.sh is not executable"
    info "Fix with: chmod +x $SETUP_SCRIPT"
fi

# Test 3: Bash syntax check
info "Checking bash syntax..."
if bash -n "$SETUP_SCRIPT" 2>/dev/null; then
    pass "No syntax errors found"
else
    fail "Syntax errors detected"
    bash -n "$SETUP_SCRIPT"
    exit 1
fi

# Test 4: Shellcheck (if available)
info "Running shellcheck (if available)..."
if command -v shellcheck &>/dev/null; then
    if shellcheck -x -e SC1091 "$SETUP_SCRIPT" 2>/dev/null; then
        pass "Shellcheck passed"
    else
        fail "Shellcheck found issues (non-critical)"
        info "Run: shellcheck $SETUP_SCRIPT"
    fi
else
    info "Shellcheck not installed (skipping)"
fi

section "Checking Required Sections"

# Test 5: Check for required sections
REQUIRED_SECTIONS=(
    "INITIALIZATION"
    "LOGGING FUNCTIONS"
    "CLEANUP AND ERROR HANDLING"
    "UTILITY FUNCTIONS"
    "WSL DETECTION"
    "DISTRIBUTION DETECTION"
    "BASE SYSTEM PACKAGES"
    "HOMEBREW INSTALLATION"
    "GNU STOW INSTALLATION"
    "DOTFILES STOWING"
    "MISE VERSION MANAGER"
    "1PASSWORD SSH AGENT"
    "ZSH DIRECTORY PERMISSIONS"
    "INSTALLATION SUMMARY"
    "NEXT STEPS"
)

info "Checking for required sections..."
for section in "${REQUIRED_SECTIONS[@]}"; do
    if grep -q "# $section" "$SETUP_SCRIPT"; then
        pass "Found section: $section"
    else
        fail "Missing section: $section"
    fi
done

section "Checking Critical Functions"

# Test 6: Check for utility functions
REQUIRED_FUNCTIONS=(
    "command_exists"
    "homebrew_installed"
    "stow_version_check"
    "detect_distro"
    "package_installed"
    "install_packages"
    "cleanup"
    "log"
    "success"
    "warn"
    "error"
    "info"
)

info "Checking for required functions..."
for func in "${REQUIRED_FUNCTIONS[@]}"; do
    if grep -q "^${func}()" "$SETUP_SCRIPT" || grep -q "^${func} ()" "$SETUP_SCRIPT"; then
        pass "Found function: $func()"
    else
        fail "Missing function: $func()"
    fi
done

section "Checking Critical Variables"

# Test 7: Check for important variables
REQUIRED_VARS=(
    "XDG_CONFIG_HOME"
    "XDG_DATA_HOME"
    "XDG_STATE_HOME"
    "XDG_CACHE_HOME"
    "BUILD_DIR"
    "LOG_DIR"
    "LOG_FILE"
    "DOTFILES_DIR"
    "DISTRO"
    "BLACKLIST"
)

info "Checking for required variables..."
for var in "${REQUIRED_VARS[@]}"; do
    if grep -q "$var=" "$SETUP_SCRIPT"; then
        pass "Found variable: $var"
    else
        fail "Missing variable: $var"
    fi
done

section "Checking Package Blacklist"

# Test 8: Verify Windows packages are blacklisted
info "Checking blacklist for Windows-specific packages..."
if grep -A5 "BLACKLIST=" "$SETUP_SCRIPT" | grep -q "windows"; then
    pass "Windows packages blacklisted"
else
    fail "Windows packages not in blacklist"
fi

if grep -A5 "BLACKLIST=" "$SETUP_SCRIPT" | grep -q "powershell"; then
    pass "PowerShell packages blacklisted"
else
    fail "PowerShell packages not in blacklist"
fi

section "Checking Error Handling"

# Test 9: Check for trap
info "Checking error handling..."
if grep -q "trap cleanup" "$SETUP_SCRIPT"; then
    pass "Trap for cleanup found"
else
    fail "No trap for cleanup"
fi

if grep -q "set -euo pipefail" "$SETUP_SCRIPT" || grep -q "set -e" "$SETUP_SCRIPT"; then
    pass "Error handling enabled (set -e)"
else
    fail "Error handling not enabled"
fi

section "Checking Tool Installation Logic"

# Test 10: Verify tool installation hierarchy
info "Checking tool installation order..."

# Check Homebrew is installed before stow
HOMEBREW_LINE=$(grep -n "HOMEBREW INSTALLATION" "$SETUP_SCRIPT" | cut -d: -f1 || echo "0")
STOW_LINE=$(grep -n "GNU STOW INSTALLATION" "$SETUP_SCRIPT" | cut -d: -f1 || echo "0")
if [ "$HOMEBREW_LINE" -lt "$STOW_LINE" ] && [ "$HOMEBREW_LINE" -gt 0 ]; then
    pass "Homebrew installed before stow"
else
    fail "Installation order issue: Homebrew vs stow"
fi

# Check stow is installed before dotfiles stowing
DOTFILES_LINE=$(grep -n "DOTFILES STOWING" "$SETUP_SCRIPT" | cut -d: -f1 || echo "0")
if [ "$STOW_LINE" -lt "$DOTFILES_LINE" ] && [ "$STOW_LINE" -gt 0 ]; then
    pass "Stow installed before dotfiles stowing"
else
    fail "Installation order issue: stow vs dotfiles"
fi

# Check mise is installed after dotfiles
MISE_LINE=$(grep -n "MISE VERSION MANAGER" "$SETUP_SCRIPT" | cut -d: -f1 || echo "0")
if [ "$DOTFILES_LINE" -lt "$MISE_LINE" ] && [ "$DOTFILES_LINE" -gt 0 ]; then
    pass "Mise installed after dotfiles (correct)"
else
    fail "Installation order issue: dotfiles vs mise"
fi

section "Checking Stow Configuration"

# Test 11: Check stow flags
info "Checking stow command flags..."
if grep -q "\-\-dotfiles" "$SETUP_SCRIPT"; then
    pass "Using --dotfiles flag"
else
    fail "Missing --dotfiles flag"
fi

if grep -q "\-\-no-folding" "$SETUP_SCRIPT"; then
    pass "Using --no-folding flag"
else
    fail "Missing --no-folding flag"
fi

if grep -q "\-\-adopt" "$SETUP_SCRIPT"; then
    pass "Has --adopt for conflict resolution"
else
    fail "Missing --adopt flag"
fi

section "Checking Logging"

# Test 12: Check logging configuration
info "Checking logging setup..."
if grep -q "LOG_FILE=" "$SETUP_SCRIPT"; then
    pass "Log file configured"
else
    fail "Log file not configured"
fi

if grep -q ">> \"\$LOG_FILE\"" "$SETUP_SCRIPT" || grep -q ">> \"$LOG_FILE\"" "$SETUP_SCRIPT"; then
    pass "Logging to file implemented"
else
    fail "No logging to file found"
fi

section "Checking XDG Compliance"

# Test 13: Check XDG directory setup
info "Checking XDG directory compliance..."
XDG_VARS=("XDG_CONFIG_HOME" "XDG_DATA_HOME" "XDG_STATE_HOME" "XDG_CACHE_HOME")
for var in "${XDG_VARS[@]}"; do
    if grep -q "export $var=" "$SETUP_SCRIPT"; then
        pass "Exports $var"
    else
        fail "Does not export $var"
    fi
done

section "Checking Idempotency"

# Test 14: Check for idempotent patterns
info "Checking idempotency patterns..."
if grep -q "already installed" "$SETUP_SCRIPT"; then
    pass "Has 'already installed' checks"
else
    fail "Missing idempotency checks"
fi

if grep -q "command_exists" "$SETUP_SCRIPT"; then
    pass "Uses command_exists for checking"
else
    fail "Not using command_exists helper"
fi

section "Summary"

echo ""
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo -e "${BLUE}→${NC} Script is ready for testing in a fresh WSL instance"
    exit 0
else
    echo -e "${YELLOW}⚠${NC} Some tests failed"
    echo -e "${BLUE}→${NC} Review failures above before testing"
    exit 1
fi
