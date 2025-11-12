# Package Management Strategy

This document explains the hybrid package management approach used across different platforms in this dotfiles repository.

## Philosophy

**Different platforms have different optimal package managers.** Instead of forcing a single tool everywhere, we use the best tool for each platform while maintaining consistency where it matters (language runtimes).

### Core Principles

1. **Language runtimes via mise everywhere** - Consistent versions across platforms
2. **Platform-native tools for CLI utilities** - Better integration and performance
3. **GUI apps via platform package managers** - Proper system integration
4. **Bootstrap with minimal dependencies** - Get to mise as quickly as possible

---

## Per-Platform Breakdown

### 🪟 Windows (Native PowerShell)

#### Package Managers

| Manager | Purpose | When to Use |
|---------|---------|-------------|
| **scoop** | CLI tools, fonts, mise | Primary package manager for command-line tools |
| **winget** | GUI applications | System-level GUI apps (VS Code, terminals, etc.) |
| **mise** | Language runtimes | Node, Python, Ruby, Go, Rust, Lua, etc. |

#### Tool Assignment

**via scoop** (`windows/packages/scoop.json`):
- Core CLI: git, curl, wget, make
- Dev tools: neovim, gh, lazygit, delta
- Modern CLI: ripgrep, bat, fd, fzf, eza, vivid, btop, zoxide
- Shell: pwsh, starship
- Utils: 7zip, gsudo, jq, yq
- Fonts: FiraCode-NF, Hack-NF, JetBrainsMono-NF, CascadiaCode-NF
- **mise itself** (to manage language runtimes)

**via winget** (`windows/packages/winget.json`):
- Git.Git (for Git Credential Manager integration)
- Microsoft.PowerShell
- wez.wezterm (terminal GUI)
- Microsoft.WindowsTerminal
- Microsoft.VisualStudioCode
- Microsoft.GitCredentialManagerCore
- 7zip.7zip (GUI version with context menu)

**via mise** (`mise/dot-config/mise/config.toml`):
- Language runtimes ONLY: node, python, ruby, go, rust, lua, luajit, bun
- Runtime-adjacent tools: uv, direnv, usage, yarn, sqlite

**NOT via mise on Windows:**
- CLI tools (bat, eza, fd, ripgrep, starship, neovim, etc.) - use scoop instead
- cargo:* packages - scoop has better Windows-native builds

---

### 🐧 Linux / WSL / macOS

#### Package Managers

| Manager | Purpose | When to Use |
|---------|---------|-------------|
| **mise** | Everything | CLI tools (via cargo) + language runtimes |
| **homebrew** | Bootstrap only | Installing stow, then unused |
| **apt/dnf/pacman** | System bootstrap | Only if tool missing and sudo available |

#### Tool Assignment

**Bootstrap phase (system packages if needed):**
- git, curl (use system version temporarily if available)
- build-essential / base-devel (if sudo available, for compiling)
- perl (for stow)

**Post-bootstrap (all via mise):**

**via mise** (`mise/dot-config/mise/config.toml`):
- **Language runtimes:** node, python, ruby, go, rust, lua, luajit, bun, uv, yarn, sqlite, vim
- **CLI tools (cargo):** bat, eza, fd, vivid, ripgrep, starship, tinty
- **Additional tools:** bat-extras, btop, fzf, neovim, direnv, usage, cargo-binstall
- **Post-bootstrap:** git (replaces system git after mise is installed)

**via homebrew (temporary):**
- stow (only for dotfile management during bootstrap)

**NOT via mise on Linux:**
- Nothing! mise handles everything after bootstrap

---

## Configuration Files

### Where to Add/Remove Packages

| Platform | Tool Type | Edit This File |
|----------|-----------|----------------|
| Windows | CLI tool | `windows/packages/scoop.json` |
| Windows | GUI app | `windows/packages/winget.json` |
| Windows | Font | `windows/packages/scoop.json` (fonts array) |
| Windows | Language runtime | `mise/dot-config/mise/config.toml` |
| Linux/WSL/macOS | Any tool | `mise/dot-config/mise/config.toml` |

### File Formats

**scoop.json:**
```json
{
  "buckets": ["main", "extras", "nerd-fonts"],
  "apps": ["git", "neovim", ...],
  "fonts": ["FiraCode-NF", ...]
}
```

**winget.json:**
```json
{
  "Sources": [{
    "Packages": [
      { "PackageIdentifier": "Git.Git" },
      ...
    ]
  }]
}
```

