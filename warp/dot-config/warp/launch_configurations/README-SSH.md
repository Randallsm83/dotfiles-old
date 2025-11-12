# Warp SSH Launch Configurations Guide

## Overview

Warp launch configurations allow you to set up persistent SSH connection profiles with pre-configured tabs, split panes, and automatic command execution.

## File Locations

Your Warp configurations are symlinked from your dotfiles:
- **Dotfiles source**: `C:\Users\Randall\.config\dotfiles\warp\dot-config\warp\launch_configurations\`
- **Warp reads from**: `C:\Users\Randall\AppData\Roaming\warp\Warp\data\launch_configurations\`

## Available Configurations

### 1. `ssh-remote.yaml`
Simple single-server connection with examples

### 2. `ssh-connections.yaml`
Comprehensive multi-server setup with:
- Split panes for monitoring
- Jump host connections
- SSH tunnels for databases
- Multiple simultaneous connections
- WSL integration

### 3. `ssh-template.yaml`
Quick template for creating new SSH profiles

## Quick Start

### Basic SSH Connection

```yaml
---
name: My Server
active_window_index: 0
windows:
  - active_tab_index: 0
    tabs:
      - title: Remote
        layout:
          commands:
            - exec: ssh user@hostname
        color: blue
```

### SSH with Key Authentication

```yaml
commands:
  - exec: ssh -i ~/.ssh/my_key user@hostname
```

### SSH with Custom Port

```yaml
commands:
  - exec: ssh -p 2222 user@hostname
```

### SSH via Jump Host

```yaml
commands:
  - exec: ssh -J jumphost.com user@internal-server
```

### SSH Tunnel (Port Forwarding)

```yaml
commands:
  # Local port 5432 forwards to remote's 5432
  - exec: ssh -L 5432:localhost:5432 user@hostname
```

## Advanced Features

### Split Panes

Work in one pane while monitoring in another:

```yaml
layout:
  split_direction: vertical  # or horizontal
  panes:
    - cwd: /home/user/projects
      is_focused: true
      commands:
        - exec: ssh user@hostname
    - commands:
        - exec: ssh user@hostname -t "htop"
```

### Multiple Tabs

Different servers or different directories on the same server:

```yaml
tabs:
  - title: Web Server
    layout:
      commands:
        - exec: ssh user@web.example.com
    color: green
  
  - title: Database
    layout:
      commands:
        - exec: ssh user@db.example.com
    color: blue
```

### Post-Connection Commands

Run commands after SSH connects:

```yaml
commands:
  - exec: ssh user@hostname
  - exec: cd ~/projects
  - exec: git status
  - exec: ls -la
```

**Note**: These commands run *locally* after the SSH command. For remote commands, use:

```yaml
commands:
  - exec: ssh user@hostname -t "cd ~/projects && git status && bash"
```

### Shell Selection

Use specific shells or WSL distributions:

```yaml
- title: From WSL
  shell: archlinux  # or ubuntu, debian, etc.
  layout:
    commands:
      - exec: ssh user@hostname
```

## Color Options

Available tab colors:
- `blue`
- `green`
- `yellow`
- `red`
- `magenta`
- `cyan`
- `purple`

## Windows-Specific Considerations

### SSH from PowerShell

PowerShell has built-in SSH client (Windows 10+):

```yaml
commands:
  - exec: ssh user@hostname
```

### SSH from WSL

Specify WSL distribution:

```yaml
shell: archlinux
layout:
  commands:
    - exec: ssh user@hostname
```

### SSH Key Paths

From PowerShell:
```yaml
- exec: ssh -i C:\Users\Randall\.ssh\id_rsa user@hostname
```

From WSL:
```yaml
- exec: ssh -i ~/.ssh/id_rsa user@hostname
```

## SSH Configuration Tips

### 1. Use SSH Config File

Instead of long commands, set up `~/.ssh/config`:

```
Host myserver
    HostName server.example.com
    User rmiller
    Port 2222
    IdentityFile ~/.ssh/id_rsa_server
    ServerAliveInterval 60
```

Then in Warp:
```yaml
commands:
  - exec: ssh myserver
```

### 2. SSH Agent

Start SSH agent to avoid repeated password prompts:

**PowerShell**:
```powershell
Start-Service ssh-agent
ssh-add C:\Users\Randall\.ssh\id_rsa
```

**WSL/Linux**:
```bash
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
```

### 3. Keep Connections Alive

```yaml
- exec: ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 user@hostname
```

## Troubleshooting

### Connection Times Out

Add to command:
```yaml
- exec: ssh -o ConnectTimeout=10 -o ServerAliveInterval=60 user@hostname
```

### Key Permission Errors

On Windows, fix key permissions:
```powershell
icacls C:\Users\Randall\.ssh\id_rsa /inheritance:r /grant:r "$($env:USERNAME):(R)"
```

### WSL SSH Can't Find Keys

Ensure key permissions in WSL:
```bash
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

## Example: Complete Development Setup

```yaml
---
name: Dev Environment
active_window_index: 0
windows:
  - active_tab_index: 0
    tabs:
      # Development server with split panes
      - title: Development
        layout:
          split_direction: horizontal
          panes:
            # Work pane
            - cwd: /home/user/projects
              is_focused: true
              commands:
                - exec: ssh -i ~/.ssh/dev_key dev@dev.example.com -t "cd ~/projects && exec $SHELL"
            # Monitoring pane
            - commands:
                - exec: ssh dev@dev.example.com -t "htop"
        color: green
      
      # Staging server
      - title: Staging
        layout:
          commands:
            - exec: ssh -i ~/.ssh/staging_key staging@stage.example.com
        color: yellow
      
      # Database tunnel
      - title: Database
        layout:
          commands:
            - exec: ssh -L 5432:localhost:5432 -L 6379:localhost:6379 db@db.example.com
            - exec: echo "PostgreSQL: localhost:5432"
            - exec: echo "Redis: localhost:6379"
        color: magenta
```

## Next Steps

1. **Edit your configuration**: Update `ssh-remote.yaml` or create a new file
2. **Replace placeholders**: Change `user@hostname` to your actual servers
3. **Test connection**: Launch from Warp's launcher (Ctrl+Shift+P or Cmd+K)
4. **Iterate**: Add more tabs, panes, or connections as needed
5. **Commit to dotfiles**: `git add` and `git commit` your changes

## Resources

- [Warp Documentation](https://docs.warp.dev/)
- [SSH Config Reference](https://man.openbsd.org/ssh_config)
- [Windows OpenSSH Documentation](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_overview)
