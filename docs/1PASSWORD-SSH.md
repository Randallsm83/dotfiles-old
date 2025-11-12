# Using 1Password SSH Agent with Warp

## Overview

1Password can act as your SSH agent, securely storing and managing SSH keys with biometric authentication. This eliminates the need to manage key files and provides better security.

## Prerequisites

1. **1Password 8+** with SSH agent feature enabled
2. **SSH keys stored in 1Password** (not as files on disk)
3. **1Password SSH agent configured** in your system

## Setup Steps

### 1. Enable 1Password SSH Agent

**In 1Password Desktop App:**
1. Go to **Settings** → **Developer**
2. Enable **"Use the SSH agent"**
3. Enable **"Integrate with 1Password CLI"** (optional but recommended)

### 2. Configure SSH to Use 1Password

#### Windows (PowerShell/CMD)

Create or edit `C:\Users\Randall\.ssh\config`:

```ssh-config
# Use 1Password SSH agent
Host *
    IdentityAgent ~/.1password/agent.sock
    
# Optional: Keep connections alive
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Example server configuration
Host myserver
    HostName server.example.com
    User rmiller
    # No IdentityFile needed - 1Password handles it!
```

**Set up the socket path in PowerShell profile:**

Add to your PowerShell profile (`$PROFILE`):

```powershell
# 1Password SSH Agent
$env:SSH_AUTH_SOCK = "$env:USERPROFILE\.1password\agent.sock"
```

#### WSL (Recommended: Use Windows SSH)

**1Password's official recommendation is to use Windows SSH from WSL** rather than bridging the socket.

Create a wrapper script `~/.local/bin/ssh` in WSL:

```bash
#!/bin/bash
# Wrapper to use Windows SSH with 1Password from WSL
/mnt/c/Windows/System32/OpenSSH/ssh.exe "$@"
```

Make it executable:
```bash
chmod +x ~/.local/bin/ssh
```

Ensure `~/.local/bin` is in your PATH (add to `~/.zshrc` or `~/.bashrc`):
```bash
export PATH="$HOME/.local/bin:$PATH"
```

**For other SSH commands, create similar wrappers:**

```bash
# ~/.local/bin/ssh-add
#!/bin/bash
/mnt/c/Windows/System32/OpenSSH/ssh-add.exe "$@"

# ~/.local/bin/scp
#!/bin/bash
/mnt/c/Windows/System32/OpenSSH/scp.exe "$@"

# ~/.local/bin/sftp
#!/bin/bash
/mnt/c/Windows/System32/OpenSSH/sftp.exe "$@"
```

Make them executable:
```bash
chmod +x ~/.local/bin/ssh-add ~/.local/bin/scp ~/.local/bin/sftp
```

### 3. Verify 1Password SSH Agent Works

Test the connection:

**PowerShell:**
```powershell
# Should list your 1Password SSH keys
ssh-add -l

# Test connection (1Password will prompt for biometric auth)
ssh -T git@github.com
```

**WSL:**
```bash
# Should list your 1Password SSH keys via Windows SSH
ssh-add -l

# Test connection
ssh -T git@github.com
```

## Warp Configuration with 1Password

### Key Differences

When using 1Password SSH agent:

✅ **DO:**
- Use simple `ssh user@host` commands
- Let 1Password handle key selection automatically
- Use SSH config file for host definitions

❌ **DON'T:**
- Specify `-i /path/to/key` (1Password manages keys)
- Store keys as files (defeats the purpose)
- Use traditional ssh-agent

### Example Configurations

#### Simple Connection (PowerShell)

```yaml
---
name: Server with 1Password
windows:
  - tabs:
      - title: Remote
        layout:
          commands:
            # 1Password will prompt for biometric auth
            - exec: ssh user@hostname
        color: blue
```

#### Simple Connection (WSL)

```yaml
---
name: Server from WSL with 1Password
windows:
  - tabs:
      - title: Remote
        shell: archlinux  # or ubuntu, debian, etc.
        layout:
          commands:
            # Uses Windows SSH wrapper - 1Password handles auth
            - exec: ssh user@hostname
        color: blue
```

#### Using SSH Config Aliases

**In `C:\Users\Randall\.ssh\config` (Windows):**
```ssh-config
Host dev
    HostName dev.example.com
    User rmiller

Host prod
    HostName prod.example.com
    User rmiller
```

