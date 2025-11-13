# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

---

## Repository Overview

This is a cross-platform dotfiles repository supporting:
- **Windows** (Native PowerShell)
- **WSL2** (Ubuntu, Arch)
- **Linux** (Ubuntu, Arch, other distributions)
- **macOS**

The repository manages configurations for 40+ tools/packages using GNU Stow with XDG Base Directory compliance.

---

## Bootstrap Commands

### Windows (PowerShell)

From repository root (`C:\Users\Randall\.config\dotfiles`):

```powershell
# Preview changes (recommended first run)
.\windows\bootstrap.ps1 -WhatIf

# Full setup (scoop + winget + symlinks)
.\windows\bootstrap.ps1

# scoop only (no winget)
.\windows\bootstrap.ps1 -Packages scoop

# Symlinks only (skip package installation)
.\windows\bootstrap.ps1 -LinkOnly

# Force overwrite existing files
.\windows\bootstrap.ps1 -Force
```

**Prerequisites:**
- PowerShell 7+ or PowerShell 5.1
- Enable Developer Mode for symlinks (or run as admin)
- winget or scoop installed

### WSL2 (Ubuntu/Arch)

From repository root (`~/.config/dotfiles`):

```bash
# Fully automated setup
./wsl/setup.sh
```

**What it does:**
1. Installs system dependencies (git, build-essential)
2. Installs Homebrew for Linux
3. Installs GNU Stow 2.4+ (via Homebrew or source build)
4. Stows all dotfiles with conflict detection
5. Installs mise version manager
6. Installs all tools from mise config
7. Configures 1Password SSH agent integration (if available)
8. Fixes zsh directory permissions

**Logs:** `~/.local/state/wsl-setup/logs/setup_YYYYMMDD_HHMMSS.log`

**Critical:** Clone inside WSL (`~/.config/dotfiles`), NOT under `/mnt/c` to avoid permission/symlink issues.

### Linux / macOS (Manual)

```bash
# Install Homebrew (if not present)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(brew shellenv)"

# Install stow
brew install stow

# Stow all packages (from dotfiles root)
cd ~/.config/dotfiles
for d in */; do stow --dotfiles "${d%/}"; done

# Install mise
curl https://mise.run | sh

# Install tools from mise config
mise install
```

---

## Verification

### Windows

```powershell
# Basic verification
.\windows\verify.ps1

# Detailed output
.\windows\verify.ps1 -Detailed

# Include VS Code checks
.\windows\verify.ps1 -IncludeVSCode -Detailed
```

### Linux / WSL / macOS

```bash
# Basic verification
./verify.sh

# Detailed output
./verify.sh --detailed

# Include optional tools
./verify.sh --detailed --optional
```

**What gets verified:**
- Environment variables (XDG_*)
- Package managers (scoop/winget/brew/mise)
- Core tools (git, stow, zsh, nvim, starship)
- Symlinks point to correct targets
- Config file content
- Shell integration (starship, mise activation)
- Fonts (Nerd Fonts)

---

## Package Management Strategy

### Windows

| Manager | Purpose | Tools |
|---------|---------|-------|
| **scoop** | CLI tools | git, neovim, starship, mise, bat, eza, fd, ripgrep, fzf, zoxide, delta, btop, gh, lazygit, make, curl, wget, jq, yq, 7zip, gsudo |
| **winget** | GUI apps | Git.Git (GCM), PowerShell, WezTerm, Windows Terminal, VS Code, 7zip GUI |
| **mise** | Language runtimes | node, python, ruby, go, rust, bun, uv, yarn, direnv, fzf, usage |

**Fonts via scoop:** FiraCode-NF, Hack-NF, JetBrainsMono-NF, CascadiaCode-NF

**Package files:**
- `windows/packages/scoop.json`
- `windows/packages/winget.json`
- `mise/dot-config/mise/config.toml`
- `mise/dot-config/mise/config.windows.toml`

### Linux / WSL / macOS

| Manager | Purpose | Tools |
|---------|---------|-------|
| **mise** | Everything | CLI tools (via cargo) + language runtimes |
| **homebrew** | Bootstrap only | stow (then unused) |
| **apt/dnf/pacman** | System bootstrap | git, curl, build-essential (if needed) |

**Tools via mise (Linux/WSL/macOS only):**
- Language runtimes: node, python, ruby, go, rust, lua, luajit, bun, uv, yarn, sqlite, vim
- CLI tools (cargo:*): bat, eza, fd-find, ripgrep, starship
- Additional: bat-extras, btop, fzf, neovim, direnv, usage, cargo-binstall

**Package files:**
- `mise/dot-config/mise/config.toml` (all platforms)
- `mise/dot-config/mise/config.linux.toml` (Linux/macOS auto-loaded)

