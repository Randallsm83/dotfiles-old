# Spaceduck Theme Integration Summary

## Overview
Integrated spaceduck color theme across vivid (LS_COLORS) and eza (file listing) for all platforms.

## Files Created/Modified

### Vivid (LS_COLORS)
- **Created**: `vivid/dot-config/vivid/themes/spaceduck.yml` - Custom spaceduck vivid theme
- **Modified**: `windows/powershell/Microsoft.PowerShell_profile.ps1` - Set `$env:VIVID_THEME = 'spaceduck'`
- **Modified**: `zsh/dot-config/zsh/dot-zprofile` - Set `export VIVID_THEME='spaceduck'`
- **Created**: `vivid/README.md` - Documentation for vivid setup

### Eza (File Listing)
- **Created**: `eza/dot-config/eza/themes/spaceduck.yml` - Custom spaceduck eza theme
- **Modified**: `eza/dot-config/eza/theme.yml` - Symlinked to `themes/spaceduck.yml`
- **Modified**: `eza/dot-config/zsh/dot-zshrc.d/80-eza.zsh` - Added completion path to fpath
- **Created**: `windows/powershell/Modules/EzaCompletion/EzaCompletion.psm1` - PowerShell completions
- **Modified**: `windows/powershell/Microsoft.PowerShell_profile.ps1` - Load eza completions

### Deployment Configuration
- **Modified**: `windows/linkmap.psd1` - Added vivid and eza symlink mappings:
  - `vivid/dot-config/vivid` → `~/.config/vivid` (XDG)
  - `vivid/dot-config/vivid` → `%APPDATA%/vivid` (Windows-specific)
  - `eza/dot-config/eza` → `~/.config/eza`
- **Modified**: `wsl/setup.sh` - Added `vivid` to stow packages list

## Platform Support

### Windows (PowerShell)
- ✅ Vivid theme: `%APPDATA%\vivid\themes\spaceduck.yml` (symlinked)
- ✅ Eza theme: `~\.config\eza\themes\spaceduck.yml` (symlinked)
- ✅ VIVID_THEME environment variable set in profile
- ✅ Eza PowerShell completions loaded
- ✅ Bootstrap script (`windows/bootstrap.ps1`) will create symlinks via linkmap

### WSL/Linux (zsh/bash)
- ✅ Vivid theme: `~/.config/vivid/themes/spaceduck.yml` (stowed)
- ✅ Eza theme: `~/.config/eza/themes/spaceduck.yml` (stowed)
- ✅ VIVID_THEME environment variable set in zprofile
- ✅ Eza zsh completions loaded via fpath
- ✅ Setup script (`wsl/setup.sh`) will stow vivid and eza packages

### macOS (not tested but should work)
- ✅ Structure supports stow via `install.sh`
- ✅ VIVID_THEME set in zprofile
- ✅ Eza completions via fpath

## Installation

### Windows
```powershell
cd dotfiles/windows
.\bootstrap.ps1
```

### WSL/Linux
```bash
cd dotfiles/wsl
./setup.sh
```

### Generate LS_COLORS Cache

**Windows**:
```powershell
.\dotfiles\windows\scripts\generate-lscolors.ps1
```

**WSL/Linux**:
```bash
./dotfiles/wsl/scripts/generate-lscolors.sh
```

## Theme Colors

Based on [spaceduck palette](https://github.com/pineapplegiant/spaceduck):

- **Background**: `#0f111b`
- **Foreground**: `#ecf0c1`
- **Cyan**: `#00a3cc` (directories)
- **Green**: `#5ccc96` (executables)
- **Purple**: `#b3a1e6` (symlinks, images)
- **Red**: `#e33400` (archives, errors)
- **Yellow**: `#f2ce00` (modified times)
- **Orange**: `#e39400` (device files)
- **Magenta**: `#ce6f8f` (special files)

## Verification

```powershell
# Check theme is set
echo $env:VIVID_THEME  # Should show: spaceduck

# Test vivid
vivid generate spaceduck | Select-Object -First 100

# Test eza with theme
eza --color=always

# Test eza completions
eza --<TAB>  # Should show completions
```
