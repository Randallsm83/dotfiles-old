# WSL Setup Script Changelog

## 2025-01-12 - Setup Script Review & Improvements

### Removed
- ✅ Deleted deprecated root `install.sh` (replaced by platform-specific scripts)

### Fixed - `mise/config.toml`
- ✅ Fixed syntax error on line 25: `"cargo:fd-find"` line had malformed comment
- ✅ Added missing `direnv` as separate line
- ✅ Added missing `"cargo:ripgrep"` for Linux/WSL/macOS
- ✅ Added `starship` prompt tool
- ✅ Added `zsh` shell
- ✅ Removed `git` from mise (conflicts with base system installation strategy)

### Improved - `wsl/setup.sh`
- ✅ Added WSL version detection (WSL1 vs WSL2) with performance warning
- ✅ Added git availability check before base package installation
- ✅ Made 1Password SSH agent configuration optional with user prompt
- ✅ Improved 1Password messaging when socket not found (informational vs warning)
- ✅ Updated zsh installation message to be more informative
- ✅ Made base package summary distribution-aware (Ubuntu/Arch/Fedora)

### Updated - `README.md`
- ✅ Removed reference to old `install.sh` script
- ✅ Updated Linux/macOS quick start with mise-first approach
- ✅ Added explicit `mise install` step

## Tool Installation Strategy

### Windows
- **Language runtimes**: mise (node, python, go, rust, etc.)
- **CLI tools**: scoop (bat, eza, fd, ripgrep, starship, neovim, etc.)
- **GUI apps**: winget

### Linux/WSL/macOS
- **Everything**: mise (CLI tools via cargo + language runtimes)
- **Bootstrap only**: Homebrew (for stow installation)
- **Base essentials**: System package manager (git, build-essential, curl)

### Tools Managed by mise (Linux/WSL/macOS)
- **CLI Tools**: bat, eza, fd-find, ripgrep, starship, neovim, fzf, direnv
- **Language Runtimes**: node, python, ruby, go, rust, lua, bun
- **Dev Tools**: btop, sqlite, vim, yarn, uv, usage
- **Shell**: zsh

## Known Good Configuration
- GNU Stow >= 2.4.0 (for XDG support and --dotfiles flag)
- Homebrew for Linux (linuxbrew)
- mise version manager (replaces asdf)
- Ubuntu/Debian, Arch/Manjaro, Fedora/RHEL support

## Testing
Run validation tests:
```bash
cd ~/.config/dotfiles/wsl
./test-setup.sh
```

## Notes
- Script is idempotent - safe to run multiple times
- Logs stored in `~/.local/state/wsl-setup/logs/`
- Clone dotfiles to WSL filesystem (NOT `/mnt/c`) for best performance
