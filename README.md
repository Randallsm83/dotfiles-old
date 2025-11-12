# Dotfiles

Cross-platform dotfiles for macOS, Linux, WSL2, and Windows.

## Features

- **Cross-platform**: Works on macOS, Linux (Ubuntu), WSL2, and native Windows
- **XDG Base Directory**: Follows XDG spec on all platforms (`~/.config`, `~/.local`, etc.)
- **Unified configs**: Same Neovim, Git, WezTerm, and Starship configs across all platforms
- **Platform-specific**: Automatic detection with platform-specific optimizations
- **Package management**: Automated setup via winget/scoop (Windows), apt (Linux/WSL), brew (macOS)

## Quick Start

### Windows (Native)

**Prerequisites:**
- PowerShell 7+ (recommended) or PowerShell 5.1
- winget or scoop (winget recommended)
- Enable Developer Mode for symlinks (or run as admin)

```powershell
# Clone the repo
git clone https://github.com/Randallsm83/dotfiles.git $env:USERPROFILE\.config\dotfiles
cd $env:USERPROFILE\.config\dotfiles

# Run bootstrap (dry run first)
.\windows\bootstrap.ps1 -WhatIf

# Run for real
.\windows\bootstrap.ps1

# Or with options
.\windows\bootstrap.ps1 -Packages scoop -LinkOnly
```

**Bootstrap Options:**
- `-Packages` - Package manager: `winget` (default), `scoop`, `both`, `none`
- `-LinkOnly` - Skip package installation, only create symlinks
- `-Force` - Overwrite existing files without prompting
- `-WhatIf` - Show what would be done without making changes

### WSL2 (Ubuntu)

**Fresh Install - Fully Automated:**

```bash
# Clone inside WSL home directory (NOT /mnt/c)
git clone https://github.com/Randallsm83/dotfiles.git ~/.config/dotfiles
cd ~/.config/dotfiles

# Run the automated setup script
./wsl/setup.sh
```

**What it does:**
1. ✓ Installs base system dependencies (git, build-essential)
2. ✓ Installs Homebrew for Linux
3. ✓ Installs GNU Stow 2.4+ (via Homebrew or source build)
4. ✓ Stows all dotfiles with conflict detection & resolution
5. ✓ Installs mise version manager
6. ✓ Installs all tools from mise config (Node, Python, Rust, CLI tools)
7. ✓ Configures 1Password SSH agent integration
8. ✓ Fixes zsh directory permissions
9. ✓ Comprehensive logging to `~/.local/state/wsl-setup/logs/`

**Manual Setup (Advanced):**

For manual control over the process:

```bash
# Install Homebrew first
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(brew shellenv)"

# Install stow
brew install stow

# Stow packages
cd ~/.config/dotfiles
stow --dotfiles git nvim starship wezterm bat zsh mise

# Install mise and tools
curl https://mise.run | sh
mise install
```

### Linux / macOS

```bash
# Clone the repo
git clone https://github.com/Randallsm83/dotfiles.git ~/.config/dotfiles
cd ~/.config/dotfiles

# Install mise and tools
curl https://mise.run | sh
mise install

# Manual stow
stow git nvim starship wezterm bat zsh mise
```

## What Gets Installed

### Cross-Platform Configs
- **Git** - `.config/git/config` with Windows conditional includes
- **Neovim** - `.config/nvim` with Lua configuration
- **WezTerm** - `.config/wezterm` with platform detection
- **Starship** - `.config/starship` prompt configs
- **mise** - `.config/mise` version manager (replaces asdf)
- **Bat** - `.config/bat` (better cat)
- **Ripgrep** - `.config/ripgrep` search configs

### Platform-Specific

**Windows:**
- PowerShell profile (both 7+ and 5.1)
- Windows Terminal settings
- Windows-specific Git config
- XDG environment variables

**WSL/Linux:**
- Zsh configuration with Oh My Zsh
- Shell integrations (zoxide, fzf, etc.)

**macOS:**
- Homebrew Brewfile
- macOS-specific paths and SDKs

## Configuration

### Enable Developer Mode (Windows)

For symlinks without admin privileges:

1. Open **Settings** → **Update & Security** → **For developers**
2. Enable **Developer Mode**
3. Restart if prompted

Or run bootstrap as administrator (it can enable it for you).

### Package Managers & Tool Hierarchy

**Windows:**
- **winget** - Built-in Windows Package Manager (recommended)
- **scoop** - CLI-focused package manager
- Fonts via winget/scoop Nerd Fonts packages

