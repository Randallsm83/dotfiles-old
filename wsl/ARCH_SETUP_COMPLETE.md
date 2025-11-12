# Arch Linux WSL Setup - Final Steps

## ✅ Completed So Far

1. ✓ Downloaded and installed ArchWSL
2. ✓ Set Arch as default WSL distribution  
3. ✓ Initialized pacman keyring
4. ✓ Updated system packages
5. ✓ Created user `rmiller` with sudo access
6. ✓ Installed base development tools (git, base-devel, curl, perl, vim, less)
7. ✓ Installed Homebrew for Linux  
8. ✓ Installed GNU Stow 2.4+
9. ✓ Stowed dotfiles (git, nvim, starship, wezterm, bat, zsh, mise, ssh, direnv, fzf, ripgrep)
10. ✓ Installed mise version manager to `~/.local/bin/mise`

## 🔧 Remaining Steps

### 1. Install zsh

```bash
wsl -d Arch
sudo pacman -S --noconfirm zsh
```

### 2. Install development tools with mise

First, remove `zsh` from your mise config since it's no longer a core tool:

```bash
# Edit the config to comment out or remove the zsh line
nano ~/.config/mise/config.toml
# Find line 43: zsh = "latest"
# Comment it out: # zsh = "latest"
# Save: Ctrl+O, Enter, Ctrl+X
```

Then install all tools:

```bash
# Add mise to PATH
export PATH="$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"

# Trust the config
~/.local/bin/mise trust ~/.config/mise/config.toml

# Install all tools (this will take 10-15 minutes)
~/.local/bin/mise install

# Verify installations
~/.local/bin/mise list
```

### 3. Set zsh as default shell

```bash
# Verify zsh is installed
which zsh

# Change default shell
chsh -s $(which zsh)

# Exit and restart WSL
exit
```

From PowerShell:

```powershell
wsl --terminate Arch
wsl -d Arch
```

You should now be in zsh with starship prompt!

### 4. Activate mise in your shell

Add to your `~/.zshrc` (should already be there from dotfiles):

```bash
# mise activation
eval "$($HOME/.local/bin/mise activate zsh)"
```

Or manually run once:

```bash
echo 'eval "$($HOME/.local/bin/mise activate zsh)"' >> ~/.zshrc
exec zsh
```

## 🎯 Verification

Run these commands to verify everything is working:

```bash
# Check distributions
wsl --list --verbose
# Should show: * Arch (Running/Stopped) and docker-desktop

# Check shell
echo $SHELL
# Should output: /usr/bin/zsh

# Check mise
mise --version
# Should show version 2025.11.3 or later

# Check tools are available
starship --version
nvim --version
node --version
python --version
rust --version

# List all mise-managed tools
mise list
```

## 📝 Configuration Files

Your dotfiles are now stowed and linked:

- `~/.config/git/` → Git configuration
- `~/.config/nvim/` → Neovim configuration
- `~/.config/starship.toml` → Starship prompt
- `~/.config/wezterm/` → WezTerm terminal
- `~/.config/mise/config.toml` → mise tool configuration
- `~/.zshrc` → zsh configuration
- `~/.config/zsh/` → Additional zsh configs

## 🛠️ Troubleshooting

### mise commands not working

```bash
# Make sure mise is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Or use full path
~/.local/bin/mise --version
```

### Tools not found after mise install

```bash
# Activate mise in current shell
eval "$($HOME/.local/bin/mise activate zsh)"

# Or add to your ~/.zshrc and restart shell
```

### Starship prompt not showing

```bash
# Make sure starship is initialized in ~/.zshrc
grep starship ~/.zshrc

# Should see: eval "$(starship init zsh)"
```

## 🎉 You're Done!

Your Arch Linux WSL2 environment is now fully configured with:

- ✅ Arch Linux as default WSL distribution
- ✅ docker-desktop preserved
- ✅ User `rmiller` with sudo access
- ✅ zsh as default shell
- ✅ Starship prompt
- ✅ All dotfiles stowed and configured
- ✅ mise managing development tools
- ✅ Homebrew available for additional packages
- ✅ Full development environment ready

Enjoy your new setup!
