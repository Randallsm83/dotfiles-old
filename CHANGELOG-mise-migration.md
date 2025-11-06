# Dotfiles Update: mise Migration & Windows Improvements

## Summary

This update migrates the dotfiles from asdf to mise and improves Windows support with scoop integration.

## Changes Made

### 1. Version Manager Migration: asdf → mise

**Why mise?**
- ✅ Faster (Rust vs Ruby)
- ✅ Better XDG compliance
- ✅ Additional backends (cargo, npm, pipx)
- ✅ Built-in task runner
- ✅ Backwards compatible with asdf

**Files Modified:**
- `install.sh` - Replaced `install_asdf()` with `install_mise()`
  - Uses official mise installer: `curl https://mise.run | sh`
  - Installs tools from `~/.config/mise/config.toml`
  - Supports auto-update via `mise self-update`

**Configuration:**
- Existing `mise/` directory already contains:
  - `mise/dot-config/mise/config.toml` - Tool versions
  - `mise/dot-config/zsh/dot-zshrc.d/50-mise.zsh` - Shell integration

### 2. Windows Package Manager Updates

**File Modified:** `windows/packages/scoop.json`

**Added:**
- `mise` - Version manager (primary addition)

**Removed:**
- `fnm` - Replaced by mise's node management

**Why scoop?**
- Aligns with your rule preference: "On Windows, prefer scoop"
- mise is available in scoop's main bucket
- No admin privileges required
- Better CLI integration than winget for dev tools

### 3. PowerShell Profile Enhancement

**File Modified:** `windows/powershell/Microsoft.PowerShell_profile.ps1`

**Added mise integration:**
```powershell
if (Get-Command mise -ErrorAction SilentlyContinue) {
    # Configure mise XDG paths for Windows
    $env:MISE_DATA_DIR = "$env:XDG_DATA_HOME\mise"
    $env:MISE_CONFIG_DIR = "$env:XDG_CONFIG_HOME\mise"
    $env:MISE_CACHE_DIR = "$env:XDG_CACHE_HOME\mise"
    $env:MISE_STATE_DIR = "$env:XDG_STATE_HOME\mise"
    
    # Activate mise
    Invoke-Expression (& mise activate pwsh | Out-String)
}
```

**Updated fnm integration:**
- Now only activates if mise is not available (graceful fallback)

### 4. Documentation Updates

**Files Modified:**

1. **WARP.md** - Project-specific agent rules
   - Replaced "ASDF Version Manager" section with "mise Version Manager"
   - Updated Key Paths to reference mise instead of asdf
   - Updated Managed Configurations section

2. **README.md** - Main documentation
   - Added mise to "What Gets Installed" section
   - Noted it replaces asdf

3. **MIGRATION.md** - New migration guide
   - Step-by-step asdf → mise migration instructions
   - Command comparison table
   - Platform-specific notes (Linux/WSL/macOS/Windows)
   - Troubleshooting section
   - Rollback instructions

4. **CHANGELOG-mise-migration.md** - This file

## Installation & Usage

### Fresh Install (Linux/WSL/macOS)

```bash
cd ~/.config/dotfiles
bash -lc ". ./install.sh; main"
```

The install script will now:
1. Install mise instead of asdf
2. Stow mise configuration
3. Install tools from `~/.config/mise/config.toml`

### Fresh Install (Windows)

```powershell
cd $env:USERPROFILE\.config\dotfiles
.\windows\bootstrap.ps1 -Packages scoop
```

The bootstrap script will:
1. Install mise via scoop
2. Create symlinks for configs (including mise)
3. Configure PowerShell profile with mise integration

### Migrating from asdf

If you're currently using asdf:

```bash
# 1. Backup your tool versions
cp ~/.config/asdf/tool-versions ~/asdf-backup.txt

# 2. Pull latest dotfiles
cd ~/.config/dotfiles
git pull

# 3. Run the updated installer
bash -lc ". ./install.sh; main"

# 4. Verify mise installation
mise doctor
mise list

# 5. Remove asdf (optional)
rm -rf ~/.local/share/asdf
stow -D asdf
```

See `MIGRATION.md` for detailed migration instructions.

## What's Still Compatible

- ✅ All existing stow packages work unchanged
- ✅ Windows bootstrap script works as before
- ✅ XDG directory structure unchanged
- ✅ Git, Neovim, WezTerm, Starship configs unchanged
- ✅ The asdf directory still exists in the repo (for reference/rollback)

## mise vs asdf Command Reference

| Task | asdf | mise |
|------|------|------|
| Install tool | `asdf install node 20.10.0` | `mise install node@20.10.0` |
| Set global | `asdf global node 20.10.0` | `mise use -g node@20.10.0` |
| Set local | `asdf local node 20.10.0` | `mise use node@20.10.0` |
| List installed | `asdf list` | `mise list` |
| Current versions | `asdf current` | `mise current` |

## Testing

**Linux/WSL/macOS:**
```bash
# After install
mise doctor
mise list
which node python ruby
```

**Windows:**
```powershell
# After bootstrap
mise doctor
mise list
Get-Command node, python, ruby
```

## Rollback Plan

If issues arise:

1. Restore asdf:
   ```bash
   git clone https://github.com/asdf-vm/asdf.git ~/.local/share/asdf
   cd ~/.config/dotfiles
   stow -D mise
   stow asdf
   # Add asdf source line back to shell rc
   ```

2. On Windows:
   ```powershell
   scoop uninstall mise
   scoop install fnm  # If you need node management
   # Edit PowerShell profile to remove mise integration
   ```

## Next Steps

1. **Test the changes:**
   - Clone/pull the updated dotfiles
   - Run installer/bootstrap
   - Verify mise works correctly

2. **Migrate tools:**
   - Review `~/.config/mise/config.toml`
   - Add/remove tools as needed: `mise use -g <tool>@<version>`

3. **Update your workflow:**
   - Replace `asdf` commands with `mise` equivalents
   - Take advantage of mise's cargo/npm/pipx backends

## Additional Resources

- [mise documentation](https://mise.jdx.dev/)
- [mise GitHub](https://github.com/jdx/mise)
- [Dotfiles MIGRATION.md](./MIGRATION.md)
- [Dotfiles WARP.md](./WARP.md) (for AI agents)

## Notes

- The asdf directory remains in the repository for backward compatibility
- You can run both asdf and mise side-by-side during migration
- mise can read `.tool-versions` files from asdf
- All changes preserve XDG Base Directory compliance
