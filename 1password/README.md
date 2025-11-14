# 1Password CLI Setup

This package provides shell completions for the 1Password CLI (`op`).

## Prerequisites

The `op` CLI tool is managed by mise:

```bash
# Install op via mise
mise install op
```

## Initial Setup

Before using `op`, you need to add your 1Password account:

```bash
op account add --address my.1password.com --email <your-email>
```

You'll be prompted for:
1. **Secret Key** - Found in your 1Password Emergency Kit (format: `A3-XXXXXX-XXXXXX-XXXXX-XXXXX-XXXXX-XXXXX`)
2. **Master Password** - Your 1Password account password

## Configuration

After adding your account, `op` stores encrypted credentials in:
- **Windows**: `%LOCALAPPDATA%\1Password\config`
- **Linux/WSL/macOS**: `~/.config/op/config`

### GitHub CLI Integration (Linux/WSL/macOS only)

To use 1Password with the GitHub CLI:

1. Install the GitHub CLI via mise:
   ```bash
   mise install github-cli
   ```

2. Initialize the 1Password GitHub CLI plugin:
   ```bash
   op plugin init gh
   ```
   This will prompt you to select your GitHub token from 1Password.

3. The plugin configuration is saved to `~/.config/op/plugins.sh` and automatically sourced in zsh.

## Shell Completions

This package provides:
- **PowerShell**: `~/.config/powershell/Completions/op.ps1`
- **Zsh**: `~/.config/zsh/.zshrc.d/80-op.zsh`

Completions are automatically sourced by your shell configuration.

## Usage

```bash
# Sign in (required after reboot or session timeout)
eval $(op signin)

# Basic commands
op item list
op item get "Item Name"
op document get "Document Name" --output file.txt
```

## Security Notes

- **Never commit** your Secret Key or Master Password to the repo
- The `op` CLI stores credentials encrypted locally
- Use `op signin` to authenticate your session
- Sessions expire after inactivity for security

## Troubleshooting

**Command not found:**
```bash
# Verify mise installation
mise list op
mise install op

# Refresh shell
exec $SHELL
```

**Authentication issues:**
```bash
# Sign out and back in
op signout --all
eval $(op signin)
```

**Re-add account:**
```bash
# If you need to reconfigure
op account forget <account-shorthand>
op account add --address my.1password.com --email <your-email>
```