**Linux/WSL (Installation Priority):**
1. **mise** → Primary for CLI tools & language runtimes
2. **Homebrew** → For packages not in mise (e.g., stow)
3. **Build from source** → Last resort with XDG compliance
4. **apt** → Only for base system essentials (git, build-essential)

**macOS (Installation Priority):**
1. **mise** → Primary for CLI tools & language runtimes  
2. **Homebrew** → Secondary package manager
3. **Build from source** → When necessary

## Structure

```
dotfiles/
├── .stowrc              # Stow configuration
├── .gitattributes       # Line ending rules (LF in repo, CRLF for .ps1)
├── git/                 # Git configs
│   └── dot-config/git/
├── nvim/                # Neovim configs
│   └── dot-config/nvim/
├── starship/            # Starship prompt
│   └── dot-config/starship/
├── wezterm/             # WezTerm terminal
│   └── dot-config/wezterm/
├── zsh/                 # Zsh configs (Unix)
│   ├── dot-config/zsh/
│   └── dot-zshenv
├── windows/             # Windows-specific
│   ├── bootstrap.ps1
│   ├── powershell/
│   ├── windows-terminal/
│   ├── packages/
│   └── dot-config/git/windows.gitconfig
└── wsl/                 # WSL-specific
    └── setup.sh
```

### Dot-file Convention

Directories/files prefixed with `dot-` are converted to `.` by GNU Stow:
- `dot-config` → `.config`
- `dot-zshrc` → `.zshrc`

## Troubleshooting

### Windows

**Symlink failures:**
- Enable Developer Mode or run PowerShell as administrator
- Bootstrap will fall back to junctions (dirs) and hardlinks (files)

**PATH not updated:**
- Restart your terminal after running bootstrap
- Check: `$env:PATH` should include `$env:USERPROFILE\bin`

**Starship not loading:**
- Verify installation: `Get-Command starship`
- Check profile loaded: `Test-Path $PROFILE`
- Manually reload: `. $PROFILE`

### WSL

**Setup script logs:**
- Location: `~/.local/state/wsl-setup/logs/setup_YYYYMMDD_HHMMSS.log`
- Check if installation fails: `tail -100 ~/.local/state/wsl-setup/logs/setup_*.log`
- Script is idempotent (safe to re-run)

**Permission issues:**
- ⚠️ Clone inside WSL (`~/.config/dotfiles`), NOT under `/mnt/c`
- Windows filesystem causes permission/symlink issues
- Setup script automatically fixes zsh insecure directory warnings

**Stow version issues:**
- Requires GNU Stow >= 2.4.0 for proper XDG support
- Setup script ensures correct version (Homebrew or source build)
- Check version: `stow --version`

**Tool installation:**
- Tools installed via mise from `~/.config/mise/config.toml`
- Verify: `mise doctor` or `mise list`
- Update tools: `mise upgrade` or `mise install`

**Fonts not rendering:**
- Install Nerd Fonts on Windows (not in WSL)
- Configure Windows Terminal to use them
- Recommended: FiraCode Nerd Font, JetBrainsMono Nerd Font

### Git Line Endings

**CRLF warnings:**
- `.gitattributes` enforces LF in repo, CRLF for .ps1 files
- `core.autocrlf=input` on Windows normalizes to LF on commit
- This keeps the repo clean across platforms

### General

**Config not found:**
- Check XDG vars: `echo $XDG_CONFIG_HOME` (should be `~/.config`)
- Verify symlinks: `ls -la ~/.config/nvim`
- Windows: `Get-Item ~\.config\nvim | Select-Object Target`

**Neovim config issues:**
- Check stdpath: `nvim --headless -c 'echo stdpath("config")' -c q`
- Should point to `.config/nvim`

## Manual Stowing

```bash
# Stow individual packages
cd ~/.config/dotfiles
stow git         # Git configuration
stow nvim        # Neovim
stow starship    # Starship prompt
stow zsh         # Zsh (Unix only)

# Unstow a package
stow -D nvim

# Restow (unlink then relink)
stow -R nvim

# Dry run
stow -n nvim
```

## Credits

- [GNU Stow](https://www.gnu.org/software/stow/) - Symlink farm manager
- [Starship](https://starship.rs/) - Cross-shell prompt
- [WezTerm](https://wezfurlong.org/wezterm/) - Cross-platform terminal
- [Neovim](https://neovim.io/) - Hyperextensible Vim-based text editor
