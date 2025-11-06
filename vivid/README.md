# Vivid Configuration

Custom themes for [vivid](https://github.com/sharkdp/vivid), a themeable LS_COLORS generator.

## Theme: spaceduck

Custom vivid theme matching the [spaceduck color palette](https://github.com/pineapplegiant/spaceduck).

### Colors

- **Directories**: cyan (`#00a3cc`)
- **Executables**: green (`#5ccc96`)
- **Symlinks**: purple (`#b3a1e6`)
- **Archives**: red (`#e33400`)
- **Media (images)**: purple (`#b3a1e6`)
- **Code files**: cyan
- **Config files**: magenta (`#ce6f8f`)

## Usage

### Setting the Theme

The `VIVID_THEME` environment variable is set to `spaceduck` by default in:
- PowerShell: `windows/powershell/Microsoft.PowerShell_profile.ps1`
- zsh: `zsh/dot-config/zsh/dot-zprofile`

### Generating LS_COLORS

LS_COLORS are generated once and cached in `~/.config/lscolors/` for performance.

**PowerShell:**
```powershell
.\windows\scripts\generate-lscolors.ps1
```

**WSL/Linux:**
```bash
./wsl/scripts/generate-lscolors.sh
```

### Platform-specific Paths

- **Windows**: `%APPDATA%\vivid\themes\` (symlinked from dotfiles)
- **Linux/WSL**: `~/.config/vivid/themes/` (stowed from dotfiles)

### Adding New Themes

1. Create a new `.yml` file in `themes/` directory
2. Use existing themes as reference for structure
3. Run the generate script to create cached LS_COLORS
4. Set `VIVID_THEME` environment variable to the new theme name

## See Also

- [vivid GitHub](https://github.com/sharkdp/vivid)
- [spaceduck theme](https://github.com/pineapplegiant/spaceduck)
- Eza integration: `eza/dot-config/zsh/dot-zshrc.d/80-eza.zsh`