**In Warp config:**
```yaml
tabs:
  - title: Development
    layout:
      commands:
        - exec: ssh dev
    color: green
  
  - title: Production
    layout:
      commands:
        - exec: ssh prod
    color: red
```

#### Multiple Servers with 1Password

```yaml
---
name: Infrastructure (1Password)
windows:
  - tabs:
      - title: Web Server
        layout:
          split_direction: vertical
          panes:
            - commands:
                - exec: ssh web@web.example.com
              is_focused: true
            - commands:
                - exec: ssh web@web.example.com -t "htop"
        color: green
      
      - title: Database
        layout:
          commands:
            - exec: ssh db@db.example.com
        color: blue
      
      - title: CI/CD
        layout:
          commands:
            - exec: ssh ci@ci.example.com
        color: yellow
```

#### Mixed Environment (PowerShell + WSL)

```yaml
---
name: Development (1Password SSH)
active_window_index: 0
windows:
  - active_tab_index: 0
    tabs:
      # PowerShell local development
      - title: Local (Windows)
        layout:
          cwd: C:\Users\Randall\projects
          commands:
            - exec: git status
        color: purple
      
      # WSL development (uses Windows SSH)
      - title: Local (WSL)
        shell: archlinux
        layout:
          cwd: ~/projects
          commands:
            - exec: git status
        color: cyan
      
      # Remote from PowerShell
      - title: Dev Server (PS)
        layout:
          commands:
            - exec: ssh dev
        color: green
      
      # Remote from WSL (still uses Windows SSH via wrapper)
      - title: Dev Server (WSL)
        shell: archlinux
        layout:
          commands:
            - exec: ssh dev
        color: green
```

## Advanced 1Password SSH Features

### 1. Multiple Keys for Same Host

1Password can automatically select the correct key based on:
- User in the SSH item
- Notes/tags in 1Password
- Host matching

**In 1Password:**
- Store multiple SSH keys
- Use clear naming: "GitHub - Personal", "GitHub - Work"
- Add notes with host patterns

### 2. Git Commit Signing

1Password can also sign Git commits:

**PowerShell:**
```powershell
# Configure Git to use 1Password for signing
git config --global gpg.format ssh
git config --global user.signingkey "ssh-ed25519 AAAA..."
git config --global commit.gpgsign true
```

**WSL (using Windows Git or WSL Git):**
```bash
# Same configuration works with Windows SSH wrapper
git config --global gpg.format ssh
git config --global user.signingkey "ssh-ed25519 AAAA..."
git config --global commit.gpgsign true
```

### 3. Temporary Access

1Password prompts for biometric auth each time:
- More secure than unlocked ssh-agent
- Auto-locks after period of inactivity
- No keys stored on disk

## Recommended SSH Config

**`C:\Users\Randall\.ssh\config` (applies to both Windows and WSL via wrappers):**

```ssh-config
# ===================================
# 1Password SSH Agent Configuration
# ===================================

# Default settings for all hosts
Host *
    # Use 1Password SSH agent
    IdentityAgent ~/.1password/agent.sock
    
    # Keep connections alive
    ServerAliveInterval 60
    ServerAliveCountMax 3
    
    # Security settings
    AddKeysToAgent no  # 1Password handles this
    ForwardAgent no    # Don't forward agent by default
    
    # Connection timeouts
    ConnectTimeout 10

# ===================================
# Development Servers
# ===================================

Host dev
    HostName dev.example.com
    User rmiller
    Port 22

Host dev-*
    User rmiller
    ForwardAgent yes  # Enable for dev servers

# ===================================
# Staging/Production
# ===================================

Host staging
    HostName staging.example.com
    User rmiller

Host prod
    HostName prod.example.com
    User rmiller-readonly

# ===================================
# Version Control
# ===================================

Host github.com
    User git
    IdentitiesOnly yes

Host gitlab.com
    User git
    IdentitiesOnly yes

Host bitbucket.org
    User git
    IdentitiesOnly yes

# ===================================
# Jump Hosts
# ===================================

Host bastion
    HostName bastion.example.com
    User rmiller

Host internal-*
    ProxyJump bastion
    User rmiller

# ===================================
# Database Servers (with tunnels)
# ===================================

Host db-tunnel
    HostName db.example.com
    User rmiller
    LocalForward 5432 localhost:5432
    LocalForward 6379 localhost:6379
```