---

## GNU Stow Operations

All stow packages use the `dot-config` naming convention:
- `PACKAGE/dot-config/APP/` → `~/.config/APP/`
- `PACKAGE/dot-zshrc` → `~/.zshrc`

### Common Stow Commands

**Preview changes (dry run):**
```bash
stow -nv PACKAGE_NAME
```

**Stow a single package:**
```bash
stow --dotfiles PACKAGE_NAME
```

**Stow all packages:**
```bash
# From dotfiles root
for d in */; do stow --dotfiles "${d%/}"; done
```

**Restow (unlink then relink):**
```bash
stow -R --dotfiles PACKAGE_NAME
```

**Unstow a package:**
```bash
stow -D --dotfiles PACKAGE_NAME
```

**Adopt existing files (conflict resolution):**
```bash
# Preview conflicts first
stow -nv --dotfiles PACKAGE_NAME

# Adopt regular files into repo
stow --adopt --dotfiles PACKAGE_NAME

# Review changes before committing
git status && git diff
```

---

## mise Commands

**Install mise (if not present):**
```bash
curl https://mise.run | sh
```

**Activate mise in current shell:**
```bash
eval "$(mise activate bash)"  # or zsh, fish
```

**Install all tools from config:**
```bash
mise install
```

**Add a tool globally:**
```bash
mise use -g node@latest
mise use -g python@3.12
mise use -g "cargo:bat@latest"  # Linux/macOS only
```

**List installed tools:**
```bash
mise list
```

**Update mise itself:**
```bash
mise self-update
```

**Update all tools:**
```bash
mise upgrade
```

**Check mise health:**
```bash
mise doctor
```

---

## Stow Packages in Repository

The repository contains 40+ GNU Stow packages:

**Core configurations:**
- `git` - Git configuration with Windows conditional includes
- `nvim` - Neovim (Lua-based kickstart config)
- `wezterm` - WezTerm terminal emulator
- `starship` - Cross-shell prompt
- `zsh` - Zsh shell configuration
- `bat` - Better cat with syntax highlighting
- `mise` - Version manager configs (platform-specific)

**Development tools:**
- `node`, `npm`, `nvm` - Node.js configurations
- `python` - Python configs
- `ruby` - Ruby configs
- `rust` - Rust/Cargo configs
- `golang` - Go configs
- `lua` - Lua configs
- `perl`, `php` - Perl and PHP configs

**CLI utilities:**
- `ripgrep` - Fast grep alternative
- `fzf` - Fuzzy finder
- `eza` - Modern ls replacement
- `vivid` - LS_COLORS generator
- `direnv` - Directory-based environment loader
- `sqlite3` - SQLite configs
- `wget` - wget configs

**Terminal/Shell:**
- `ssh` - SSH configs and 1Password integration
- `fonts` - Nerd Fonts
- `p10k` - Powerlevel10k theme
- `thefuck`, `tinted-theming` - Shell enhancements

**Editors/IDEs:**
- `vim` - Vim configuration
- `editorconfig` - EditorConfig

**Platform-specific:**
- `windows` - PowerShell profiles, Windows Terminal settings
- `utilities` - PowerShell utility scripts (UtilCacheClean.ps1)
- `bin` - Shell scripts and executables
- `wsl` - WSL-specific configs

**Other:**
- `asdf` - asdf version manager (legacy, being replaced by mise)
- `arduino` - Arduino IDE configs
- `glow` - Markdown renderer
- `homebrew` - Homebrew configs (macOS)
- `iterm2` - iTerm2 configs (macOS)
- `lde` - Local development environment
- `vagrant` - Vagrant configs
- `warp` - Warp terminal launch configurations

---

## Architecture Details

### XDG Base Directory Structure

All configurations follow XDG Base Directory specification:

| Variable | Default Path | Purpose |
|----------|--------------|---------|  
| `XDG_CONFIG_HOME` | `~/.config` | Configuration files |
| `XDG_DATA_HOME` | `~/.local/share` | Data files |
| `XDG_STATE_HOME` | `~/.local/state` | State files (logs, history) |
| `XDG_CACHE_HOME` | `~/.cache` | Cache files |

**Key paths:**
- Dotfiles repo: `$XDG_CONFIG_HOME/dotfiles` (`~/.config/dotfiles`)
- mise config: `$XDG_CONFIG_HOME/mise` (`~/.config/mise`)
- mise data: `$XDG_DATA_HOME/mise` (`~/.local/share/mise`)
- Build logs: `$XDG_STATE_HOME/*/logs` (`~/.local/state/*/logs`)
- Build cache: `$XDG_CACHE_HOME/*/build` (`~/.cache/*/build`)