**mise config.toml:**
```toml
[tools]
node = "23.7.0"
python = "latest"
"cargo:bat" = "latest"  # Linux/WSL/macOS only
```

---

## Migration Guide

### If You Have Existing Installations

#### Windows: Clean Up CLI Tools from winget

If you previously installed CLI tools via winget, clean them up:

```powershell
# Uninstall CLI tools that are now managed by scoop
winget uninstall Neovim.Neovim
winget uninstall Starship.Starship
winget uninstall BurntSushi.ripgrep.MSVC
winget uninstall sharkdp.bat
winget uninstall sharkdp.fd
winget uninstall junegunn.fzf
winget uninstall ajeetdsouza.zoxide
winget uninstall gerardog.gsudo

# Re-run bootstrap to install via scoop
cd ~/.config/dotfiles
.\windows\bootstrap.ps1 -Packages scoop
```

#### Linux/WSL: Replace System Packages with mise

```bash
# After mise is installed and configured, it will manage tools
# System packages (git, curl, etc.) can remain as fallbacks
# mise takes precedence when activated in your shell

mise install  # Install all tools from config.toml
```

---

## Bootstrap Flow

### Windows
```
1. Use pre-installed git/curl (Windows 10+)
2. Install scoop (no admin needed)
3. Install CLI tools via scoop (including mise)
4. Install GUI apps via winget
5. mise installs language runtimes only
```

### Linux/WSL/macOS
```
1. Use system git/curl (or install via apt/dnf if needed)
2. Install homebrew (user-space, no root)
3. Install stow via homebrew
4. Stow dotfiles
5. Install mise
6. mise installs EVERYTHING (CLI tools + language runtimes)
7. mise's git replaces system git
```

---

## FAQ

### Why not use mise for CLI tools on Windows?

scoop provides pre-built Windows binaries that integrate better with PowerShell and Windows paths. mise's cargo-based tools compile from source or use Linux-centric builds that may have issues on Windows.

### Why not use homebrew for everything on Linux?

mise is lighter weight, faster, and provides per-project version management via `.tool-versions` or `.mise.toml` files. Homebrew is excellent for bootstrap (getting stow) but  unnecessary once mise is available.

### Can I use winget for everything on Windows?

You can, but scoop is better for CLI tools because:
- No admin rights required
- Portable installs (~\scoop)
- Better version management
- Simpler for development tools

### What if I don't have sudo on Linux?

The bootstrap script handles this:
1. Tries to use existing system packages (git, curl)
2. Installs homebrew (doesn't need sudo)
3. homebrew installs stow
4. mise handles everything else

You may need build tools (gcc, make) for compiling, but homebrew includes its own toolchain.

### Why keep Git.Git in winget on Windows?

The winget version includes Git Credential Manager (GCM) which integrates well with Windows authentication and is harder to set up separately with scoop's git.

---

## Troubleshooting

### Windows: Scoop/mise version conflicts

If you have tools installed in both scoop and mise:

```powershell
# Check what's installed where
scoop list
mise list

# Uninstall from mise (keep scoop version)
mise uninstall neovim
mise uninstall bat
# etc.
```

### Linux: System package vs mise conflicts

mise takes precedence when your shell is configured. Check order:

```bash
# Should show mise's path first
which git
# Should show mise version
git --version

# If showing system version, ensure mise is activated
eval "$(mise activate zsh)"  # or bash
```

### Can't install packages without admin/sudo

On Windows: Use scoop (no admin needed)
On Linux: Use homebrew → stow → mise (all user-space)

---

## Summary Table

| Tool Category | Windows | Linux/WSL/macOS |
|--------------|---------|-----------------|
| **Package Managers** | scoop (primary)<br>winget (GUI)<br>mise (runtimes) | mise (primary)<br>homebrew (bootstrap only)<br>apt/dnf (optional bootstrap) |
| **Language Runtimes** | mise | mise |
| **CLI Tools** | scoop | mise (via cargo) |
| **GUI Apps** | winget | Native package manager |
| **Fonts** | scoop (nerd-fonts) | Native package manager |
| **Dotfile Manager** | PowerShell (stow-like) | stow (via homebrew) |

---

## See Also

- [README.md](../README.md) - General dotfiles documentation
- [windows/bootstrap.ps1](../windows/bootstrap.ps1) - Windows installation script
- [wsl/setup.sh](../wsl/setup.sh) - Linux/WSL installation script
- [mise documentation](https://mise.jdx.dev)
- [scoop documentation](https://scoop.sh)
