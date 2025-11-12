#!/usr/bin/env bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Arch Linux WSL Initialization ===${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}"
    echo "Run from PowerShell: wsl -d Arch -u root bash /mnt/c/Users/Randall/.config/dotfiles/wsl/init-arch.sh"
    exit 1
fi

# Initialize pacman keyring
echo -e "${BLUE}Initializing pacman keyring...${NC}"
pacman-key --init
pacman-key --populate archlinux

# Update system
echo -e "${BLUE}Updating system packages...${NC}"
pacman -Syu --noconfirm

# Install sudo if not present
if ! command -v sudo &>/dev/null; then
    echo -e "${BLUE}Installing sudo...${NC}"
    pacman -S --noconfirm sudo
fi

# Prompt for username
read -p "Enter username (default: randall): " USERNAME
USERNAME=${USERNAME:-randall}

# Check if user already exists
if id "$USERNAME" &>/dev/null; then
    echo -e "${YELLOW}User $USERNAME already exists${NC}"
else
    echo -e "${BLUE}Creating user: $USERNAME${NC}"
    useradd -m -G wheel -s /bin/bash "$USERNAME"
    
    echo -e "${BLUE}Set password for $USERNAME:${NC}"
    passwd "$USERNAME"
fi

# Enable sudo for wheel group
echo -e "${BLUE}Configuring sudo for wheel group...${NC}"
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel

echo ""
echo -e "${GREEN}✓ Initial setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Exit this shell: ${BLUE}exit${NC}"
echo "2. Set default user from PowerShell:"
echo "   ${BLUE}& \"\$env:USERPROFILE\\Arch\\Arch.exe\" config --default-user $USERNAME${NC}"
echo "3. Launch Arch as $USERNAME:"
echo "   ${BLUE}wsl -d Arch${NC}"
echo "4. Clone and setup dotfiles:"
echo "   ${BLUE}sudo pacman -S --noconfirm git${NC}"
echo "   ${BLUE}mkdir -p ~/.config${NC}"
echo "   ${BLUE}git clone /mnt/c/Users/Randall/.config/dotfiles ~/.config/dotfiles${NC}"
echo "   ${BLUE}cd ~/.config/dotfiles && ./wsl/setup.sh${NC}"