## Troubleshooting

### 1Password Not Prompting for SSH (Windows)

**Check SSH agent is configured:**
```powershell
# Should show 1Password socket path
$env:SSH_AUTH_SOCK

# Should list keys from 1Password
ssh-add -l
```

**If not set:**
```powershell
# Add to PowerShell profile
$env:SSH_AUTH_SOCK = "$env:USERPROFILE\.1password\agent.sock"

# Reload profile
. $PROFILE
```

### 1Password Not Working from WSL

**Verify Windows SSH wrapper is working:**
```bash
# Check wrapper exists and is executable
ls -la ~/.local/bin/ssh

# Should point to Windows SSH
cat ~/.local/bin/ssh

# Test - should show Windows SSH version
ssh -V

# Should list 1Password keys
ssh-add -l
```

**If wrapper not working:**
```bash
# Ensure PATH is correct
echo $PATH | grep ".local/bin"

# Verify Windows SSH exists
ls -la /mnt/c/Windows/System32/OpenSSH/ssh.exe

# Test Windows SSH directly
/mnt/c/Windows/System32/OpenSSH/ssh.exe -V
```

### Connection Fails with "Permission Denied"

1. **Check 1Password SSH agent is running**
   - Open 1Password desktop app
   - Check Settings → Developer → SSH agent enabled

2. **Verify key is in 1Password**
   ```powershell
   ssh-add -l
   ```

3. **Test with verbose output**
   ```powershell
   ssh -vv user@hostname
   ```

### Path Issues in WSL

If `ssh` still uses WSL's built-in SSH instead of the wrapper:

```bash
# Check which ssh is being used
which ssh

# Should show: /home/username/.local/bin/ssh
# If not, check PATH order in ~/.zshrc or ~/.bashrc

# Temporarily test Windows SSH
/mnt/c/Windows/System32/OpenSSH/ssh.exe -T git@github.com
```

## Best Practices

### 1. Use Windows SSH Config for Both Environments
- Single source of truth: `C:\Users\Randall\.ssh\config`
- WSL automatically uses it via Windows SSH wrapper
- Easier to maintain

### 2. Separate Keys by Environment
- Development keys
- Production keys (highly restricted)
- Personal vs. work

### 3. Use Descriptive Names in 1Password
- "AWS EC2 - Production"
- "GitHub - Personal"
- "GitLab - Work Projects"

### 4. Test in Both Environments
```powershell
# From PowerShell
ssh -T git@github.com
```

```bash
# From WSL
ssh -T git@github.com
```

Both should work identically!

## Complete Warp Configuration Example

```yaml
---
name: Cross-Platform Dev (1Password SSH)
active_window_index: 0
windows:
  - active_tab_index: 0
    tabs:
      # Windows local
      - title: Local (Windows)
        layout:
          cwd: C:\Users\Randall\projects
          commands:
            - exec: git status
        color: purple
      
      # WSL local
      - title: Local (WSL)
        shell: archlinux
        layout:
          cwd: ~/projects
          commands:
            - exec: git status
        color: cyan
      
      # Remote from Windows
      - title: Remote (Windows)
        layout:
          commands:
            - exec: ssh dev
            - exec: cd ~/projects
        color: green
      
      # Remote from WSL (uses Windows SSH)
      - title: Remote (WSL)
        shell: archlinux
        layout:
          commands:
            - exec: ssh dev
            - exec: cd ~/projects
        color: green
      
      # Split pane: Windows + WSL
      - title: Hybrid
        layout:
          split_direction: vertical
          panes:
            - cwd: C:\Users\Randall\projects
              is_focused: true
            - shell: archlinux
              cwd: ~/projects
        color: yellow
```

## Additional Resources

- [1Password SSH Agent Documentation](https://developer.1password.com/docs/ssh/)
- [1Password SSH Agent on WSL](https://developer.1password.com/docs/ssh/agent/advanced/#use-the-windows-ssh-agent-in-wsl)
- [OpenSSH Config Manual](https://man.openbsd.org/ssh_config)
- [Git Commit Signing with 1Password](https://developer.1password.com/docs/ssh/git-commit-signing/)