### Platform-Specific mise Configuration

mise automatically loads platform-specific configs:

**`mise/dot-config/mise/config.toml` (Base - All Platforms):**
- Language runtimes: node, python, ruby, go, rust, bun
- Universal tools: direnv, fzf, usage, uv, yarn
- Settings and environment variables

**`mise/dot-config/mise/config.linux.toml` (Auto-loaded on Linux/macOS):**
- Additional runtimes: lua, luajit, sqlite, vim
- CLI tools via cargo: bat, eza, fd-find, ripgrep
- Editors: neovim, vim
- Terminal tools: starship, btop, bat-extras
- Build tools: cargo-binstall

**`mise/dot-config/mise/config.windows.toml` (Auto-loaded on Windows):**
- Disables tools that don't work on Windows: lua, luajit, sqlite
- Use scoop for CLI tools instead

### Neovim Configuration

**Structure:**
- Entry point: `nvim/dot-config/nvim/init.lua`
- Modular Lua config:
  - `lua/options.lua` - Editor options
  - `lua/keymaps.lua` - Key mappings
  - `lua/autocommands.lua` - Auto commands
  - `lua/plugins.lua` - Plugin definitions
  - `lua/colors.lua` - Color scheme
  - `lua/custom/plugins/init.lua` - Custom plugins
  - `lua/kickstart/plugins/` - Kickstart.nvim plugins
- Plugin manager: lazy.nvim
- Lockfile: `lazy-lock.json`

### Windows Bootstrap Pipeline

1. **Check prerequisites** - Developer Mode, package managers
2. **Install packages** - Via scoop and/or winget
3. **Create symlinks** - Config files to `$env:USERPROFILE\.config`
4. **Setup PowerShell profile** - Load starship, mise, aliases
5. **Configure XDG environment** - Set XDG_* variables

**Key Windows paths:**
- Dotfiles: `$env:USERPROFILE\.config\dotfiles` (`C:\Users\USERNAME\.config\dotfiles`)
- PowerShell profile: `$PROFILE` (varies by PS version)
- Windows Terminal settings: `$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json`

### WSL Bootstrap Pipeline

1. **System packages** - Install git, build-essential via apt/dnf/pacman
2. **Homebrew** - Install Homebrew for Linux (user-space)
3. **GNU Stow** - Install stow 2.4+ via Homebrew or source build
4. **Stow dotfiles** - Symlink all packages with conflict detection
5. **mise** - Install mise version manager
6. **Tools** - Install all CLI tools and runtimes via mise
7. **1Password SSH** - Configure 1Password SSH agent (if available)
8. **Zsh permissions** - Fix insecure directory warnings

---

## Platform-Specific Notes

### Windows

**Developer Mode:**
- Required for symlinks without admin rights
- Enable: Settings → Update & Security → For developers → Developer mode
- Or run bootstrap as administrator to enable automatically

**PowerShell Profile:**
- Bootstrap configures `$PROFILE` for both PowerShell 7+ and 5.1
- Loads starship prompt, mise activation, custom aliases
- Location: `$PROFILE` or `$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

**Git Credential Manager:**
- Included with winget's Git.Git package
- Integrates with Windows authentication
- Configured automatically

**Path Updates:**
- `$env:USERPROFILE\bin` added to PATH
- `$env:USERPROFILE\.local\bin` added to PATH
- Restart terminal after bootstrap for PATH changes

### WSL2

**Critical: Clone Location**
- ✅ Clone inside WSL: `~/.config/dotfiles`
- ❌ Do NOT clone under `/mnt/c` - causes permission/symlink issues
- Windows filesystem breaks POSIX permissions and symlinks

**GNU Stow Version:**
- Requires stow >= 2.4.0 for proper XDG support
- Setup script ensures correct version via Homebrew or source build
- Check version: `stow --version`

**Zsh Insecure Directories:**
- Setup script automatically fixes insecure directory warnings
- Manually fix: `compaudit | xargs chmod go-w`

**1Password SSH Agent:**
- Optional integration for SSH key management
- Requires 1Password installed on Windows host
- Configured automatically if detected

**Fonts:**
- Install Nerd Fonts on Windows (not in WSL)
- Configure Windows Terminal to use them
- Recommended: FiraCode Nerd Font, JetBrainsMono Nerd Font

### Linux (Native)

**Build Tools:**
- Required for compiling: gcc, make, automake, perl
- Install via system package manager: `apt install build-essential` (Ubuntu/Debian)
- Or: `dnf groupinstall "Development Tools"` (Fedora/RHEL)
- Or: `pacman -S base-devel` (Arch)

**GNU Stow:**
- Install via Homebrew or system package manager
- Verify version >= 2.4.0: `stow --version`

### macOS

**Xcode Command Line Tools:**
- Required for building from source
- Install: `xcode-select --install`

**Homebrew:**
- Recommended for managing packages
- Install: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

---

## Common Tasks

### Adding a New Tool

**Windows (CLI tool):**
1. Add to `windows/packages/scoop.json` in the `apps` array
2. Run: `scoop install TOOL_NAME`

**Windows (GUI app):**
1. Add to `windows/packages/winget.json` in the `Packages` array
2. Run: `winget install --id PACKAGE_ID`

**Windows (Language runtime):**
1. Add to `mise/dot-config/mise/config.toml` in the `[tools]` section
2. Run: `mise install TOOL_NAME`

**Linux/WSL/macOS (CLI tool via cargo):**
1. Add to `mise/dot-config/mise/config.linux.toml` as `"cargo:TOOL_NAME" = "latest"`
2. Run: `mise install "cargo:TOOL_NAME"`

**Linux/WSL/macOS (Language runtime):**
1. Add to `mise/dot-config/mise/config.toml` in the `[tools]` section
2. Run: `mise install TOOL_NAME`

### Creating a New Stow Package

```bash
# From dotfiles root
mkdir -p NEW_PACKAGE/dot-config/APP_NAME

