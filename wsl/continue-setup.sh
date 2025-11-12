#!/usr/bin/env bash

set -euo pipefail

# Load Homebrew environment
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Stow essential packages
cd ~
echo "Stowing dotfiles..."
stow --dotfiles --no-folding -d ~/.config/dotfiles -t ~ \
  git nvim starship wezterm bat zsh mise ssh direnv fzf ripgrep

echo "✓ Dotfiles stowed successfully"

# Install mise
if ! command -v mise &>/dev/null; then
    echo "Installing mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Setup mise config
cd ~/.config/dotfiles
if [ -f ~/.config/mise/config.toml ]; then
    echo "Installing tools from mise config..."
    mise trust ~/.config/mise/config.toml 2>/dev/null || true
    mise install
fi

echo ""
echo "✓ Setup complete!"
echo ""
echo "To set zsh as default shell:"
echo "  which zsh"
echo "  chsh -s \$(which zsh)"
echo "  exit"
echo "Then restart WSL: wsl --terminate Arch && wsl -d Arch"
