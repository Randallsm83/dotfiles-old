# Migration Guide: asdf to mise

This guide helps you migrate from asdf to mise in your dotfiles setup.

## Why mise?

mise is a modern, faster alternative to asdf that:
- Has better performance (written in Rust vs Ruby)
- Is backwards compatible with asdf plugins
- Supports additional backends (cargo, npm, pipx, etc.)
- Has better XDG directory compliance
- Includes task runner capabilities

## Quick Migration

### 1. Install mise

**Linux/WSL/macOS:**
```bash
curl https://mise.run | sh
```

**Windows (via scoop):**
```powershell
scoop install mise
```

### 2. Migrate existing tools

mise can read asdf's `.tool-versions` file, but we recommend using mise's config format:

```bash
# Let mise detect your current tools
cd ~/.config/dotfiles
mise install

# Or migrate manually
mise use -g node@$(asdf current nodejs | awk '{print $2}')
mise use -g python@$(asdf current python | awk '{print $2}')
# ... repeat for other tools
```

### 3. Update shell configuration

**For zsh users:**

The dotfiles already include mise configuration. After stowing:

```bash
cd ~/.config/dotfiles
stow mise  # This links ~/.config/mise and shell integrations
```

Your shell will now use mise instead of asdf.

### 4. Remove asdf (optional)

Once you've verified mise works:

```bash
# Backup first
cp ~/.config/asdf/tool-versions ~/asdf-tool-versions.backup

# Remove asdf
rm -rf ~/.local/share/asdf

# Unstow asdf package
cd ~/.config/dotfiles
stow -D asdf
```

## Configuration Differences

### asdf
```bash
# ~/.config/asdf/tool-versions
nodejs 20.10.0
python 3.12.0
ruby 3.3.0
```

### mise
```toml
# ~/.config/mise/config.toml
[tools]
node = "20.10.0"
python = "3.12.0"
ruby = "3.3.0"

# Or use latest
node = "latest"
python = "latest"
```

## Shell Activation

### asdf
```bash
export ASDF_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/asdf"
. "$ASDF_DATA_DIR/asdf.sh"
```

### mise
```bash
eval "$(mise activate bash)"  # or zsh
```

The dotfiles mise package includes proper zsh integration at `~/.config/zsh/.zshrc.d/50-mise.zsh`.

## Common Commands Comparison

| Task | asdf | mise |
|------|------|------|
| Install tool | `asdf install node 20.10.0` | `mise install node@20.10.0` |
| Set global version | `asdf global node 20.10.0` | `mise use -g node@20.10.0` |
| Set local version | `asdf local node 20.10.0` | `mise use node@20.10.0` |
| List installed | `asdf list` | `mise list` |
| List available | `asdf list all node` | `mise ls-remote node` |
| Current versions | `asdf current` | `mise current` |
| Add plugin | `asdf plugin add node` | Automatic - mise has core support |
| Update plugins | `asdf plugin update --all` | Not needed for core tools |

## Advanced: Using mise's Additional Features

### Cargo backend
```bash
mise use -g cargo:ripgrep@latest
mise use -g cargo:bat@latest
```

### npm backend
```bash
mise use -g npm:typescript@latest
```

### pipx backend
```bash
mise use -g pipx:poetry@latest
```

### Task runner
```toml
# In .mise.toml or mise.toml
[tasks.test]
run = "pytest tests/"

[tasks.lint]
run = "ruff check ."
```

```bash
mise run test
mise run lint
```

## Troubleshooting

### Tools not found after migration
```bash
# Verify mise is activated
mise doctor

# Reinstall tools
mise install

# Check PATH
echo $PATH | tr ':' '\n' | grep mise
```

### Shell integration not working
```bash
# Ensure mise is in PATH
which mise

# Re-activate shell integration
eval "$(mise activate zsh)"

# Or restart your shell
exec zsh
```

### Plugin compatibility
Most asdf plugins work with mise. If a plugin fails:
```bash
# Check if it's a core tool (built-in support)
mise use -g <tool>@latest

# For legacy plugins
mise use -g asdf:<plugin>@<version>
```

## Windows-Specific Notes

On Windows, mise should be installed via scoop and will work in PowerShell/pwsh. The shell integration needs to be added to your PowerShell profile:

```powershell
# Add to $PROFILE
Invoke-Expression (&mise activate pwsh | Out-String)
```

The Windows bootstrap script will handle this automatically when you run:
```powershell
.\windows\bootstrap.ps1 -Packages scoop
```

## Rollback

If you need to rollback to asdf:

1. Reinstall asdf: `git clone https://github.com/asdf-vm/asdf.git ~/.local/share/asdf`
2. Restore shell integration: Source asdf in your shell rc file
3. Restore tools: `asdf install` using your backed-up `.tool-versions`
4. Unstow mise: `stow -D mise`
5. Restow asdf: `stow asdf`

## Resources

- [mise documentation](https://mise.jdx.dev/)
- [mise GitHub](https://github.com/jdx/mise)
- [asdf to mise migration](https://mise.jdx.dev/getting-started.html#asdf-migration)