# Add config files
echo "config content" > NEW_PACKAGE/dot-config/APP_NAME/config

# Stow it
stow --dotfiles NEW_PACKAGE

# Verify
ls -la ~/.config/APP_NAME
```

### Updating Tools

**Windows (scoop):**
```powershell
scoop update
scoop update *
```

**Windows (winget):**
```powershell
winget upgrade --all
```

**Linux/WSL/macOS (mise):**
```bash
mise upgrade
```

**Language runtimes (mise on all platforms):**
```bash
mise upgrade
```

### SSH Configuration with 1Password

See `docs/SSH.md` and `docs/1PASSWORD-SSH.md` for detailed setup instructions.

**Quick setup (WSL):**
```bash
./ssh/setup-1password-wsl.sh
```

---

## Troubleshooting

### Symlink Issues (Windows)

**Symptom:** "Cannot create symbolic link" errors

**Solution:**
1. Enable Developer Mode (Settings → For developers)
2. Or run bootstrap as administrator
3. Bootstrap falls back to junctions (dirs) and hardlinks (files) if symlinks fail

### Stow Conflicts

**Symptom:** "WARNING! stowing X would cause conflicts"

**Solution:**
```bash
# Preview conflicts
stow -nv --dotfiles PACKAGE_NAME

# If conflicts are regular files you want to keep:
stow --adopt --dotfiles PACKAGE_NAME

# Review what changed
git diff

# Revert unwanted changes
git checkout -- .

# If conflicts should be overwritten:
rm ~/.config/CONFLICTING_FILE
stow --dotfiles PACKAGE_NAME
```

### mise Tools Not Found

**Symptom:** Commands installed by mise not available

**Solution:**
```bash
# Ensure mise is activated in your shell
eval "$(mise activate bash)"  # or zsh

# Or add to shell rc file
echo 'eval "$(mise activate bash)"' >> ~/.bashrc

# Reload shell
exec bash
```

### WSL Permission Issues

**Symptom:** "compinit: insecure directories" or permission errors

**Solution:**
```bash
# Fix zsh insecure directories
compaudit | xargs chmod go-w

# Or run setup script (fixes automatically)
./wsl/setup.sh
```

### Git Line Endings (Windows)

**Symptom:** CRLF warnings when committing

**Solution:**
- `.gitattributes` enforces LF in repo, CRLF for .ps1 files
- Git config uses `core.autocrlf=input` on Windows
- This is correct behavior - keeps repo clean across platforms

---

## Documentation References

- [README.md](README.md) - Overview and quick start
- [docs/PACKAGE_MANAGEMENT.md](docs/PACKAGE_MANAGEMENT.md) - Detailed package management strategy
- [docs/SSH.md](docs/SSH.md) - SSH and Warp launch configurations
- [docs/1PASSWORD-SSH.md](docs/1PASSWORD-SSH.md) - 1Password SSH agent setup
- [docs/QUICKSTART-1PASSWORD.md](docs/QUICKSTART-1PASSWORD.md) - 1Password quick setup

**External Resources:**
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
- [mise Documentation](https://mise.jdx.dev)
- [scoop Documentation](https://scoop.sh)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Starship Documentation](https://starship.rs)
- [WezTerm Documentation](https://wezfurlong.org/wezterm)
- [Neovim Documentation](https://neovim.io/doc)
